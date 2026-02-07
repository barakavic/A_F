from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Numeric, Enum, Text
from sqlalchemy.orm import relationship
from app.db.base_class import GUID
import uuid
from datetime import datetime
from app.db.base_class import Base

class Milestone(Base):
    __tablename__ = "milestone"
    
    milestone_id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    campaign_id = Column(GUID(), ForeignKey("campaign.campaign_id"))
    
    milestone_number = Column(Integer, nullable=False) # 1 to P
    description = Column(Text)
    phase_weight_wi = Column(Numeric(6, 5))
    disbursement_percentage_di = Column(Numeric(6, 5))
    release_amount = Column(Numeric(12, 2))
    
    # Timeline Markers
    activated_at = Column(DateTime, nullable=True)
    evidence_submitted_at = Column(DateTime, nullable=True)
    voting_start_date = Column(DateTime, nullable=True)
    voting_end_date = Column(DateTime, nullable=True)
    approved_at = Column(DateTime, nullable=True)
    rejected_at = Column(DateTime, nullable=True)
    funds_released_at = Column(DateTime, nullable=True)
    
    # Revision Control
    revision_count = Column(Integer, default=0)
    max_revisions = Column(Integer, default=1)
    
    status = Column(Enum(
        'pending', 
        'active', 
        'evidence_submitted', 
        'voting_open', 
        'voting_closed', 
        'approved', 
        'rejected', 
        'revision_submitted', 
        'failed', 
        'released', 
        name='milestone_status'
    ), default='pending')
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    campaign = relationship("Campaign", back_populates="milestones")
    vote_result = relationship("VoteResult", back_populates="milestone", uselist=False)
    vote_submissions = relationship("VoteSubmission", back_populates="milestone")
    evidence = relationship("MilestoneEvidence", back_populates="milestone")
