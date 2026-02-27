from pydantic import BaseModel, Field
from uuid import UUID
from datetime import datetime
from decimal import Decimal
from typing import Optional

class ContributionBase(BaseModel):
    campaign_id: UUID
    amount: Decimal = Field(..., gt=0)

class ContributionCreate(ContributionBase):
    pass

class ContributionOut(BaseModel):
    contribution_id: UUID
    campaign_id: UUID
    contributor_id: UUID
    amount: Decimal
    status: str
    created_at: datetime

    class Config:
        from_attributes = True

class ContributionResponse(BaseModel):
    contribution: ContributionOut
    campaign_total_raised: Decimal
    escrow_balance: Decimal
    vote_token_id: Optional[UUID] = None

class UserContributionOut(BaseModel):
    contribution_id: UUID
    campaign_id: UUID
    campaign_title: str
    campaign_status: str
    amount: Decimal
    status: str
    created_at: datetime

    class Config:
        from_attributes = True

class ContributorStats(BaseModel):
    total_portfolio_value: Decimal
    active_investments_count: int
