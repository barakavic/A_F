from sqlalchemy.orm import Session
from app.models.campaign import Campaign
from datetime import datetime, timedelta
from uuid import UUID
from typing import List

class CampaignStateService:
    # Define valid status transitions
    VALID_TRANSITIONS = {
        'draft': ['pending_review', 'active'],
        'pending_review': ['active', 'draft'],
        'active': ['funded', 'in_phases', 'failed'],
        'funded': ['in_phases', 'failed'],
        'in_phases': ['completed', 'failed'],
        'completed': [], # Final state
        'failed': []     # Final state
    }

    @staticmethod
    def validate_transition(current_status: str, next_status: str) -> bool:
        """
        Validates if a transition from current_status to next_status is allowed.
        """
        allowed_next = CampaignStateService.VALID_TRANSITIONS.get(current_status, [])
        return next_status in allowed_next

    @staticmethod
    def transition_status(db: Session, campaign_id: UUID, next_status: str) -> Campaign:
        """
        Transitions a campaign to a new status with validation and timestamp markers.
        """
        campaign = db.query(Campaign).filter(Campaign.campaign_id == campaign_id).first()
        if not campaign:
            raise ValueError("Campaign not found")

        if not CampaignStateService.validate_transition(campaign.status, next_status):
            raise ValueError(f"Invalid transition from {campaign.status} to {next_status}")

        campaign.status = next_status
        
        # Apply timestamp markers based on status
        now = datetime.utcnow()
        if next_status == 'pending_review':
            campaign.submitted_for_review_at = now
        elif next_status == 'active':
            campaign.launched_at = now
            campaign.funding_start_date = now
            # Assume 30 days per month for duration_d calculation
            campaign.funding_end_date = now + (timedelta(days=int(campaign.duration_d) * 30) if campaign.duration_d else timedelta(days=30))
        elif next_status == 'funded':
            campaign.funded_at = now
        elif next_status == 'in_phases':
            campaign.phases_started_at = now
            campaign.current_milestone_number = 1
        elif next_status == 'completed':
            campaign.completed_at = now
        elif next_status == 'failed':
            campaign.failed_at = now

        db.commit()
        db.refresh(campaign)
        return campaign

    @staticmethod
    def launch_campaign(db: Session, campaign_id: UUID) -> Campaign:
        """
        Moves campaign from draft to active.
        """
        return CampaignStateService.transition_status(db, campaign_id, 'active')

    @staticmethod
    def mark_as_funded(db: Session, campaign_id: UUID) -> Campaign:
        """
        Moves campaign from active to funded.
        """
        return CampaignStateService.transition_status(db, campaign_id, 'funded')

    @staticmethod
    def start_phases(db: Session, campaign_id: UUID) -> Campaign:
        """
        Moves campaign from funded to in_phases.
        """
        return CampaignStateService.transition_status(db, campaign_id, 'in_phases')

    @staticmethod
    def complete_campaign(db: Session, campaign_id: UUID) -> Campaign:
        """
        Finalizes a campaign after all milestones are approved.
        """
        campaign = CampaignStateService.transition_status(db, campaign_id, 'completed')
        
        # Trigger Broadcast
        from app.services.notification_service import NotificationService
        NotificationService.notify_campaign_completed(campaign.id, campaign.title)
        
        return campaign

    @staticmethod
    def terminate_campaign(db: Session, campaign_id: UUID) -> Campaign:
        """
        Marks campaign as failed (triggers refund process in workflow).
        """
        campaign = CampaignStateService.transition_status(db, campaign_id, 'failed')
        
        # Trigger Broadcast
        from app.services.notification_service import NotificationService
        NotificationService.notify_campaign_failed(campaign.id, campaign.title)
        
        return campaign
