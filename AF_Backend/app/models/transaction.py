from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Numeric, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime
from app.db.base_class import Base

class TransactionLedger(Base):
    __tablename__ = "transaction_ledger"
    
    transaction_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    escrow_id = Column(UUID(as_uuid=True), ForeignKey("escrow_account.escrow_id"))
    
    # Link to the source transaction record
    contribution_id = Column(UUID(as_uuid=True), ForeignKey("contribution.contribution_id"), nullable=True)
    fund_release_id = Column(UUID(as_uuid=True), ForeignKey("fund_release.release_id"), nullable=True)
    refund_event_id = Column(UUID(as_uuid=True), ForeignKey("refund_event.refund_id"), nullable=True)
    
    transaction_type = Column(Enum('contribution', 'disbursement', 'refund', name='transaction_type'))
    amount = Column(Numeric(12, 2))
    reference_code = Column(String(100)) # External payment reference (e.g., M-Pesa code)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    escrow = relationship("EscrowAccount")
    contribution = relationship("Contribution")
    fund_release = relationship("FundRelease")
    refund_event = relationship("RefundEvent")

class Contribution(Base):
    __tablename__ = "contribution"
    
    contribution_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    campaign_id = Column(UUID(as_uuid=True), ForeignKey("campaign.campaign_id"))
    contributor_id = Column(UUID(as_uuid=True), ForeignKey("account.account_id"))
    
    amount = Column(Numeric(12, 2))
    status = Column(Enum('pending', 'completed', 'failed', 'refunded', name='contribution_status'), default='pending')
    created_at = Column(DateTime, default=datetime.utcnow)
    
    campaign = relationship("Campaign")
    contributor = relationship("User")
