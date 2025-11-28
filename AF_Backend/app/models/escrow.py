from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Numeric
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime
from app.db.base_class import Base

class EscrowAccount(Base):
    __tablename__ = "escrow_account"
    
    escrow_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    campaign_id = Column(UUID(as_uuid=True), ForeignKey("campaign.campaign_id"))
    
    total_contributions = Column(Numeric(12, 2), default=0)
    total_released = Column(Numeric(12, 2), default=0)
    balance = Column(Numeric(12, 2), default=0)
    
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    campaign = relationship("Campaign", back_populates="escrow_account")
