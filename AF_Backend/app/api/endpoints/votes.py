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
from app.services.voting_service import VotingService
from app.services.escrow_service import EscrowService

router = APIRouter()

class MilestonePending(BaseModel):
    milestone_id: UUID
    milestone_number: int
    description: Optional[str] = None
    campaign_title: str
    campaign_id: UUID
    voting_end_date: datetime
    release_amount: float
    evidence_description: Optional[str] = None
    evidence_image_urls: List[str] = []

    class Config:
        from_attributes = True

class PendingVoteOut(BaseModel):
    milestones: List[MilestonePending]

class VoteRequest(BaseModel):
    campaign_id: UUID
    milestone_id: UUID
    vote: str # 'YES' or 'NO'
    signature: str
    nonce: str

class WaiverRequest(BaseModel):
    milestone_id: UUID
    signature: str

@router.post("/generate-tokens/{campaign_id}")
def generate_vote_token(
    campaign_id: UUID,
    db: Session = Depends(get_db)
) -> Any:
    """
    Generate vote tokens for all existing contributors of a campaign.
    """
    result = VotingService.generate_vote_tokens(db, campaign_id)
    return {"status": "success", "tokens_created": result}

@router.post("/submit", status_code=201)
async def submit_vote(
    request: VoteRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Submit a vote with signature verification.
    """
    try:
        vote = VotingService.submit_vote(
            db=db,
            contributor_id=current_user.account_id,
            campaign_id=request.campaign_id,
            milestone_id=request.milestone_id,
            vote_value=request.vote,
            signature=request.signature,
            nonce=request.nonce
        )
        return {"status": "success", "vote_id": vote.id}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/waive")
def waive_votes(
    request: WaiverRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Waive voting right (automatic YES).
    """
    try:
        VotingService.waive_vote(
            db=db,
            contributor_id=current_user.account_id,
            milestone_id=request.milestone_id,
            signature=request.signature
        )
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/tally/{milestone_id}")
def tally_votes(
    milestone_id: UUID,
    db: Session = Depends(get_db),
) -> Any:
    """
    Tally votes for a milestone.
    """
    result = VotingService.tally_votes(db, milestone_id)
            
    return {
        "status": "success",
        "milestone_id": milestone_id,
        "outcome": result.outcome,
        "yes_percentage": float(result.yes_percentage),
        "total_yes": result.total_yes,
        "total_no": result.total_no
    }

@router.get("/status/{milestone_id}")
def get_vote_status(
    milestone_id: UUID,
    db: Session = Depends(get_db),
) -> Any:
    """
    Get live vote counts for a milestone (read-only, does not tally or finalize).
    For fundraiser visibility during voting_open phase.
    """
    milestone = db.query(Milestone).filter(Milestone.milestone_id == milestone_id).first()
    if not milestone:
        print(f"DEBUG: Milestone {milestone_id} NOT FOUND")
        raise HTTPException(status_code=404, detail="Milestone not found")

    votes = db.query(VoteSubmission).filter(VoteSubmission.milestone_id == milestone_id).all()
    total_voters = db.query(VoteToken).filter(VoteToken.campaign_id == milestone.campaign_id).count()
    
    print(f"DEBUG: Status for M:{milestone_id} - Votes:{len(votes)}, Tokens:{total_voters}")
    yes_votes = sum(1 for v in votes if str(v.vote_value).lower() == 'yes' or v.is_waived is True)
    no_votes = sum(1 for v in votes if str(v.vote_value).lower() == 'no' and not v.is_waived)
    votes_cast = len(votes)
    yes_pct = 0.0
    if votes_cast > 0:
        yes_pct = round(float(yes_votes) / votes_cast * 100, 1)

    return {
        "milestone_id": milestone_id,
        "milestone_status": milestone.status,
        "total_eligible_voters": total_voters,
        "votes_cast": votes_cast,
        "yes_votes": yes_votes,
        "no_votes": no_votes,
        "yes_percentage": yes_pct,
        "threshold": 75.0,
        "voting_end_date": milestone.voting_end_date,
    }

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
    
    tokens = db.query(VoteToken).filter(VoteToken.contributor_id == current_user.account_id).all()
    campaign_ids = [t.campaign_id for t in tokens]
    
    if not campaign_ids:
        return {"milestones": []}
    
    pending_milestones = db.query(Milestone).filter(
        Milestone.campaign_id.in_(campaign_ids),
        Milestone.status == 'voting_open'
    ).all()
    
    result = []
    for m in pending_milestones:
        # Check if user already voted
        already_voted = db.query(VoteSubmission).filter(
            VoteSubmission.contributor_id == current_user.account_id,
            VoteSubmission.milestone_id == m.milestone_id
        ).first()
        
        if not already_voted:
            evidence_desc = None
            evidence_images = []
            if m.evidence:
                latest_evidence = sorted(m.evidence, key=lambda x: x.uploaded_at, reverse=True)[0]
                evidence_desc = latest_evidence.description
                # Optionally take all evidence images or just the latest one's
                evidence_images = [e.file_path for e in m.evidence]

            result.append({
                "milestone_id": m.milestone_id,
                "milestone_number": m.milestone_number,
                "description": m.description,
                "campaign_title": m.campaign.title,
                "campaign_id": m.campaign_id,
                "voting_end_date": m.voting_end_date,
                "release_amount": float(m.release_amount),
                "evidence_description": evidence_desc,
                "evidence_image_urls": evidence_images
            })
            
    return {"milestones": result}
