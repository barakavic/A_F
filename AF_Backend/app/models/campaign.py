from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Numeric, Enum, Text, Boolean
from sqlalchemy.orm import relationship
from app.db.base_class import GUID
import uuid
from datetime import datetime
from app.db.base_class import Base

class Campaign(Base):
    __tablename__ = "campaign"
    
    campaign_id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    fundraiser_id = Column(GUID(), ForeignKey("fundraiser_profile.fundraiser_id"))
    title = Column(String(200))
    description = Column(Text)
    funding_goal_f = Column(Numeric(12, 2))
    duration_d = Column(Integer) # in months
    campaign_type_ct = Column(Enum('donation', name='campaign_type'), default='donation')
    
    funding_start_date = Column(DateTime)
    funding_end_date = Column(DateTime)
    
    category_c = Column(Numeric(4, 3))
    num_phases_p = Column(Integer)
    alpha_value = Column(Numeric(4, 3))
    
    total_contributions = Column(Numeric(12, 2), default=0)
    total_released = Column(Numeric(12, 2), default=0)
    
    status = Column(Enum('draft', 'active', 'funded', 'in_phases', 'completed', 'failed', name='campaign_status'), default='draft')
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    fundraiser = relationship("FundraiserProfile", back_populates="campaigns")
    milestones = relationship("Milestone", back_populates="campaign")
    escrow_account = relationship("EscrowAccount", back_populates="campaign", uselist=False)
    vote_tokens = relationship("VoteToken", back_populates="campaign")

