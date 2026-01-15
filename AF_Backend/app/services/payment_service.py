from sqlalchemy.orm import Session
from app.models.campaign import Campaign
from app.models.user import User
from app.services.contribution_service import ContributionService
from app.core.redis import save_stk_session, get_stk_session, delete_stk_session
from app.core.config import settings
import uuid
from typing import Dict, Any

class PaymentService:
    @staticmethod
    def initiate_stk_push(
        db: Session,
        campaign_id: uuid.UUID,
        contributor_id: uuid.UUID,
        amount: float,
        phone_number: str
    ) -> Dict[str, Any]:
        """
        Initiate an STK Push request (Simulator Mode).
        
        In production, this will call Safaricom's Daraja API.
        For now, it generates a fake CheckoutRequestID and stores the session in Redis.
        
        Args:
            db: Database session
            campaign_id: UUID of the campaign
            contributor_id: UUID of the contributor
            amount: Amount to contribute
            phone_number: M-Pesa phone number (format: 254XXXXXXXXX)
        
        Returns:
            Dictionary with status and checkout_request_id
        """
        # Validate campaign exists and is active
        campaign = db.query(Campaign).filter(Campaign.campaign_id == campaign_id).first()
        if not campaign:
            raise ValueError("Campaign not found")
        if campaign.status != 'active':
            raise ValueError(f"Campaign is not active. Current status: {campaign.status}")
        
        # Validate contributor exists
        contributor = db.query(User).filter(User.account_id == contributor_id).first()
        if not contributor:
            raise ValueError("Contributor not found")
        
        # Generate a fake CheckoutRequestID (in production, this comes from Safaricom)
        checkout_request_id = f"ws_CO_{uuid.uuid4().hex[:12]}"
        
        # Prepare session data
        session_data = {
            "campaign_id": str(campaign_id),
            "contributor_id": str(contributor_id),
            "amount": float(amount),
            "phone_number": phone_number
        }
        
        # Save to Redis with 10-minute TTL
        save_stk_session(checkout_request_id, session_data)
        
        return {
            "status": "pending",
            "checkout_request_id": checkout_request_id,
            "message": "STK Push sent. Please enter your PIN."
        }
    
    @staticmethod
    def process_stk_callback(
        db: Session,
        checkout_request_id: str,
        result_code: int,
        result_desc: str
    ) -> Dict[str, Any]:
        """
        Process the callback from M-Pesa (or simulator).
        
        Args:
            db: Database session
            checkout_request_id: The CheckoutRequestID from the original request
            result_code: 0 for success, non-zero for failure
            result_desc: Description of the result
        
        Returns:
            Dictionary with processing status
        """
        # Retrieve session from Redis
        session_data = get_stk_session(checkout_request_id)
        
        if not session_data:
            return {
                "status": "error",
                "message": "Session not found or expired"
            }
        
        try:
            if result_code == 0:
                # Success - Create the contribution
                campaign_id = uuid.UUID(session_data["campaign_id"])
                contributor_id = uuid.UUID(session_data["contributor_id"])
                amount = session_data["amount"]
                
                # This triggers the entire flow: Escrow update, Ledger entry, Vote token
                ContributionService.create_contribution(
                    db=db,
                    campaign_id=campaign_id,
                    contributor_id=contributor_id,
                    amount=amount
                )
                
                # Clean up Redis session
                delete_stk_session(checkout_request_id)
                
                return {
                    "status": "success",
                    "message": "Payment processed successfully"
                }
            else:
                # Failure - Log and clean up
                print(f"Payment failed: {result_desc}")
                delete_stk_session(checkout_request_id)
                
                return {
                    "status": "failed",
                    "message": f"Payment failed: {result_desc}"
                }
        except Exception as e:
            # Clean up even on error
            delete_stk_session(checkout_request_id)
            raise e
