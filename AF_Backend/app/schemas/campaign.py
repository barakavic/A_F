from typing import List, Optional
from pydantic import BaseModel, Field
from uuid import UUID
from datetime import datetime
from decimal import Decimal

class MilestoneBase(BaseModel):
    phase_index: int
    phase_weight_wi: Decimal
    disbursement_percentage_di: Decimal
    release_amount: Decimal
    status: str
    deadline: Optional[datetime] = None

class MilestoneOut(MilestoneBase):
    milestone_id: UUID
    
    class Config:
        from_attributes = True

class CampaignBase(BaseModel):
    title: str
    description: str
    funding_goal_f: Decimal = Field(..., alias="funding_goal")
    duration_d: int = Field(..., alias="duration_months")
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
    title: str
    description: str
    funding_goal_f: Decimal
    duration_d: int
    campaign_type_ct: str
    status: str
    category_c: Decimal
    num_phases_p: int
    alpha_value: Decimal
    total_contributions: Decimal
    total_released: Decimal
    created_at: datetime
    updated_at: datetime
    
    milestones: List[MilestoneOut] = []

    class Config:
        from_attributes = True
        populate_by_name = True
