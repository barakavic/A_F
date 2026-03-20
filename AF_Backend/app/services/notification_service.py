import firebase_admin
from firebase_admin import credentials, messaging
from app.core.config import settings
import os
import logging
import uuid
from sqlalchemy.orm import Session
from app.models.user import User

logger = logging.getLogger(__name__)

class NotificationService:
    _initialized = False

    @staticmethod
    def _initialize():
        """Initialize Firebase Admin SDK. Returns True if successful."""
        if NotificationService._initialized:
            return True
        
        try:
            # Look for the credentials file in the root directory
            cred_path = os.path.join(os.getcwd(), "firebase-service-account.json")
            if os.path.exists(cred_path):
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
                NotificationService._initialized = True
                logger.info("Firebase Admin SDK initialized successfully")
                return True
            else:
                # We log this as info rather than warning to avoid cluttering logs during dev
                # The developer can drop the JSON file in anytime to activate real pushes
                return False
        except Exception as e:
            logger.error(f"Failed to initialize Firebase Admin SDK: {e}")
            return False

    @staticmethod
    def send_to_user(db: Session, user_id: uuid.UUID, title: str, body: str, data: dict = None):
        """Send a personalized push notification to a specific user."""
        user = db.query(User).filter(User.account_id == user_id).first()
        if not user or not user.fcm_token:
            logger.info(f"[NO TOKEN] Skipping notification for user {user_id}: {title}")
            return

        if not NotificationService._initialize():
            logger.info(f"[SIMULATED PUSH] User: {user.email} | Title: {title} | Body: {body}")
            return

        try:
            message = messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                data=data or {},
                token=user.fcm_token,
            )
            messaging.send(message)
        except Exception as e:
            logger.error(f"Failed to send push to user {user_id}: {e}")

    @staticmethod
    def send_to_topic(topic: str, title: str, body: str, data: dict = None):
        """Broadcast a message to everyone subscribed to a topic (e.g. campaign_id)."""
        if not NotificationService._initialize():
            logger.info(f"[SIMULATED BROADCAST] Topic: {topic} | Title: {title}")
            return

        try:
            message = messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                data=data or {},
                topic=topic,
            )
            messaging.send(message)
        except Exception as e:
            logger.error(f"Failed to send topic broadcast to {topic}: {e}")

    # --- High Level Event Handlers ---

    @staticmethod
    def notify_investment_confirmed(db: Session, contributor_id: uuid.UUID, campaign_title: str, amount: float):
        NotificationService.send_to_user(
            db, 
            contributor_id, 
            "Investment Confirmed", 
            f"Your contribution of KES {amount:,.0f} to '{campaign_title}' has been received."
        )

    @staticmethod
    def notify_campaign_funded(db: Session, fundraiser_id: uuid.UUID, campaign_id: uuid.UUID, title: str):
        # Notify Fundraiser
        NotificationService.send_to_user(
            db, fundraiser_id, "Goal Reached", f"Your campaign '{title}' is now fully funded!"
        )
        # Notify all contributors via Topic
        NotificationService.send_to_topic(
            str(campaign_id), 
            "Project Funded", 
            f"The project '{title}' has reached its goal. Phases will start soon!"
        )

    @staticmethod
    def notify_voting_started(campaign_id: uuid.UUID, campaign_title: str, phase_number: int):
        NotificationService.send_to_topic(
            str(campaign_id),
            "Voting Window Open",
            f"Phase {phase_number} for '{campaign_title}' is ready for review. Cast your vote now!"
        )

    @staticmethod
    def notify_withdrawal_completed(db: Session, fundraiser_id: uuid.UUID, title: str, amount: float):
        NotificationService.send_to_user(
            db, fundraiser_id, "Withdrawal Successful", 
            f"Funds of KES {amount:,.0f} from '{title}' have been sent to your account."
        )

    @staticmethod
    def notify_milestone_submission_required(db: Session, fundraiser_id: uuid.UUID, title: str, phase_number: int):
        NotificationService.send_to_user(
            db, fundraiser_id, "Submission Required", 
            f"It's time to submit evidence for Phase {phase_number} of '{title}'."
        )

    @staticmethod
    def notify_vote_results(campaign_id: uuid.UUID, title: str, phase_number: int, approved: bool, percentage: float):
        result_text = "Approved" if approved else "Rejected"
        NotificationService.send_to_topic(
            str(campaign_id),
            "Voting Results Available",
            f"Phase {phase_number} for '{title}' has been {result_text} with {percentage}% approval."
        )

    @staticmethod
    def notify_campaign_completed(campaign_id: uuid.UUID, title: str):
        NotificationService.send_to_topic(
            str(campaign_id),
            "Campaign Completed",
            f"Success! The campaign '{title}' has successfully completed all its phases."
        )

    @staticmethod
    def notify_campaign_failed(campaign_id: uuid.UUID, title: str):
        NotificationService.send_to_topic(
            str(campaign_id),
            "Campaign Failed",
            f"The campaign '{title}' has failed due to a rejected phase and was unable to continue."
        )
