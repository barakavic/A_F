from sqlalchemy import Column, ForeignKey, DateTime, Numeric
from sqlalchemy.orm import relationship
from app.db.base_class import GUID
import uuid
from datetime import datetime
from app.db.base_class import Base

class FundRelease(Base):
    __tablename__ = "fund_release"
    
    release_id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    campaign_id = Column(GUID(), ForeignKey("campaign.campaign_id"))
    milestone_id = Column(GUID(), ForeignKey("milestone.milestone_id"))
    
    amount_released = Column(Numeric(12, 2))
    released_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    campaign = relationship("Campaign")
    milestone = relationship("Milestone")
