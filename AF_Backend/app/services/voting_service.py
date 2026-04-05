from sqlalchemy.orm import Session
import uuid
from app.models.vote import VoteResult, VoteSubmission, VoteToken
from app.models.milestone import Milestone
from app.models.user import ContributorProfile
from app.utils.crypto import verify_vote_signature, verify_waiver_signature, generate_keccak_hash

class VotingService:
    @staticmethod
    def generate_vote_token(db: Session, campaign_id: uuid.UUID, contributor_id: uuid.UUID) -> VoteToken:
        """
        Generate a vote token for a contributor.
        """
        token = VoteToken(
            campaign_id=campaign_id,
            contributor_id=contributor_id,
            token_hash="authorized" 
        )
        db.add(token)
        db.commit()
        db.refresh(token)
        return token

    @staticmethod
    def submit_vote(
        db: Session, 
        milestone_id: uuid.UUID, 
        contributor_id: uuid.UUID, 
        vote_value: str, 
        signature: str, 
        nonce: str
    ) -> VoteSubmission:
        """
        Submit a vote with digital signature verification.
        """
        import sys
        
        # Verify Milestone exists
        milestone = db.query(Milestone).filter(Milestone.milestone_id == milestone_id).first()
        if not milestone:
            print(f"[VOTING] Milestone {milestone_id} not found", file=sys.stderr, flush=True)
            raise ValueError("Milestone not found")

        #Verify Contributor is authorized
        token = db.query(VoteToken).filter(
            VoteToken.campaign_id == milestone.campaign_id,
            VoteToken.contributor_id == contributor_id
        ).first()

        if not token:
            print(f"[VOTING] Unauthorized: no token for contributor {contributor_id} on campaign {milestone.campaign_id}", file=sys.stderr, flush=True)
            raise ValueError("Unauthorized to vote on this campaign")

        # Get Contributor's Public Key
        profile = db.query(ContributorProfile).filter(ContributorProfile.contributor_id == contributor_id).first()
        
        # Verify Digital Signature
        is_valid = verify_vote_signature(
            campaign_id=str(milestone.campaign_id),
            milestone_id=str(milestone_id),
            vote_value=vote_value,
            nonce=nonce,
            signature=signature,
            public_key=profile.public_key if profile else "MissingKey"
        )
        
        if not is_valid:
            from app.utils.crypto import get_vote_message, encode_defunct, Account
            msg = get_vote_message(str(milestone.campaign_id), str(milestone_id), vote_value, nonce)
            recovered = Account.recover_message(encode_defunct(text=msg), signature=signature)
            print(f"[VOTING] Invalid signature from {contributor_id}. Expected: {profile.public_key if profile else 'N/A'}, Recovered: {recovered}", file=sys.stderr, flush=True)
            raise ValueError("Invalid cryptographic signature. Vote rejected.")

        #Check if already voted
        existing_vote = db.query(VoteSubmission).filter(
            VoteSubmission.milestone_id == milestone_id,
            VoteSubmission.contributor_id == contributor_id
        ).first()
        
        if existing_vote:
            raise ValueError("Already voted on this milestone")
            
        # Create vote hash for audit trail
        vote_hash = generate_keccak_hash(f"{signature}{nonce}")
        
        vote = VoteSubmission(
            milestone_id=milestone_id,
            contributor_id=contributor_id,
            vote_value=vote_value,
            vote_hash=vote_hash,
            signature=signature
        )
        db.add(vote)
        db.commit()
        db.refresh(vote)

        # If all users have voted, tally immediately
        total_tokens = db.query(VoteToken).filter(VoteToken.campaign_id == milestone.campaign_id).count()
        total_votes = db.query(VoteSubmission).filter(VoteSubmission.milestone_id == milestone_id).count()

        if total_votes >= total_tokens and total_tokens > 0:
            print(f"[VOTING] 100% participation reached for milestone {milestone_id}. Auto-tallying...")
            VotingService.tally_votes(db, milestone_id)

        return vote


    @staticmethod
    def tally_votes(db: Session, milestone_id: uuid.UUID) -> VoteResult:
        """
        Tally votes for a milestone and determine outcome.
        Consensus required: >= 75% YES.
        """
        votes = db.query(VoteSubmission).filter(VoteSubmission.milestone_id == milestone_id).all()
        
        total_votes = len(votes)
        
        if total_votes == 0:
            yes_votes = 0
            no_votes = 0
            yes_percentage = 0
        else:
            yes_votes = sum(1 for v in votes if str(v.vote_value).lower() == 'yes' or v.is_waived is True)
            no_votes = total_votes - yes_votes
            yes_percentage = (yes_votes / total_votes) * 100
            
        outcome = 'approved' if yes_percentage >= 75 else 'rejected'
        
        # Create the result record
        result = VoteResult(
            milestone_id=milestone_id,
            total_yes=yes_votes,
            total_no=no_votes,
            quorum=total_votes,
            yes_percentage=yes_percentage,
            outcome=outcome
        )
        
        db.add(result)
        
        # Update milestone status
        milestone = db.query(Milestone).filter(Milestone.milestone_id == milestone_id).first()
        if milestone:
            milestone.status = outcome
            
            # TRIGGER BROADCAST EVENT: Voting Results
            from app.services.notification_service import NotificationService
            NotificationService.notify_vote_results(
                milestone.campaign_id,
                milestone.campaign.title,
                milestone.milestone_number,
                outcome == 'approved',
                yes_percentage
            )
            
            # TRIGGER REFUND: If milestone is rejected, the whole campaign is refunded
            if outcome == 'rejected':
                from app.services.campaign_state_service import CampaignStateService
                from app.services.refund_service import RefundService
                
                RefundService.process_campaign_refunds(
                    db=db, 
                    campaign_id=milestone.campaign_id,
                    reason=f"Milestone {milestone.description} rejected by contributors"
                )
                
                # Transition Campaign to FAILED and trigger broadcast
                CampaignStateService.terminate_campaign(db, milestone.campaign_id)
            
            # If milestone is approved, release funds immediately
            if outcome == 'approved':
                from app.services.financial_workflow_service import FinancialWorkflowService
                try:
                    FinancialWorkflowService.release_milestone_funds(db, milestone_id)
                    print(f"[FINANCIAL] Funds released for approved milestone {milestone_id}")
                except Exception as e:
                    print(f"[FINANCIAL_ERROR] Failed to release funds for milestone {milestone_id}: {str(e)}")
        
        db.commit()
        db.refresh(result)
        return result
