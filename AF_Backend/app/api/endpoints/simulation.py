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
        # Find the milestone currently in focus 
        current_m = db.query(Milestone).filter(
            Milestone.campaign_id == id,
            Milestone.status.in_(['pending', 'active', 'voting_open', 'evidence_submitted', 'revision_submitted'])
        ).order_by(Milestone.milestone_number).first()

        if not current_m:
            return {"status": "info", "message": "No phases found. Campaign might be complete."}

        # STEP 1: If it's asleep (pending), wake it up
        if current_m.status == 'pending':
            MilestoneWorkflowService.activate_milestone(db, current_m.milestone_id)
            await emit_milestone_update(str(id), {"event": "milestone_activated", "milestone_number": current_m.milestone_number})
            return {
                "status": "success", 
                "message": f"Phase {current_m.milestone_number} is now ACTIVE. The fundraiser can now work on this phase."
            }

        # STEP 2: If it's active, submit simulated evidence
        if current_m.status == 'active':
            MilestoneWorkflowService.submit_evidence(
                db=db, 
                milestone_id=current_m.milestone_id,
                description="[SIMULATED] Infrastructure deployment complete. Mesh network nodes installed and tested for signal strength."
            )
            await emit_milestone_update(str(id), {"event": "evidence_submitted", "milestone_number": current_m.milestone_number})
            return {
                "status": "success", 
                "message": f"Evidence submitted for Phase {current_m.milestone_number}! Voting is now OPEN for contributors."
            }

        # STEP 3: If voting is open, perform the skip and tally
        if current_m.status == 'voting_open':
            # RUN THE CONSENSUS CALCULATION
            # This now automatically triggers fund release in VotingService
            MilestoneWorkflowService.tally_votes(db, current_m.milestone_id)
            db.refresh(current_m)
            
            if current_m.status in ['approved', 'released']:
                # The status 'released' means funds were released automatically
                await emit_milestone_update(str(id), {"event": "milestone_approved", "milestone_number": current_m.milestone_number})
                return {
                    "status": "success", 
                    "message": f"Consensus reached! Funds released for Phase {current_m.milestone_number}. Click again to activate the next phase."
                }
            else:
                return {
                    "status": "failed", 
                    "message": f"Consensus failed. Status: {current_m.status}. Did you cast enough 'YES' votes?"
                }

    return {"status": "no_action", "message": f"Current status is {campaign.status}. No time-skip available."}
