from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID

from app.api.dependencies.deps import get_db, get_current_user
from app.schemas.campaign import CampaignCreate, CampaignOut, CampaignUpdate, MilestoneOut
from app.models.user import User
from app.models.campaign import Campaign
from app.services.campaign_service import CampaignService
from app.services.campaign_state_service import CampaignStateService
from app.schemas.campaign import CampaignProgress
from datetime import datetime

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

@router.get("/my-campaigns", response_model=List[CampaignOut])
def read_my_campaigns(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Retrieve campaigns created by the current user.
    """
    campaigns = db.query(Campaign).filter(Campaign.fundraiser_id == current_user.account_id).all()
    return campaigns

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

@router.post("/{campaign_id}/launch", response_model=CampaignOut)
def launch_campaign(
    campaign_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Launch a draft campaign.
    """
    campaign = db.query(Campaign).filter(Campaign.campaign_id == campaign_id).first()
    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")
    
    if str(campaign.fundraiser_id) != str(current_user.account_id):
        raise HTTPException(status_code=403, detail="Not authorized to launch this campaign")

    try:
        updated_campaign = CampaignStateService.start_campaign(db, campaign_id)
        return updated_campaign
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/{campaign_id}/timeline", response_model=List[MilestoneOut])
def get_campaign_timeline(
    campaign_id: UUID,
    db: Session = Depends(get_db)
) -> Any:
    """
    Get campaign timeline with milestones.
    """
    campaign = db.query(Campaign).filter(Campaign.campaign_id == campaign_id).first()
    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")
    
    # Simple list of milestones with statuses
    return campaign.milestones

@router.get("/{campaign_id}/progress", response_model=CampaignProgress)
def get_campaign_progress(
    campaign_id: UUID,
    db: Session = Depends(get_db)
) -> Any:
    """
    Get a summary of campaign progress for dashboard displays.
    """
    campaign = db.query(Campaign).filter(Campaign.campaign_id == campaign_id).first()
    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")
    
    funding_pct = (float(campaign.total_contributions) / float(campaign.funding_goal_f)) * 100 if campaign.funding_goal_f > 0 else 0
    
    # Calculate days remaining if active
    days_rem = None
    if campaign.status == 'active' and campaign.funding_end_date:
        delta = campaign.funding_end_date - datetime.utcnow()
        days_rem = max(0, delta.days)

    # Determine next action
    next_action = "N/A"
    if campaign.status == 'draft':
        next_action = "Launch Campaign"
    elif campaign.status == 'active':
        next_action = "Reach Funding Goal"
    elif campaign.status == 'funded':
        next_action = "Start Phases"
    elif campaign.status == 'in_phases':
        # More complex logic could check current milestone status
        next_action = f"Complete Milestone {campaign.current_milestone_number}"

    return {
        "status": campaign.status,
        "funding_percentage": funding_pct,
        "total_contributions": campaign.total_contributions,
        "funding_goal": campaign.funding_goal_f,
        "milestones_total": campaign.num_phases_p,
        "milestones_completed": campaign.milestones_approved_count,
        "current_milestone_number": campaign.current_milestone_number,
        "next_action_required": next_action,
        "days_remaining": days_rem
    }

@router.post("/{campaign_id}/cancel", response_model=CampaignOut)
def cancel_campaign(
    campaign_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Cancel a campaign (Only allowed for Draft/Pending Review).
    """
    campaign = db.query(Campaign).filter(Campaign.campaign_id == campaign_id).first()
    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")
    
    if str(campaign.fundraiser_id) != str(current_user.account_id):
        raise HTTPException(status_code=403, detail="Not authorized")
    
    if campaign.status not in ['draft', 'pending_review']:
        raise HTTPException(status_code=400, detail="Cannot cancel campaign in current status")
    
    # Using terminate for now as a catch-all for 'failed/cancelled'
    try:
        updated_campaign = CampaignStateService.terminate_campaign(db, campaign_id)
        return updated_campaign
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
