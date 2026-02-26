import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.session import SessionLocal
from app.models.user import User, FundraiserProfile
from app.models.campaign import Campaign
from app.models.milestone import Milestone
from app.models.vote import VoteSubmission
from app.models.transaction import Contribution
from app.models.escrow import EscrowAccount
from app.services.campaign_service import CampaignService
from app.services.campaign_state_service import CampaignStateService
from app.services.milestone_workflow_service import MilestoneWorkflowService
from app.services.financial_workflow_service import FinancialWorkflowService
from app.services.contribution_service import ContributionService
from decimal import Decimal
import uuid

def simulate_failure():
    db = SessionLocal()
    print("🧨 Starting Failure & Refund Simulation...")

    try:
        # 1. Create Fundraiser
        email = f"fundraiser_{uuid.uuid4().hex[:6]}@example.com"
        user = User(email=email, password_hash="pw", role='fundraiser', is_active=True)
        db.add(user)
        db.flush()
        
        # Add fundraiser profile (required by CampaignService)
        profile = FundraiserProfile(fundraiser_id=user.account_id, company_name="Test Corp")
        db.add(profile)
        db.flush()
        
        # 2. Create Campaign
        goal = 200000.0 
        campaign = CampaignService.create_campaign(
            db=db, fundraiser_id=user.account_id,
            title="Clean Energy Fail Test", description="Testing refund process.",
            funding_goal=goal, duration_months=3, campaign_type='donation'
        )
        print(f"Campaign Created: {campaign.title}")
        
        # 3. Launch
        CampaignStateService.transition_status(db, campaign.campaign_id, 'active')
        
        # 4. Fund it with two contributors
        print("\n--- Phase 2: Funding (Contributor A & B) ---")
        contributor_a = User(email=f"a_{uuid.uuid4().hex[:4]}@test.com", password_hash="pw", role='contributor')
        contributor_b = User(email=f"b_{uuid.uuid4().hex[:4]}@test.com", password_hash="pw", role='contributor')
        db.add_all([contributor_a, contributor_b])
        db.flush()

        # Contribute via Service
        ContributionService.create_contribution(db, campaign.campaign_id, contributor_a.account_id, 150000.0)
        ContributionService.create_contribution(db, campaign.campaign_id, contributor_b.account_id, 50000.0)
        
        print(f"Funded KES {campaign.total_contributions}. Status: {campaign.status}")
        
        # Transition to funded and in_phases
        CampaignStateService.transition_status(db, campaign.campaign_id, 'funded')
        CampaignStateService.transition_status(db, campaign.campaign_id, 'in_phases')
        print(f"Execution Phase Started.")

        # 5. Milestone 1 - Failure
        m1 = campaign.milestones[0]
        print(f"\n▶ Processing Milestone {m1.milestone_number} (Simulation: REJECTION)")
        
        MilestoneWorkflowService.activate_milestone(db, m1.milestone_id)
        MilestoneWorkflowService.submit_evidence(db, m1.milestone_id, "Attempted work but failed quality check.")
        MilestoneWorkflowService.start_voting(db, m1.milestone_id)

        # Cast NO votes
        vote = VoteSubmission(
            milestone_id=m1.milestone_id,
            contributor_id=contributor_a.account_id,
            vote_value='no',
            signature="negative_signed"
        )
        db.add(vote)
        db.commit()

        # Tally Votes
        result = MilestoneWorkflowService.tally_votes(db, m1.milestone_id)
        print(f"Milestone Status: {result.status}")

        if result.status == 'rejected':
            print("\n Milestone Rejected! Triggering Bulk Refunds...")
            
            # 6. Execute Bulk Refund
            refund_data = FinancialWorkflowService.initiate_bulk_refunds(
                db, campaign.campaign_id, reason="Milestone 1 rejected by consensus."
            )
            
            print(f"Refund Status:")
            print(f"Total Refunded: KES {refund_data['total_refunded']}")
            print(f"Contributors Impacted: {refund_data['contributor_count']}")
            
            # Verify Escrow
            escrow = db.query(EscrowAccount).filter(EscrowAccount.campaign_id == campaign.campaign_id).first()
            print(f"Final Escrow Balance: KES {escrow.balance}")
            print(f"Final Campaign Status: {campaign.status}")
            
            # Check individual contribution status
            contribs = db.query(Contribution).filter(Contribution.campaign_id == campaign.campaign_id).all()
            for c in contribs:
                print(f"Contributor {c.contributor_id}: {c.status}")

    except Exception as e:
        print(f"Simulation Failed: {str(e)}")
        import traceback
        traceback.print_exc()
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    simulate_failure()
