from typing import List, Optional
from pydantic import BaseModel, Field
from uuid import UUID
from datetime import datetime
from decimal import Decimal

class MilestoneBase(BaseModel):
    milestone_number: int
    description: Optional[str] = None
    phase_weight_wi: Decimal
    disbursement_percentage_di: Decimal
    release_amount: Decimal
    status: str
    
    # New Markers
    activated_at: Optional[datetime] = None
    evidence_submitted_at: Optional[datetime] = None
    voting_start_date: Optional[datetime] = None
    voting_end_date: Optional[datetime] = None
    approved_at: Optional[datetime] = None
    rejected_at: Optional[datetime] = None
    funds_released_at: Optional[datetime] = None
    target_deadline: Optional[datetime] = None
    revision_count: int = 0
    max_revisions: int = 1

class MilestoneEvidenceOut(BaseModel):
    evidence_id: UUID
    file_path: Optional[str] = None
    file_type: Optional[str] = None
    description: Optional[str] = None
    is_verified: bool
    uploaded_at: datetime
    
    class Config:
        from_attributes = True

class MilestoneOut(MilestoneBase):
    milestone_id: UUID
    evidence: List[MilestoneEvidenceOut] = []
    
    class Config:
        from_attributes = True

class CampaignBase(BaseModel):
    title: str
    description: str
    funding_goal_f: Decimal = Field(..., alias="funding_goal")
    duration_d: int = Field(..., alias="duration_months")
    category: str = "General"
    campaign_type_ct: str = Field("donation", alias="campaign_type")

class CampaignCreate(CampaignBase):
    pass

class CampaignUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = None

class CampaignOut(BaseModel):
    campaign_id: UUID
    fundraiser_id: UUID
    fundraiser_name: str
    title: str
    description: str
    funding_goal_f: Decimal
    duration_d: int
    campaign_type_ct: str
    status: str
    category_c: Decimal
    num_phases_p: int
    alpha_value: Decimal
    cover_image_url: Optional[str] = None
    backers_count: int
    days_left: int
    category_name: str
    total_contributions: Decimal
    total_released: Decimal
    
    # New Markers
    submitted_for_review_at: Optional[datetime] = None
    approved_at: Optional[datetime] = None
    launched_at: Optional[datetime] = None
    funded_at: Optional[datetime] = None
    phases_started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    failed_at: Optional[datetime] = None
    current_milestone_number: int = 0
    milestones_approved_count: int = 0
    milestones_rejected_count: int = 0
    
    created_at: datetime
    updated_at: datetime
    
    milestones: List[MilestoneOut] = []

    class Config:
        from_attributes = True
        populate_by_name = True

class CampaignProgress(BaseModel):
    status: str
    funding_percentage: float
    total_contributions: Decimal
    funding_goal: Decimal
    milestones_total: int
    milestones_completed: int
    current_milestone_number: Optional[int] = None
    next_action_required: str
    days_remaining: Optional[int] = None

class FundraiserStats(BaseModel):
    total_raised: Decimal
    active_phases_count: int
    available_balance: Decimal
    escrow_balance: Decimal
    active_projects_count: int
