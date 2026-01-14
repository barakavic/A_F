from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Numeric, Enum, Text
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime
from app.db.base_class import Base

class Milestone(Base):
    __tablename__ = "milestone"
    
    milestone_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    campaign_id = Column(UUID(as_uuid=True), ForeignKey("campaign.campaign_id"))
    
    phase_index = Column(Integer)
    description = Column(Text)  # What the fundraiser will deliver in this phase
    phase_weight_wi = Column(Numeric(6, 5))
    disbursement_percentage_di = Column(Numeric(6, 5))
    release_amount = Column(Numeric(12, 2))
    
    vote_window_start = Column(DateTime)
    vote_window_end = Column(DateTime)
    deadline = Column(DateTime)
    
    status = Column(Enum('pending', 'approved', 'rejected', 'released', name='milestone_status'), default='pending')
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    campaign = relationship("Campaign", back_populates="milestones")
    vote_result = relationship("VoteResult", back_populates="milestone", uselist=False)
    vote_submissions = relationship("VoteSubmission", back_populates="milestone")
    evidence = relationship("MilestoneEvidence", back_populates="milestone")
