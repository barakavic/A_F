import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.session import SessionLocal
from app.models.user import User, FundraiserProfile
from app.models.campaign import Campaign
from app.models.milestone import Milestone
from app.models.vote import VoteSubmission
from app.services.campaign_service import CampaignService
from app.services.campaign_state_service import CampaignStateService
from app.services.milestone_workflow_service import MilestoneWorkflowService
from app.services.financial_workflow_service import FinancialWorkflowService
from datetime import datetime, timedelta
import uuid

def simulate():
    db = SessionLocal()
    print("🚀 Starting Campaign Lifecycle Simulation...")

    try:
        # 1. Create Fundraiser
        email = f"fundraiser_{uuid.uuid4().hex[:6]}@example.com"
        user = User(
            email=email,
            password_hash="hashed_password",
            role='fundraiser',
            is_active=True
        )
        db.add(user)
        db.flush()
        
        profile = FundraiserProfile(
            fundraiser_id=user.account_id,
            company_name="Simulated Tech",
        )
        db.add(profile)
        db.flush()
        
        # 2. Create Campaign (Day 1: Creation)
        print("\n--- Phase 1: Creation & Seeding Setup ---")
        goal = 1000000.0 # KES 1M
        duration = 3 # 3 Months
        campaign = CampaignService.create_campaign(
            db=db,
            fundraiser_id=user.account_id,
            title="Clean Water for Kitui",
            description="Providing solar-powered water pumps.",
            funding_goal=goal,
            duration_months=duration,
            campaign_type='donation'
        )
        
        print(f"✅ Campaign Created: {campaign.title}")
        print(f"   Status: {campaign.status}")
        print(f"   Total Phases: {campaign.num_phases_p}")
        
        # Show Seeding Phase / Milestones
        for m in campaign.milestones:
            print(f"   Milestone {m.milestone_number}: Weight={m.phase_weight_wi}, Deadline={m.target_deadline}, Release=KES {m.release_amount}")

        # 3. Launch Campaign (Phase 2: Funding)
        print("\n--- Phase 2: Funding Period ---")
        CampaignStateService.transition_status(db, campaign.campaign_id, 'active')
        print(f"✅ Campaign Launched. Status: {campaign.status}")
        print(f"   Funding End Date: {campaign.funding_end_date}")

        # 4. Success: Reach Funding Goal
        campaign.total_contributions = goal
        db.add(campaign)
        db.flush()
        
        # ACTUALLY FUND THE ESCROW
        from app.models.escrow import EscrowAccount
        escrow = db.query(EscrowAccount).filter(EscrowAccount.campaign_id == campaign.campaign_id).first()
        escrow.balance = goal
        db.add(escrow)
        
        CampaignStateService.transition_status(db, campaign.campaign_id, 'funded')
        print(f"✅ Funding Goal Reached! Status: {campaign.status}")

        # 5. Start Execution Phase
        print("\n--- Phase 3: Milestone Execution ---")
        CampaignStateService.transition_status(db, campaign.campaign_id, 'in_phases')
        print(f"✅ Execution Started. Status: {campaign.status}")

        # 6. Loop through Milestones
        for m in campaign.milestones:
            print(f"\n▶ Working on Milestone {m.milestone_number}...")
            
            # Step A: Activate
            MilestoneWorkflowService.activate_milestone(db, m.milestone_id)
            print(f"   Status: {m.status} (Activated at {m.activated_at})")
            
            # Step B: Submit Evidence
            MilestoneWorkflowService.submit_evidence(
                db=db,
                milestone_id=m.milestone_id,
                description=f"Work complete for phase {m.milestone_number}"
            )
            print(f"   Status: {m.status} (Evidence submitted)")
            
            # Step C: Start Voting
            MilestoneWorkflowService.start_voting(db, m.milestone_id)
            print(f"   Status: {m.status} (Voting until {m.voting_end_date})")
            
            # Step D: Simulate Consensus (Mock YES votes)
            # Create a mock contributor to vote
            vote_user = User(email=f"voter_{uuid.uuid4().hex[:6]}@example.com", password_hash="pw", role='contributor')
            db.add(vote_user)
            db.flush()
            vote = VoteSubmission(
                milestone_id=m.milestone_id,
                contributor_id=vote_user.account_id,
                vote_value='yes',
                signature="signed_hex"
            )
            db.add(vote)
            db.flush()
            
            # Step E: Tally & Approve
            MilestoneWorkflowService.tally_votes(db, m.milestone_id)
            print(f"   Status: {m.status} (Tally: 100% YES)")
            
            # Step F: Release Funds
            FinancialWorkflowService.release_milestone_funds(db, m.milestone_id)
            print(f"   Status: {m.status} (Funds Released!)")
            
            # Auto-transition to finish if last milestone
            if m.milestone_number == campaign.num_phases_p:
                CampaignStateService.complete_campaign(db, campaign.campaign_id)

        print("\n--- Phase 4: Completion ---")
        print(f"✅ Final Campaign Status: {campaign.status}")
        print(f"   Total Milestones Approved: {campaign.milestones_approved_count}")
        print(f"   Completed At: {campaign.completed_at}")
        
    except Exception as e:
        print(f"❌ Simulation Failed: {str(e)}")
        import traceback
        traceback.print_exc()
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    simulate()
