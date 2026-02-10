from sqlalchemy.orm import Session
from datetime import datetime
from app.models.campaign import Campaign
from app.models.milestone import Milestone
from app.services.campaign_state_service import CampaignStateService
from app.services.milestone_workflow_service import MilestoneWorkflowService
from app.services.financial_workflow_service import FinancialWorkflowService
import logging

logger = logging.getLogger(__name__)

def check_funding_deadlines(db: Session):
    """
    Monitor active campaigns that have passed their funding deadline.
    """
    now = datetime.utcnow()
    expired_campaigns = db.query(Campaign).filter(
        Campaign.status == 'active',
        Campaign.funding_end_date < now
    ).all()

    for campaign in expired_campaigns:
        try:
            if campaign.total_contributions >= campaign.funding_goal_f:
                logger.info(f"Campaign {campaign.campaign_id} reached goal. Transitioning to 'funded'.")
                CampaignStateService.mark_as_funded(db, campaign.campaign_id)
            else:
                logger.info(f"Campaign {campaign.campaign_id} missed goal. Transitioning to 'failed'.")
                CampaignStateService.terminate_campaign(db, campaign.campaign_id)
                # Trigger bulk refunds
                FinancialWorkflowService.initiate_bulk_refunds(db, campaign.campaign_id, reason="Funding deadline missed")
        except Exception as e:
            logger.error(f"Error processing deadline for campaign {campaign.campaign_id}: {str(e)}")
            db.rollback()

def check_voting_deadlines(db: Session):
    """
    Monitor milestones where the voting period has expired.
    """
    now = datetime.utcnow()
    expired_milestones = db.query(Milestone).filter(
        Milestone.status == 'voting_open',
        Milestone.voting_end_date < now
    ).all()

    for milestone in expired_milestones:
        try:
            logger.info(f"Voting period ended for milestone {milestone.milestone_id}. Tallying votes.")
            MilestoneWorkflowService.tally_votes(db, milestone.milestone_id)
            
            # If approved, we also trigger fund release
            db.refresh(milestone)
            if milestone.status == 'approved':
                FinancialWorkflowService.release_milestone_funds(db, milestone.milestone_id)
            
            # If it was the last milestone, complete the campaign
            campaign = milestone.campaign
            if milestone.status == 'approved' and milestone.milestone_number == campaign.num_phases_p:
                CampaignStateService.complete_campaign(db, campaign.campaign_id)
            # If rejected and max revisions exceeded, campaign fails (handled in tally_votes + Financial Service if needed)
            # tally_votes already transitions milestone to 'failed' if rejected and revisions exceeded.
            # We should check if we need to fail the campaign and trigger refunds here too.
            if milestone.status == 'failed':
                 CampaignStateService.terminate_campaign(db, campaign.campaign_id)
                 FinancialWorkflowService.initiate_bulk_refunds(db, campaign.campaign_id, reason="Milestone failed rejection")

        except Exception as e:
            logger.error(f"Error tallying votes for milestone {milestone.milestone_id}: {str(e)}")
            db.rollback()
