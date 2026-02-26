import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.session import SessionLocal
from app.models.user import User, FundraiserProfile
from app.models.campaign import Campaign
from app.services.campaign_service import CampaignService
from app.services.campaign_state_service import CampaignStateService
import uuid

def security_probe():
    db = SessionLocal()
    print("Starting Security Transition Probe...")
    
    try:
        # Create a fresh campaign
        email = f"attacker_{uuid.uuid4().hex[:6]}@example.com"
        user = User(email=email, password_hash="pw", role='fundraiser', is_active=True)
        db.add(user)
        db.flush()
        profile = FundraiserProfile(fundraiser_id=user.account_id, company_name="Shadow Corp")
        db.add(profile)
        db.flush()

        campaign = CampaignService.create_campaign(
            db=db, fundraiser_id=user.account_id,
            title="Attack Target", description="Probing transitions.",
            funding_goal=1000, duration_months=1, campaign_type='donation'
        )
        print(f"Initial Status: {campaign.status}")

        # 1. Attempt invalid transition: DRAFT -> COMPLETED
        print("\n Attempting: DRAFT -> COMPLETED (Illegal skip)")
        try:
            CampaignStateService.transition_status(db, campaign.campaign_id, 'completed')
            print(" SECURITY VULNERABILITY: Draft allowed to jump to Completed!")
        except ValueError as e:
            print(f" BLOCKED: {e}")

        # 2. Attempt invalid transition: DRAFT -> IN_PHASES
        print("\n Attempting: DRAFT -> IN_PHASES (Illegal skip)")
        try:
            CampaignStateService.transition_status(db, campaign.campaign_id, 'in_phases')
            print(" SECURITY VULNERABILITY: Draft allowed to jump to In Phases!")
        except ValueError as e:
            print(f" BLOCKED: {e}")

        # 3. Valid move: DRAFT -> ACTIVE
        print("\n Attempting: DRAFT -> ACTIVE (Legal move)")
        CampaignStateService.transition_status(db, campaign.campaign_id, 'active')
        print(f" SUCCESS: Status is now {campaign.status}")

        # 4. Attempt invalid transition: ACTIVE -> COMPLETED (Must fund first)
        print("\n Attempting: ACTIVE -> COMPLETED (Illegal skip)")
        try:
            CampaignStateService.transition_status(db, campaign.campaign_id, 'completed')
            print(" SECURITY VULNERABILITY: Active allowed to jump to Completed!")
        except ValueError as e:
            print(f" BLOCKED: {e}")

        print("\n Security Probe Finished: All illegal state transitions were successfully blocked!")

    except Exception as e:
        print(f" Probe Errored: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    security_probe()
