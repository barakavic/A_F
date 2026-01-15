from sqlalchemy.orm import Session
from app.models.transaction import Contribution
from app.models.escrow import EscrowAccount
from app.models.refund_event import RefundEvent
from app.services.transaction_service import TransactionService
from decimal import Decimal
import uuid

class RefundService:
    @staticmethod
    def process_campaign_refunds(db: Session, campaign_id: uuid.UUID, reason: str = "Milestone failure"):
        """
        Processes refunds for all contributors of a campaign.
        Refund is proportional to the remaining escrow balance.
        """
        # 1. Get Escrow Account
        escrow = db.query(EscrowAccount).filter(EscrowAccount.campaign_id == campaign_id).first()
        if not escrow or escrow.balance <= 0:
            print(f"[REFUND] No balance to refund for campaign {campaign_id}")
            return []

        # 2. Get all successful contributions
        contributions = db.query(Contribution).filter(
            Contribution.campaign_id == campaign_id,
            Contribution.status == 'completed'
        ).all()

        if not contributions:
            print(f"[REFUND] No completed contributions found for campaign {campaign_id}")
            return []

        total_contributions = escrow.total_contributions
        current_balance = escrow.balance
        refund_events = []

        # 3. Calculate and record refund for each contributor
        for contribution in contributions:
            # Pro-rata refund calculation: (User Contribution / Total Contributions) * Remaining Balance
            # This handles cases where some funds were already released for previous milestones.
            refund_amount = (contribution.amount / total_contributions) * current_balance
            
            # Round to 2 decimal places for currency
            refund_amount = refund_amount.quantize(Decimal('0.01'))

            if refund_amount <= 0:
                continue

            # Create RefundEvent
            refund_event = RefundEvent(
                campaign_id=campaign_id,
                contributor_id=contribution.contributor_id,
                amount_refunded=refund_amount,
                refund_reason=reason
            )
            db.add(refund_event)
            db.flush() # Get refund_id

            # Record in Ledger and update Escrow balance
            TransactionService.record_refund(
                db=db,
                refund_event_id=refund_event.refund_id,
                escrow_id=escrow.escrow_id,
                amount=refund_amount
            )

            # Update contribution status
            contribution.status = 'refunded'
            
            refund_events.append(refund_event)
            print(f"[SIMULATION] Refunded {refund_amount} to contributor {contribution.contributor_id}")

        db.commit()
        return refund_events
