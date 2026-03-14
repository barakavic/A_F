from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.api.dependencies.deps import get_db
from app.models.campaign import Campaign
from app.models.milestone import Milestone
from app.services.milestone_workflow_service import MilestoneWorkflowService
from app.services.escrow_service import EscrowService
from app.core.socket_manager import sio
import uuid
from datetime import datetime

router = APIRouter()

async def emit_milestone_update(campaign_id: str, data: dict):
    """Notify clients of a state change via Socket.io"""
    await sio.emit("milestone_update", data, room=campaign_id)
    await sio.emit("milestone_update", data)

@router.post("/{id}/advance")
async def advance_campaign_simulation(
    id: uuid.UUID,
    db: Session = Depends(get_db)
):
    """
    STRICT TIME SKIPPER: 
    Bypasses the 7-day voting window and triggers an immediate tally.
    Requires the user to have manually submitted evidence and cast manual votes first.
    """
    campaign = db.query(Campaign).filter(Campaign.campaign_id == id).first()
    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")

    if campaign.status == 'active':
        return {
            "status": "manual_action", 
            "message": "Campaign is in Fundraising. Please contribute manually from contributor accounts."
        }

    if campaign.status == 'in_phases':
        # Find the milestone currently in the voting period
        current_m = db.query(Milestone).filter(
            Milestone.campaign_id == id,
            Milestone.status.in_(['active', 'voting_open', 'evidence_submitted'])
        ).order_by(Milestone.milestone_number).first()

        if not current_m:
            return {"status": "info", "message": "No active phase found. Please ensure the project is proceeding correctly."}

        if current_m.status == 'active':
            return {
                "status": "manual_action", 
                "message": f"Phase {current_m.milestone_number} is ACTIVE. Please submit evidence manually as the fundraiser."
            }

        if current_m.status == 'voting_open':
            # RUN THE CONSENSUS CALCULATION (Handled manually by the user up to this point)
            MilestoneWorkflowService.tally_votes(db, current_m.milestone_id)
            
            db.refresh(current_m)
            
            if current_m.status == 'approved':
                # Release the funds held in escrow
                EscrowService.release_milestone_funds(db, current_m.milestone_id)
                
                # Automatically wake up the next phase
                next_m = db.query(Milestone).filter(
                    Milestone.campaign_id == id,
                    Milestone.milestone_number == current_m.milestone_number + 1
                ).first()
                
                if next_m:
                    MilestoneWorkflowService.activate_milestone(db, next_m.milestone_id)
                    next_status = f"Phase {next_m.milestone_number} is now active."
                else:
                    from app.services.campaign_state_service import CampaignStateService
                    CampaignStateService.complete_campaign(db, id)
                    next_status = "Campaign completed!"

                await emit_milestone_update(str(id), {"event": "milestone_approved"})
                return {
                    "status": "success", 
                    "message": f"Consensus reached! Funds released. {next_status}"
                }
            else:
                return {
                    "status": "failed", 
                    "message": f"Consensus failed or Quorum not met. Current Status: {current_m.status}. Did you cast enough 'YES' votes manually?"
                }

    return {"status": "no_action", "message": f"Current status is {campaign.status}. No time-skip available."}
