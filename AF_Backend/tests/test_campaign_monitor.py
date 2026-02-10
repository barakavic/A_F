import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from unittest.mock import MagicMock, patch
from datetime import datetime, timedelta
from app.models.campaign import Campaign
from app.models.milestone import Milestone
from app.tasks.campaign_monitor import check_funding_deadlines, check_voting_deadlines
import uuid

def test_check_funding_deadlines():
    db = MagicMock()
    now = datetime.utcnow()
    past = now - timedelta(days=1)
    
    # 1. Successful Campaign (reached goal)
    camp_success = Campaign(
        campaign_id=uuid.uuid4(),
        status='active',
        funding_end_date=past,
        total_contributions=1000,
        funding_goal_f=1000
    )
    
    # 2. Failed Campaign (missed goal)
    camp_fail = Campaign(
        campaign_id=uuid.uuid4(),
        status='active',
        funding_end_date=past,
        total_contributions=500,
        funding_goal_f=1000
    )
    
    db.query().filter().all.return_value = [camp_success, camp_fail]
    
    with patch('app.services.campaign_state_service.CampaignStateService.mark_as_funded') as mock_funded, \
         patch('app.services.campaign_state_service.CampaignStateService.terminate_campaign') as mock_terminate, \
         patch('app.services.financial_workflow_service.FinancialWorkflowService.initiate_bulk_refunds') as mock_refund:
        
        check_funding_deadlines(db)
        
        mock_funded.assert_called_once()
        mock_terminate.assert_called_once()
        mock_refund.assert_called_once()

def test_check_voting_deadlines():
    db = MagicMock()
    now = datetime.utcnow()
    past = now - timedelta(days=1)
    
    # Expired Milestone
    milestone = Milestone(
        milestone_id=uuid.uuid4(),
        status='voting_open',
        voting_end_date=past,
        milestone_number=1,
        campaign=Campaign(campaign_id=uuid.uuid4(), num_phases_p=2)
    )
    
    db.query().filter().all.return_value = [milestone]
    
    with patch('app.services.milestone_workflow_service.MilestoneWorkflowService.tally_votes') as mock_tally:
        # Simulate approval
        def side_effect(db_sess, m_id):
            milestone.status = 'approved'
        mock_tally.side_effect = side_effect
        
        with patch('app.services.financial_workflow_service.FinancialWorkflowService.release_milestone_funds') as mock_release:
            check_voting_deadlines(db)
            mock_tally.assert_called_once()
            mock_release.assert_called_once()

if __name__ == "__main__":
    test_check_funding_deadlines()
    test_check_voting_deadlines()
    print("✅ Campaign Monitor task tests passed!")
