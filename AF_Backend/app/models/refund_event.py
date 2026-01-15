from sqlalchemy import Column, ForeignKey, DateTime, Numeric, Text
from sqlalchemy.orm import relationship
from app.db.base_class import GUID
import uuid
from datetime import datetime
from app.db.base_class import Base

class RefundEvent(Base):
    __tablename__ = "refund_event"
    
    refund_id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    campaign_id = Column(GUID(), ForeignKey("campaign.campaign_id"))
    contributor_id = Column(GUID(), ForeignKey("account.account_id"))
    
    amount_refunded = Column(Numeric(12, 2))
    refund_reason = Column(Text)  # "Milestone failure", "Voting timeout", etc.
    refunded_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    campaign = relationship("Campaign")
    contributor = relationship("User")
