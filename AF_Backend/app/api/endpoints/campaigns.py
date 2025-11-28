from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID

from app.api.dependencies.deps import get_db, get_current_user
from app.models.user import User
from app.models.campaign import Campaign
from app.services.campaign_service import CampaignService
from pydantic import BaseModel

router = APIRouter()

class CampaignCreate(BaseModel):
    title: str
    description: str
    funding_goal: float
    duration_months: int
    campaign_type: str = 'donation'

class CampaignOut(BaseModel):
    campaign_id: UUID
    title: str
    status: str
    funding_goal_f: float
    # Add other fields as needed
    
    class Config:
        from_attributes = True

@router.post("/", response_model=CampaignOut)
def create_campaign(
    campaign_in: CampaignCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Create new campaign.
    """
    if current_user.role != 'fundraiser':
        raise HTTPException(status_code=403, detail="Only fundraisers can create campaigns")
        
    try:
        campaign = CampaignService.create_campaign(
            db=db,
            fundraiser_id=current_user.account_id,
            title=campaign_in.title,
            description=campaign_in.description,
            funding_goal=campaign_in.funding_goal,
            duration_months=campaign_in.duration_months,
            campaign_type=campaign_in.campaign_type
        )
        return campaign
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/", response_model=List[CampaignOut])
def read_campaigns(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
) -> Any:
    """
    Retrieve campaigns.
    """
    campaigns = db.query(Campaign).offset(skip).limit(limit).all()
    return campaigns
