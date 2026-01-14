from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID

from app.api.dependencies.deps import get_db, get_current_user
from app.schemas.campaign import CampaignCreate, CampaignOut, CampaignUpdate
from app.models.user import User
from app.models.campaign import Campaign
from app.services.campaign_service import CampaignService

router = APIRouter()

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
            funding_goal=float(campaign_in.funding_goal_f),
            duration_months=campaign_in.duration_d,
            campaign_type=campaign_in.campaign_type_ct
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

@router.get("/{campaign_id}", response_model=CampaignOut)
def read_campaign(
    campaign_id: UUID,
    db: Session = Depends(get_db)
) -> Any:
    """
    Get campaign by ID.
    """
    campaign = db.query(Campaign).filter(Campaign.campaign_id == campaign_id).first()
    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")
    return campaign
