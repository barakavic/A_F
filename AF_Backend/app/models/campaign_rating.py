from sqlalchemy import Column, Integer, ForeignKey, DateTime, Text, CheckConstraint
from sqlalchemy.orm import relationship
from app.db.base_class import GUID
import uuid
from datetime import datetime
from app.db.base_class import Base

class CampaignRating(Base):
    __tablename__ = "campaign_rating"
    
    campaign_rating_id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    campaign_id = Column(GUID(), ForeignKey("campaign.campaign_id"))
    contributor_id = Column(GUID(), ForeignKey("account.account_id"))
    
    rating_value = Column(Integer)  # Rating value from 1 to 5
    comment = Column(Text)  # Optional rating feedback
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    campaign = relationship("Campaign")
    contributor = relationship("User")
    
    # Constraint to ensure rating is between 1 and 5
    __table_args__ = (
        CheckConstraint('rating_value >= 1 AND rating_value <= 5', name='check_rating_range'),
    )
