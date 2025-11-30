from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Numeric, Enum, Text, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime
from app.db.base_class import Base

class VoteResult(Base):
    __tablename__ = "vote_result"
    
    result_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    milestone_id = Column(UUID(as_uuid=True), ForeignKey("milestone.milestone_id"))
    
    total_yes = Column(Integer, default=0)
    total_no = Column(Integer, default=0)
    quorum = Column(Integer, default=0)
    yes_percentage = Column(Numeric(5, 2))
    outcome = Column(Enum('approved', 'rejected', name='vote_outcome'))
    
    tallied_at = Column(DateTime, default=datetime.utcnow)
    
    milestone = relationship("Milestone", back_populates="vote_result")

class VoteToken(Base):
    __tablename__ = "vote_token"
    
    token_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    campaign_id = Column(UUID(as_uuid=True), ForeignKey("campaign.campaign_id"))
    contributor_id = Column(UUID(as_uuid=True), ForeignKey("account.account_id")) # Linking to User (contributor)
    
    token_hash = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    campaign = relationship("Campaign", back_populates="vote_tokens")
    contributor = relationship("User")

class VoteSubmission(Base):
    __tablename__ = "vote_submission"
    
    vote_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    milestone_id = Column(UUID(as_uuid=True), ForeignKey("milestone.milestone_id"))
    contributor_id = Column(UUID(as_uuid=True), ForeignKey("account.account_id"))
    
    vote_hash = Column(Text)
    signature = Column(Text) # Digital signature of the vote
    vote_value = Column(Enum('yes', 'no', name='vote_value'))
    submitted_at = Column(DateTime, default=datetime.utcnow)
    
    milestone = relationship("Milestone", back_populates="vote_submissions")
    contributor = relationship("User")

    # Prevent double voting: One vote per contributor per milestone
    __table_args__ = (
        UniqueConstraint('milestone_id', 'contributor_id', name='uq_vote_milestone_contributor'),
    )
