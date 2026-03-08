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
    
    cover_image_url = Column(String(255), nullable=True)
    
    category = Column(String(100), nullable=True)
    category_c = Column(Numeric(4, 3))
    num_phases_p = Column(Integer)
    alpha_value = Column(Numeric(4, 3))
    
    total_contributions = Column(Numeric(12, 2), default=0)
    total_released = Column(Numeric(12, 2), default=0)

    # Timeline Markers
    submitted_for_review_at = Column(DateTime, nullable=True)
    approved_at = Column(DateTime, nullable=True)
    launched_at = Column(DateTime, nullable=True)
    funded_at = Column(DateTime, nullable=True)
    phases_started_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)
    failed_at = Column(DateTime, nullable=True)
    
    # Progress Tracking
    current_milestone_number = Column(Integer, default=0)
    milestones_approved_count = Column(Integer, default=0)
    milestones_rejected_count = Column(Integer, default=0)
    
    status = Column(Enum(
        'draft', 
        'pending_review', 
        'active', 
        'funded', 
        'in_phases', 
        'completed', 
        'failed', 
        name='campaign_status'
    ), default='draft')
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    fundraiser = relationship("FundraiserProfile", back_populates="campaigns")
    milestones = relationship("Milestone", back_populates="campaign")
    escrow_account = relationship("EscrowAccount", back_populates="campaign", uselist=False)
    vote_tokens = relationship("VoteToken", back_populates="campaign")

    @property
    def fundraiser_name(self) -> str:
        if self.fundraiser:
            return self.fundraiser.company_name or "Unknown Fundraiser"
        return "Unknown Fundraiser"

    @property
    def backers_count(self) -> int:
        from app.models.transaction import Contribution
        from sqlalchemy import select, func
        from app.db.session import SessionLocal
        
        db = SessionLocal()
        try:
            count = db.query(func.count(func.distinct(Contribution.contributor_id))).\
                filter(Contribution.campaign_id == self.campaign_id, Contribution.status == 'completed').scalar()
            return count or 0
        finally:
            db.close()

    @property
    def days_left(self) -> int:
        from datetime import timedelta
        
        # 1. Calculate Seed Phase Duration D_seed = 0.1 * D (in months) * 30 days
        d_seed_months = max(0.1 * float(self.duration_d), 0.1) if self.duration_d else 0.1
        d_seed_days = int(d_seed_months * 30)
        
        # 2. If Draft, show total seed days available
        if self.status == 'draft' or not self.funding_start_date:
            return d_seed_days
            
        # 3. If Active (Seed Phase running)
        if self.status in ['active', 'pending_review']:
            seed_end_date = self.funding_start_date + timedelta(days=d_seed_days)
            delta = seed_end_date - datetime.utcnow()
            return max(0, delta.days)
            
        # 4. If funded or beyond, seed phase is over.
        return 0

    @property
    def category_name(self) -> str:
        if self.category:
            return self.category
        if self.fundraiser and self.fundraiser.industry_l1:
            return self.fundraiser.industry_l1.l1_name
        return "General"

