from sqlalchemy.orm import Session
from app.models.milestone import Milestone
from app.models.campaign import Campaign
from app.models.milestone_evidence import MilestoneEvidence
from app.models.vote import VoteSubmission, VoteResult
from datetime import datetime, timedelta
from uuid import UUID
from typing import Optional, List

class MilestoneWorkflowService:
    
    @staticmethod
    def activate_milestone(db: Session, milestone_id: UUID) -> Milestone:
        """
        Moves a milestone from 'pending' to 'active'.
        Triggered when a campaign starts or previous milestone is completed.
        """
        milestone = db.query(Milestone).filter(Milestone.milestone_id == milestone_id).first()
        if not milestone:
            raise ValueError("Milestone not found")
        
        if milestone.status != 'pending':
            raise ValueError(f"Cannot activate milestone in status: {milestone.status}")
        
        milestone.status = 'active'
        milestone.activated_at = datetime.utcnow()
        
        # Update Campaign current milestone marker
        campaign = milestone.campaign
        campaign.current_milestone_number = milestone.milestone_number
        
        # TRIGGER NOTIFICATION: Fundraiser needs to submit evidence
        from app.services.notification_service import NotificationService
        NotificationService.notify_milestone_submission_required(
            db, campaign.fundraiser_id, campaign.title, milestone.milestone_number
        )
        
        db.commit()
        db.refresh(milestone)
        return milestone

    @staticmethod
    def submit_evidence(
        db: Session, 
        milestone_id: UUID, 
        description: str,
        file_path: Optional[str] = None,
        file_type: Optional[str] = None
    ) -> Milestone:
        """
        Fundraiser submits evidence. Advances status to 'evidence_submitted'.
        Handles revisions if previously rejected.
        """
        milestone = db.query(Milestone).filter(Milestone.milestone_id == milestone_id).first()
        if not milestone:
            raise ValueError("Milestone not found")
        
        if milestone.status not in ['active', 'rejected']:
            raise ValueError(f"Cannot submit evidence in status: {milestone.status}")

        # Create evidence record
        evidence = MilestoneEvidence(
            milestone_id=milestone.milestone_id,
            file_path=file_path,
            file_type=file_type,
            description=description,
            metadata_json={},
            uploaded_at=datetime.utcnow()
        )
        db.add(evidence)
        
        # Update milestone status
        if milestone.status == 'rejected':
            milestone.status = 'revision_submitted'
            milestone.revision_count += 1
        else:
            milestone.status = 'evidence_submitted'
            
        milestone.evidence_submitted_at = datetime.utcnow()
        
        # AUTOMATION: Automatically start voting window upon submission
        from datetime import timedelta
        milestone.status = 'voting_open'
        milestone.voting_start_date = datetime.utcnow()
        milestone.voting_end_date = datetime.utcnow() + timedelta(days=7)
        
        # TRIGGER BROADCAST EVENT: Voting Window Open
        from app.services.notification_service import NotificationService
        NotificationService.notify_voting_started(
            milestone.campaign_id, milestone.campaign.title, milestone.milestone_number
        )
        
        db.commit()
        db.refresh(milestone)
        return milestone

    @staticmethod
    def start_voting(db: Session, milestone_id: UUID, window_days: int = 7) -> Milestone:
        """
        Opens the 7-day voting window for contributors.
        """
        milestone = db.query(Milestone).filter(Milestone.milestone_id == milestone_id).first()
        if not milestone:
            raise ValueError("Milestone not found")
        
        if milestone.status not in ['evidence_submitted', 'revision_submitted']:
            raise ValueError("Evidence must be submitted before voting can start")
            
        now = datetime.utcnow()
        milestone.status = 'voting_open'
        milestone.voting_start_date = now
        milestone.voting_end_date = now + timedelta(days=window_days)
        
        # TRIGGER BROADCAST EVENT: Voting Window Open
        from app.services.notification_service import NotificationService
        NotificationService.notify_voting_started(
            milestone.campaign_id, milestone.campaign.title, milestone.milestone_number
        )
        
        db.commit()
        db.refresh(milestone)
        return milestone

    @staticmethod
    def tally_votes(db: Session, milestone_id: UUID) -> Milestone:
        """
        Calculates the result of a voting window.
        Delegates to VotingService for core tallying logic.
        """
        from app.services.voting_service import VotingService
        VotingService.tally_votes(db, milestone_id)
        
        milestone = db.query(Milestone).filter(Milestone.milestone_id == milestone_id).first()
        db.refresh(milestone)
        return milestone
