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
    
    transaction_type = Column(String(50)) # e.g., 'contribution', 'disbursement', 'refund'
    amount = Column(Numeric(12, 2))
    reference_code = Column(String(100)) # M-Pesa code etc.
    
    created_at = Column(DateTime, default=datetime.utcnow)

class Contribution(Base):
    __tablename__ = "contribution"
    
    contribution_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    campaign_id = Column(UUID(as_uuid=True), ForeignKey("campaign.campaign_id"))
    contributor_id = Column(UUID(as_uuid=True), ForeignKey("account.account_id"))
    
    amount = Column(Numeric(12, 2))
    status = Column(String(20), default='pending')
    created_at = Column(DateTime, default=datetime.utcnow)
    
    campaign = relationship("Campaign")
    contributor = relationship("User")
