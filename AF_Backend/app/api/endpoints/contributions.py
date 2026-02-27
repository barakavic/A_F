from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api.dependencies.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.contribution import ContributionCreate, ContributionResponse, UserContributionOut, ContributorStats
from app.models.transaction import Contribution
from app.models.campaign import Campaign
from app.services.contribution_service import ContributionService
from sqlalchemy import func

router = APIRouter()

@router.get("/stats", response_model=ContributorStats)
def get_contributor_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Get portfolio stats for the current contributor.
    """
    if current_user.role != 'contributor':
        raise HTTPException(status_code=403, detail="Stats only available for contributors")

    # Aggregate total portfolio value
    total_value = db.query(func.sum(Contribution.amount))\
        .filter(Contribution.contributor_id == current_user.account_id, Contribution.status == 'completed')\
        .scalar() or 0

    # Count unique active campaigns invested in
    active_count = db.query(func.count(func.distinct(Contribution.campaign_id)))\
        .filter(Contribution.contributor_id == current_user.account_id, Contribution.status == 'completed')\
        .scalar() or 0

    return {
        "total_portfolio_value": total_value,
        "active_investments_count": active_count
    }

@router.post("/", response_model=ContributionResponse)
def create_contribution(
    contribution_in: ContributionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Pledge a contribution to a campaign.
    Only users with 'contributor' role can perform this action.
    """
    if current_user.role != 'contributor':
        raise HTTPException(
            status_code=403, 
            detail="Only contributors can pledge to campaigns"
        )
        
    try:
        result = ContributionService.create_contribution(
            db=db,
            campaign_id=contribution_in.campaign_id,
            contributor_id=current_user.account_id,
            amount=float(contribution_in.amount)
        )
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")

@router.get("/my-contributions", response_model=List[UserContributionOut])
def get_my_contributions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Get all contributions made by the current user.
    """
    contributions = db.query(Contribution).join(Campaign).filter(
        Contribution.contributor_id == current_user.account_id
    ).all()
    
    result = []
    for c in contributions:
        result.append({
            "contribution_id": c.contribution_id,
            "campaign_id": c.campaign_id,
            "campaign_title": c.campaign.title,
            "campaign_status": c.campaign.status,
            "amount": c.amount,
            "status": c.status,
            "created_at": c.created_at
        })
    
    return result
