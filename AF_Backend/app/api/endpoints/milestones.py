from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from uuid import UUID
import os

from app.api.dependencies.deps import get_db, get_current_user
from app.models.user import User
from app.models.milestone import Milestone
from app.models.milestone_evidence import MilestoneEvidence
from app.services.milestone_workflow_service import MilestoneWorkflowService
from app.schemas.campaign import MilestoneOut

router = APIRouter()

# Directory for evidence uploads
UPLOAD_DIR = "uploads/evidence"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.post("/{milestone_id}/submit-evidence", response_model=MilestoneOut)
async def submit_evidence(
    milestone_id: UUID,
    description: str = Form(...),
    file: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Fundraiser submits evidence for a milestone.
    """
    milestone = db.query(Milestone).filter(Milestone.milestone_id == milestone_id).first()
    if not milestone:
        raise HTTPException(status_code=404, detail="Milestone not found")
    
    if str(milestone.campaign.fundraiser_id) != str(current_user.account_id):
        raise HTTPException(status_code=403, detail="Not authorized")
    
    file_path = None
    file_type = None
    
    if file:
        file_extension = os.path.splitext(file.filename)[1]
        file_name = f"{milestone_id}_{current_user.account_id}{file_extension}"
        file_path = os.path.join(UPLOAD_DIR, file_name)
        
        with open(file_path, "wb") as buffer:
            content = await file.read()
            buffer.write(content)
        
        file_type = file.content_type

    try:
        updated_milestone = MilestoneWorkflowService.submit_evidence(
            db=db,
            milestone_id=milestone_id,
            description=description,
            file_path=file_path,
            file_type=file_type
        )
        return updated_milestone
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/{milestone_id}/start-voting", response_model=MilestoneOut)
def start_voting(
    milestone_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Fundraiser starts the voting period for a milestone.
    """
    milestone = db.query(Milestone).filter(Milestone.milestone_id == milestone_id).first()
    if not milestone:
        raise HTTPException(status_code=404, detail="Milestone not found")
    
    if str(milestone.campaign.fundraiser_id) != str(current_user.account_id):
        raise HTTPException(status_code=403, detail="Not authorized")
    
    try:
        updated_milestone = MilestoneWorkflowService.start_voting(db, milestone_id)
        return updated_milestone
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/{milestone_id}/vote-status")
def get_vote_status(
    milestone_id: UUID,
    db: Session = Depends(get_db)
) -> Any:
    """
    Get current vote tally for a milestone.
    """
    milestone = db.query(Milestone).filter(Milestone.milestone_id == milestone_id).first()
    if not milestone:
        raise HTTPException(status_code=404, detail="Milestone not found")
    
    if not milestone.vote_result:
         # If voting hasn't happened or finished yet
         from app.models.vote import VoteSubmission
         votes = db.query(VoteSubmission).filter(VoteSubmission.milestone_id == milestone_id).all()
         yes = len([v for v in votes if v.vote_value == 'yes' or v.is_waived])
         no = len(votes) - yes
         return {
             "status": milestone.status,
             "total_votes": len(votes),
             "yes": yes,
             "no": no,
             "quorum_reached": False # Logic would involve checking total tokens
         }
    
    return {
        "status": milestone.status,
        "total_yes": milestone.vote_result.total_yes,
        "total_no": milestone.vote_result.total_no,
        "yes_percentage": milestone.vote_result.yes_percentage,
        "outcome": milestone.vote_result.outcome
    }

@router.get("/{milestone_id}/evidence", response_model=List[Any])
def get_milestone_evidence(
    milestone_id: UUID,
    db: Session = Depends(get_db)
) -> Any:
    """
    Get all evidence submitted for a milestone.
    """
    milestone = db.query(Milestone).filter(Milestone.milestone_id == milestone_id).first()
    if not milestone:
        raise HTTPException(status_code=404, detail="Milestone not found")
    
    return milestone.evidence
