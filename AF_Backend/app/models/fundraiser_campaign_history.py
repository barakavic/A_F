from sqlalchemy import Column, ForeignKey, DateTime, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime
from app.db.base_class import Base

class FundraiserCampaignHistory(Base):
    __tablename__ = "fundraiser_campaign_history"
    
    history_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    fundraiser_id = Column(UUID(as_uuid=True), ForeignKey("fundraiser_profile.fundraiser_id"))
    campaign_id = Column(UUID(as_uuid=True), ForeignKey("campaign.campaign_id"))
    
    is_successful = Column(Boolean)  # TRUE if campaign completed all milestones
    is_high_budget = Column(Boolean)  # TRUE if campaign exceeded the high-budget threshold
    completed_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    fundraiser = relationship("FundraiserProfile")
    campaign = relationship("Campaign")
