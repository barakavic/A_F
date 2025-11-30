from sqlalchemy import Column, ForeignKey, DateTime, Numeric, Text
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime
from app.db.base_class import Base

class RefundEvent(Base):
    __tablename__ = "refund_event"
    
    refund_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    campaign_id = Column(UUID(as_uuid=True), ForeignKey("campaign.campaign_id"))
    contributor_id = Column(UUID(as_uuid=True), ForeignKey("account.account_id"))
    
    amount_refunded = Column(Numeric(12, 2))
    refund_reason = Column(Text)  # "Milestone failure", "Voting timeout", etc.
    refunded_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    campaign = relationship("Campaign")
    contributor = relationship("User")
