from sqlalchemy import Column, ForeignKey, DateTime, Numeric
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime
from app.db.base_class import Base

class FundRelease(Base):
    __tablename__ = "fund_release"
    
    release_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    campaign_id = Column(UUID(as_uuid=True), ForeignKey("campaign.campaign_id"))
    milestone_id = Column(UUID(as_uuid=True), ForeignKey("milestone.milestone_id"))
    
    amount_released = Column(Numeric(12, 2))
    released_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    campaign = relationship("Campaign")
    milestone = relationship("Milestone")
