import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from unittest.mock import MagicMock
from app.models.milestone import Milestone
from app.models.campaign import Campaign
from app.models.vote import VoteSubmission
from app.services.milestone_workflow_service import MilestoneWorkflowService
import uuid
import pytest

def test_milestone_workflow():
    db = MagicMock()
    
    # 1. Setup Mock Campaign and Milestone
    campaign = Campaign(
        campaign_id=uuid.uuid4(), 
        status='in_phases', 
        current_milestone_number=0,
        milestones_approved_count=0,
        milestones_rejected_count=0
    )
    milestone = Milestone(
        milestone_id=uuid.uuid4(),
        campaign_id=campaign.campaign_id,
        milestone_number=1,
        status='pending',
        revision_count=0,
        campaign=campaign
    )
    
    db.query().filter().first.return_value = milestone
    
    # 2. Test Activation
    MilestoneWorkflowService.activate_milestone(db, milestone.milestone_id)
    assert milestone.status == 'active'
    assert campaign.current_milestone_number == 1
    
    # 3. Test Evidence Submission
    MilestoneWorkflowService.submit_evidence(db, milestone.milestone_id, "Work done!")
    assert milestone.status == 'evidence_submitted'
    assert milestone.evidence_submitted_at is not None
    
    # 4. Test Start Voting
    MilestoneWorkflowService.start_voting(db, milestone.milestone_id)
    assert milestone.status == 'voting_open'
    assert milestone.voting_end_date is not None
    
    # 5. Test Tallying (Mocking votes)
    # Mock YES vote
    vote1 = VoteSubmission(vote_value='yes', is_waived=False)
    vote2 = VoteSubmission(vote_value='no', is_waived=False)
    vote3 = VoteSubmission(vote_value='yes', is_waived=True) # Counts as YES
    
    db.query().filter().all.return_value = [vote1, vote2, vote3] # 2/3 = 66% (Fails 75%)
    
    MilestoneWorkflowService.tally_votes(db, milestone.milestone_id)
    assert milestone.status == 'rejected'
    
    # 6. Test Revision and Passing
    milestone.status = 'rejected' # Reset for second attempt
    MilestoneWorkflowService.submit_evidence(db, milestone.milestone_id, "Fixed the issues")
    assert milestone.status == 'revision_submitted'
    assert milestone.revision_count == 1
    
    # Mock Votes where 75% quorum is met
    vote_pass_1 = VoteSubmission(vote_value='yes', is_waived=False)
    vote_pass_2 = VoteSubmission(vote_value='yes', is_waived=False)
    vote_pass_3 = VoteSubmission(vote_value='yes', is_waived=False)
    db.query().filter().all.return_value = [vote_pass_1, vote_pass_2, vote_pass_3] # 100%
    
    MilestoneWorkflowService.tally_votes(db, milestone.milestone_id)
    assert milestone.status == 'approved'
    assert campaign.milestones_approved_count == 1

if __name__ == "__main__":
    test_milestone_workflow()
    print("✅ Milestone Workflow tests passed!")
