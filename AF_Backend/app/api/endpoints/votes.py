from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID
from pydantic import BaseModel
from datetime import datetime

from app.api.dependencies.deps import get_db, get_current_user
from app.models.user import User
from app.models.vote import VoteSubmission, VoteToken
from app.models.milestone import Milestone
from app.models.milestone_evidence import MilestoneEvidence
from app.models.campaign import Campaign
from app.services.voting_service import VotingService
from app.services.escrow_service import EscrowService

router = APIRouter()

class MilestonePending(BaseModel):
    milestone_id: UUID
    milestone_number: int
    description: str
    campaign_title: str
    campaign_id: UUID
    voting_end_date: datetime
    release_amount: float
    evidence_description: Optional[str] = None

    class Config:
        from_attributes = True

class PendingVoteOut(BaseModel):
    milestones: List[MilestonePending]

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
@router.get("/pending", response_model=PendingVoteOut)
def get_pending_votes(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Get all milestones awaiting vote for the current contributor.
    """
    if current_user.role != 'contributor':
        raise HTTPException(status_code=403, detail="Only contributors can view pending votes")
    
    # 1. Find all campaigns this user has a vote token for
    tokens = db.query(VoteToken).filter(VoteToken.contributor_id == current_user.account_id).all()
    campaign_ids = [t.campaign_id for t in tokens]
    
    if not campaign_ids:
        return {"milestones": []}
    
    # 2. Find all 'voting_open' milestones for these campaigns
    pending_milestones = db.query(Milestone).filter(
        Milestone.campaign_id.in_(campaign_ids),
        Milestone.status == 'voting_open'
    ).all()
    
    # 3. Filter out milestones already voted on by this user
    already_voted_ids = db.query(VoteSubmission.milestone_id).filter(
        VoteSubmission.milestone_id.in_([m.milestone_id for m in pending_milestones]),
        VoteSubmission.contributor_id == current_user.account_id
    ).all()
    already_voted_ids = [v[0] for v in already_voted_ids]
    
    result = []
    for m in pending_milestones:
        if m.milestone_id not in already_voted_ids:
            # Get latest evidence description
            latest_evidence = db.query(MilestoneEvidence).filter(
                MilestoneEvidence.milestone_id == m.milestone_id
            ).order_by(MilestoneEvidence.uploaded_at.desc()).first()
            
            # Extract description from metadata_json if it exists
            evidence_desc = None
            if latest_evidence and latest_evidence.metadata_json:
                evidence_desc = latest_evidence.metadata_json.get("description")

            result.append({
                "milestone_id": m.milestone_id,
                "milestone_number": m.milestone_number,
                "description": m.description,
                "campaign_title": m.campaign.title,
                "campaign_id": m.campaign_id,
                "voting_end_date": m.voting_end_date,
                "release_amount": float(m.release_amount),
                "evidence_description": evidence_desc
            })
            
    return {"milestones": result}
