from typing import Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID
from pydantic import BaseModel

from app.api.dependencies.deps import get_db, get_current_user
from app.models.user import User
from app.services.voting_service import VotingService
from app.services.escrow_service import EscrowService

router = APIRouter()

class VoteTokenOut(BaseModel):
    token_hash: str
    
    class Config:
        from_attributes = True

class VoteSubmit(BaseModel):
    milestone_id: UUID
    vote_value: str # 'yes' or 'no'
    signature: str
    nonce: str

class VoteWaive(BaseModel):
    campaign_id: UUID
    signature: str
    nonce: str

@router.post("/token/{campaign_id}", response_model=VoteTokenOut)
def generate_vote_token(
    campaign_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Generate a voting token for a campaign.
    """
    if current_user.role != 'contributor':
        raise HTTPException(status_code=403, detail="Only contributors can vote")
        
    # TODO: Check if user actually contributed to this campaign
    
    try:
        token = VotingService.generate_vote_token(db, campaign_id, current_user.account_id)
        return token
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/submit")
def submit_vote(
    vote_in: VoteSubmit,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Submit a vote.
    """
    if current_user.role != 'contributor':
        raise HTTPException(status_code=403, detail="Only contributors can vote")
        
    try:
        vote = VotingService.submit_vote(
            db=db,
            milestone_id=vote_in.milestone_id,
            contributor_id=current_user.account_id,
            vote_value=vote_in.vote_value,
            signature=vote_in.signature,
            nonce=vote_in.nonce
        )
        return {"status": "success", "vote_id": vote.vote_id}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/waive")
def waive_votes(
    waive_in: VoteWaive,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Waive all future votes for a campaign.
    """
    if current_user.role != 'contributor':
        raise HTTPException(status_code=403, detail="Only contributors can waive votes")
        
    try:
        count = VotingService.waive_all_votes(
            db=db,
            campaign_id=waive_in.campaign_id,
            contributor_id=current_user.account_id,
            signature=waive_in.signature,
            nonce=waive_in.nonce
        )
        return {"status": "success", "waived_milestones": count}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/tally/{milestone_id}")
def tally_votes(
    milestone_id: UUID,
    db: Session = Depends(get_db),
    # current_user: User = Depends(get_current_user) # Maybe restrict to admin/system
) -> Any:
    """
    Tally votes for a milestone.
    """
    result = VotingService.tally_votes(db, milestone_id)
    
    # If approved, release funds
    if result.outcome == 'approved':
        try:
            EscrowService.release_milestone_funds(db, milestone_id)
        except Exception as e:
            # We don't want to fail the tally if release fails (e.g. already released)
            # But in a real app, we'd log this or handle it more robustly
            print(f"Fund release failed for milestone {milestone_id}: {str(e)}")
            
    return result
