import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from unittest.mock import MagicMock
from app.models.milestone import Milestone
from app.models.campaign import Campaign
from app.models.escrow import EscrowAccount
from app.models.transaction import Contribution
from app.services.financial_workflow_service import FinancialWorkflowService
import uuid
import pytest
from decimal import Decimal

def test_release_milestone_funds():
    db = MagicMock()
    
    # Setup
    campaign_id = uuid.uuid4()
    milestone_id = uuid.uuid4()
    escrow_id = uuid.uuid4()
    
    campaign = Campaign(campaign_id=campaign_id, fundraiser_id=uuid.uuid4())
    milestone = Milestone(
        milestone_id=milestone_id,
        campaign_id=campaign_id,
        release_amount=50000,
        status='approved',
        campaign=campaign,
        milestone_number=1,
        funds_released_at=None
    )
    escrow = EscrowAccount(escrow_id=escrow_id, campaign_id=campaign_id, balance=100000)
    
    db.query().filter().first.side_effect = [milestone, escrow]
    
    # Execute
    result = FinancialWorkflowService.release_milestone_funds(db, milestone_id)
    
    # Verify
    assert result is True
    assert escrow.balance == 50000
    assert milestone.status == 'released'
    assert milestone.funds_released_at is not None
    db.add.assert_called()

def test_initiate_bulk_refunds():
    db = MagicMock()
    campaign_id = uuid.uuid4()
    
    campaign = Campaign(campaign_id=campaign_id, status='active')
    escrow = EscrowAccount(campaign_id=campaign_id, balance=60000)
    
    # Two contributors: A (40k), B (20k)
    contributor_a = uuid.uuid4()
    contributor_b = uuid.uuid4()
    
    contribution_a = Contribution(contributor_id=contributor_a, amount=40000, status='completed')
    contribution_b = Contribution(contributor_id=contributor_b, amount=20000, status='completed')
    
    # Use side_effect to return the correct objects based on the sequence of calls in the service
    # 1. db.query(Campaign).filter(...).first() -> campaign
    # 2. db.query(EscrowAccount).filter(...).first() -> escrow
    # 3. db.query(Contribution).filter(...).all() -> [contributions]
    db.query().filter().first.side_effect = [campaign, escrow]
    db.query().filter().all.return_value = [contribution_a, contribution_b]
    
    # Execute
    stats = FinancialWorkflowService.initiate_bulk_refunds(db, campaign_id)
    
    # Verify
    print(f"DEBUG: Campaign Status: {campaign.status}")
    assert stats["total_refunded"] == 60000
    assert stats["contributor_count"] == 2
    assert escrow.balance == 0
    assert campaign.status == 'failed'
    assert contribution_a.status == 'refunded'
    assert contribution_b.status == 'refunded'

if __name__ == "__main__":
    test_release_milestone_funds()
    test_initiate_bulk_refunds()
    print("✅ Financial Workflow tests passed!")
