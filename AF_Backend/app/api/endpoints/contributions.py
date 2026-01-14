from typing import Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api.dependencies.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.contribution import ContributionCreate, ContributionResponse
from app.services.contribution_service import ContributionService

router = APIRouter()

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
