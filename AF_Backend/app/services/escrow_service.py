from sqlalchemy.orm import Session
from app.models.escrow import EscrowAccount
from app.models.fund_release import FundRelease
from app.models.milestone import Milestone
from app.models.transaction import TransactionLedger
from app.services.transaction_service import TransactionService
from decimal import Decimal
import uuid

class EscrowService:
    @staticmethod
    def release_milestone_funds(db: Session, milestone_id: uuid.UUID) -> FundRelease:
        """
        Release funds for an approved milestone.
        Amount released = Campaign.target_amount * Milestone.weight
        """
        # 1. Get Milestone and Campaign
        milestone = db.query(Milestone).filter(Milestone.milestone_id == milestone_id).first()
        if not milestone:
            raise ValueError("Milestone not found")
        
        if milestone.status != 'approved':
            raise ValueError(f"Cannot release funds for milestone with status: {milestone.status}")
        
        # Check if already released
        existing_release = db.query(FundRelease).filter(FundRelease.milestone_id == milestone_id).first()
        if existing_release:
            raise ValueError("Funds already released for this milestone")

        campaign = milestone.campaign
        if not campaign:
            raise ValueError("Campaign not found for milestone")

        # 2. Calculate release amount
        # Note: In a real scenario, we might release based on TOTAL RAISED if target wasn't met,
        # but here we assume target is met or we release proportional to target.
        # Let's use funding_goal_f * phase_weight_wi
        release_amount = Decimal(str(campaign.funding_goal_f)) * Decimal(str(milestone.phase_weight_wi))

        # 3. Get Escrow Account
        escrow = db.query(EscrowAccount).filter(EscrowAccount.campaign_id == campaign.campaign_id).first()
        if not escrow:
            raise ValueError("Escrow account not found for campaign")
        
        if escrow.balance < release_amount:
            # This shouldn't happen if target was met, but good to check
            raise ValueError(f"Insufficient escrow balance. Required: {release_amount}, Available: {escrow.balance}")

        # 4. Create FundRelease record
        release = FundRelease(
            campaign_id=campaign.campaign_id,
            milestone_id=milestone_id,
            amount_released=release_amount
        )
        db.add(release)
        db.flush() # Get release_id

        # 5. Record in Ledger and update Escrow balance via TransactionService
        TransactionService.record_disbursement(
            db=db,
            fund_release_id=release.release_id,
            escrow_id=escrow.escrow_id,
            amount=release_amount
        )

        db.commit()
        db.refresh(release)
        return release

    @staticmethod
    def get_escrow_summary(db: Session, campaign_id: uuid.UUID):
        """
        Get a summary of the escrow state for a campaign.
        """
        escrow = db.query(EscrowAccount).filter(EscrowAccount.campaign_id == campaign_id).first()
        if not escrow:
            return None
        
        return {
            "total_contributions": escrow.total_contributions,
            "total_released": escrow.total_released,
            "balance": escrow.balance,
            "updated_at": escrow.updated_at
        }
