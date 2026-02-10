from sqlalchemy.orm import Session
from app.models.milestone import Milestone
from app.models.campaign import Campaign
from app.models.escrow import EscrowAccount
from app.models.transaction import TransactionLedger, Contribution
from app.models.fund_release import FundRelease
from app.models.refund_event import RefundEvent
from datetime import datetime
from uuid import UUID, uuid4
from decimal import Decimal

class FinancialWorkflowService:

    @staticmethod
    def release_milestone_funds(db: Session, milestone_id: UUID) -> bool:
        """
        Moves money from Escrow to Fundraiser after milestone approval.
        Updates the ledger and escrow balance.
        """
        milestone = db.query(Milestone).filter(Milestone.milestone_id == milestone_id).first()
        if not milestone or milestone.status != 'approved':
            raise ValueError("Milestone must be approved before funds can be released")

        if milestone.funds_released_at:
            raise ValueError("Funds have already been released for this milestone")

        campaign = milestone.campaign
        escrow = db.query(EscrowAccount).filter(EscrowAccount.campaign_id == campaign.campaign_id).first()
        
        amount_to_release = Decimal(str(milestone.release_amount))

        if escrow.balance < amount_to_release:
            raise ValueError("Insufficient escrow balance for release")

        # 1. Deduct from Escrow
        escrow.balance -= amount_to_release
        
        # 2. Create FundRelease entry
        release = FundRelease(
            release_id=uuid4(),
            campaign_id=campaign.campaign_id,
            milestone_id=milestone.milestone_id,
            amount_released=amount_to_release,
            released_at=datetime.utcnow()
        )
        db.add(release)
        db.flush() # Get the release_id

        # 3. Record in Ledger
        ledger_entry = TransactionLedger(
            transaction_id=uuid4(),
            escrow_id=escrow.escrow_id,
            fund_release_id=release.release_id,
            transaction_type='disbursement',
            amount=amount_to_release,
            reference_code=f"REL-{milestone.milestone_number}-{uuid4().hex[:8].upper()}",
            created_at=datetime.utcnow()
        )
        db.add(ledger_entry)

        # 4. Mark milestone as released
        milestone.status = 'released'
        milestone.funds_released_at = datetime.utcnow()
        
        db.commit()
        return True

    @staticmethod
    def initiate_bulk_refunds(db: Session, campaign_id: UUID, reason: str = "Campaign failure") -> dict:
        """
        Calculates pro-rata refunds for ALL contributors when a campaign fails.
        """
        campaign = db.query(Campaign).filter(Campaign.campaign_id == campaign_id).first()
        escrow = db.query(EscrowAccount).filter(EscrowAccount.campaign_id == campaign_id).first()
        
        if escrow.balance <= 0:
            return {"status": "skipped", "reason": "No funds to refund"}

        # Get all contributions to calculate pro-rata shares
        contributions = db.query(Contribution).filter(
            Contribution.campaign_id == campaign_id,
            Contribution.status == 'completed'
        ).all()
        
        if not contributions:
            return {"status": "skipped", "reason": "No completed contributions found"}

        total_contributed = sum(Decimal(str(c.amount)) for c in contributions)
        
        remaining_escrow = escrow.balance
        refund_stats = {"total_refunded": 0, "contributor_count": len(contributions)}

        for contribution in contributions:
            # Formula: (User Contribution / Total Contributed) * Current Escrow Balance
            share_ratio = Decimal(str(contribution.amount)) / total_contributed
            refund_amount = (share_ratio * remaining_escrow).quantize(Decimal('0.01'))

            # 1. Create Refund Event
            refund_event = RefundEvent(
                refund_id=uuid4(),
                campaign_id=campaign_id,
                contributor_id=contribution.contributor_id,
                amount_refunded=refund_amount,
                refund_reason=reason,
                refunded_at=datetime.utcnow()
            )
            db.add(refund_event)
            db.flush()

            # 2. Create Ledger Entry
            ledger_entry = TransactionLedger(
                transaction_id=uuid4(),
                escrow_id=escrow.escrow_id,
                refund_event_id=refund_event.refund_id,
                transaction_type='refund',
                amount=refund_amount,
                reference_code=f"REF-{uuid4().hex[:8].upper()}",
                created_at=datetime.utcnow()
            )
            db.add(ledger_entry)

            # 3. Update Contribution Status
            contribution.status = 'refunded'
            
            refund_stats["total_refunded"] += float(refund_amount)

        # Deduct total from escrow once all pending entries are created
        escrow.balance = 0
        campaign.status = 'failed'
        campaign.failed_at = datetime.utcnow()

        db.commit()
        return refund_stats
