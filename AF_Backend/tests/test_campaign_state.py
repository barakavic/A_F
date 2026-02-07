import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.db.base_class import Base
from app.models.campaign import Campaign
from app.models.user import User, FundraiserProfile
from app.services.campaign_state_service import CampaignStateService
import uuid
import pytest

# Use an in-memory SQLite for testing logic if possible, 
# but models use GUID which might be tricky in SQLite.
# We'll try to connect to the actual test DB or just mock the session.

def test_transitions():
    from unittest.mock import MagicMock
    db = MagicMock()
    
    # Mock campaign
    campaign = Campaign(
        campaign_id=uuid.uuid4(),
        status='draft',
        duration_d=3
    )
    
    db.query().filter().first.return_value = campaign
    
    # Test 1: Draft -> Active (Launch)
    CampaignStateService.launch_campaign(db, campaign.campaign_id)
    assert campaign.status == 'active'
    assert campaign.launched_at is not None
    assert campaign.funding_start_date is not None
    
    # Test 2: Active -> Funded
    CampaignStateService.mark_as_funded(db, campaign.campaign_id)
    assert campaign.status == 'funded'
    assert campaign.funded_at is not None
    
    # Test 3: Funded -> In Phases
    CampaignStateService.start_phases(db, campaign.campaign_id)
    assert campaign.status == 'in_phases'
    assert campaign.phases_started_at is not None
    assert campaign.current_milestone_number == 1
    
    # Test 4: In Phases -> Completed
    CampaignStateService.complete_campaign(db, campaign.campaign_id)
    assert campaign.status == 'completed'
    assert campaign.completed_at is not None
    
    # Test 5: Invalid transition (Completed -> Active)
    try:
        CampaignStateService.transition_status(db, campaign.campaign_id, 'active')
        assert False, "Should have raised ValueError"
    except ValueError as e:
        assert "Invalid transition" in str(e)

if __name__ == "__main__":
    test_transitions()
    print("✅ All state transition tests passed!")
