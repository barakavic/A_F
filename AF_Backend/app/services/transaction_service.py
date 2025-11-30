from sqlalchemy.orm import Session
from app.models.transaction import TransactionLedger, Contribution
from app.models.escrow import EscrowAccount
from app.models.fund_release import FundRelease
from app.models.refund_event import RefundEvent
from decimal import Decimal
import uuid

class TransactionService:
    @staticmethod
    def record_contribution(
        db: Session,
        contribution_id: uuid.UUID,
        escrow_id: uuid.UUID,
        amount: Decimal,
        reference_code: str = None
    ):
        """
        Record a contribution transaction and update escrow balance.
        Amount is POSITIVE (money coming IN).
        """
        # 1. Create ledger entry
        ledger_entry = TransactionLedger(
            escrow_id=escrow_id,
            contribution_id=contribution_id,
            transaction_type='contribution',
            amount=amount,  # Positive value
            reference_code=reference_code
        )
        db.add(ledger_entry)
        
        # 2. Update escrow account with row-level locking and atomic update
        escrow = db.query(EscrowAccount).filter(
            EscrowAccount.escrow_id == escrow_id
        ).with_for_update().first()
        
        if escrow:
            # Use atomic SQL update to prevent race conditions
            from sqlalchemy import update
            db.execute(
                update(EscrowAccount)
                .where(EscrowAccount.escrow_id == escrow_id)
                .values(
                    total_contributions=EscrowAccount.total_contributions + amount,
                    balance=EscrowAccount.balance + amount
                )
            )
        
        db.commit()
        return ledger_entry
    
    @staticmethod
    def record_disbursement(
        db: Session,
        fund_release_id: uuid.UUID,
        escrow_id: uuid.UUID,
        amount: Decimal
    ):
        """
        Record a fund release transaction and update escrow balance.
        Amount is POSITIVE in ledger, but DECREASES balance (money going OUT).
        """
        # 1. Create ledger entry
        ledger_entry = TransactionLedger(
            escrow_id=escrow_id,
            fund_release_id=fund_release_id,
            transaction_type='disbursement',
            amount=amount  # Store as positive, but will subtract from balance
        )
        db.add(ledger_entry)
        
        # 2. Update escrow account with row-level locking and atomic update
        escrow = db.query(EscrowAccount).filter(
            EscrowAccount.escrow_id == escrow_id
        ).with_for_update().first()
        
        if escrow:
            from sqlalchemy import update
            db.execute(
                update(EscrowAccount)
                .where(EscrowAccount.escrow_id == escrow_id)
                .values(
                    total_released=EscrowAccount.total_released + amount,
                    balance=EscrowAccount.balance - amount  # SUBTRACT
                )
            )
        
        db.commit()
        return ledger_entry
    
    @staticmethod
    def record_refund(
        db: Session,
        refund_event_id: uuid.UUID,
        escrow_id: uuid.UUID,
        amount: Decimal
    ):
        """
        Record a refund transaction and update escrow balance.
        Amount is POSITIVE in ledger, but DECREASES balance (money going OUT).
        """
        # 1. Create ledger entry
        ledger_entry = TransactionLedger(
            escrow_id=escrow_id,
            refund_event_id=refund_event_id,
            transaction_type='refund',
            amount=amount  # Store as positive, but will subtract from balance
        )
        db.add(ledger_entry)
        
        # 2. Update escrow account with row-level locking and atomic update
        escrow = db.query(EscrowAccount).filter(
            EscrowAccount.escrow_id == escrow_id
        ).with_for_update().first()
        
        if escrow:
            from sqlalchemy import update
            db.execute(
                update(EscrowAccount)
                .where(EscrowAccount.escrow_id == escrow_id)
                .values(
                    balance=EscrowAccount.balance - amount  # SUBTRACT
                )
            )
        
        db.commit()
        return ledger_entry
