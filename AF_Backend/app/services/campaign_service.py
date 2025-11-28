from sqlalchemy.orm import Session
from app.models.campaign import Campaign
from app.models.milestone import Milestone
from app.models.escrow import EscrowAccount
from app.models.user import FundraiserProfile
from app.services.algorithm_service import AlgorithmService
from datetime import datetime, timedelta
import uuid

class CampaignService:
    @staticmethod
    def create_campaign(
        db: Session,
        fundraiser_id: uuid.UUID,
        title: str,
        description: str,
        funding_goal: float,
        duration_months: int,
        campaign_type: str = 'donation'
    ) -> Campaign:
        """
        Create a new campaign and generate milestones based on algorithms.
        """
        # 1. Fetch Fundraiser Profile for Risk Calc
        profile = db.query(FundraiserProfile).filter(FundraiserProfile.fundraiser_id == fundraiser_id).first()
        if not profile:
            raise ValueError("Fundraiser profile not found")
            
        # 2. Calculate Algorithmic Parameters
        # Assuming we have access to user rating/history. For now using placeholders or profile data if available.
        # In a real scenario, we'd fetch these stats.
        # Placeholder values for FTI calculation:
        fti = AlgorithmService.calculate_fti(
            tenure_months=12, # TODO: Fetch real tenure
            successful_campaigns=1, # TODO: Fetch real stats
            high_value_projects=0,
            rating=4.5
        )
        
        # Risk Factor C
        # Using L1/L2 weights from profile if available, else defaults
        l1_risk = float(profile.industry_l1.l1_risk_weight) if profile.industry_l1 else 0.5
        l2_risk = float(profile.industry_l2.l2_risk_weight) if profile.industry_l2 else 0.5
        risk_c = AlgorithmService.calculate_risk_factor_c(l1_risk, l2_risk)
        
        # Alpha
        alpha = AlgorithmService.calculate_alpha(duration_months)
        
        # Phase Count P
        phase_count = AlgorithmService.calculate_phase_count(risk_c, funding_goal)
        
        # Remedial Reserve Rm
        reserve_rm = AlgorithmService.calculate_remedial_reserve(fti, duration_months)
        
        # 3. Create Campaign Record
        campaign = Campaign(
            fundraiser_id=fundraiser_id,
            title=title,
            description=description,
            funding_goal_f=funding_goal,
            duration_d=duration_months,
            campaign_type_ct=campaign_type,
            category_c=risk_c,
            num_phases_p=phase_count,
            alpha_value=alpha,
            remedial_reserve_rm=reserve_rm,
            status='draft'
        )
        db.add(campaign)
        db.flush() # Get ID
        
        # 4. Create Escrow Account
        escrow = EscrowAccount(campaign_id=campaign.campaign_id)
        db.add(escrow)
        
        # 5. Generate Milestones
        # Calculate weights
        weights = AlgorithmService.calculate_milestone_weights(phase_count, alpha)
        
        # Seeding phase duration (0.1 * D or 0.1 months)
        seeding_duration_months = max(0.1 * duration_months, 0.1)
        active_duration_months = duration_months - seeding_duration_months
        phase_duration_months = active_duration_months / phase_count
        
        # Start date (assuming campaign starts now for calculation, but actual start is when funding opens)
        # We'll set relative dates or leave null until activation.
        # For now, let's create them with pending status.
        
        for i, weight in enumerate(weights):
            phase_idx = i + 1
            
            # Disbursement Di = (1 - Rm) * Wi
            disbursement_pct = (1 - reserve_rm) * weight
            release_amt = float(funding_goal) * disbursement_pct
            
            milestone = Milestone(
                campaign_id=campaign.campaign_id,
                phase_index=phase_idx,
                phase_weight_wi=weight,
                disbursement_percentage_di=disbursement_pct,
                release_amount=release_amt,
                status='pending'
            )
            db.add(milestone)
            
        db.commit()
        db.refresh(campaign)
        return campaign
