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
            metadata_json={"description": description},
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
        
        db.commit()
        db.refresh(milestone)
        return milestone

    @staticmethod
    def tally_votes(db: Session, milestone_id: UUID) -> Milestone:
        """
        Calculates the result of a voting window.
        Enforces 75% quorum rule (YES + Waived / Total).
        """
        milestone = db.query(Milestone).filter(Milestone.milestone_id == milestone_id).first()
        if not milestone:
            raise ValueError("Milestone not found")
        
        # Get all votes
        votes = db.query(VoteSubmission).filter(VoteSubmission.milestone_id == milestone_id).all()
        
        # In a real scenario, total_contributors would come from the campaign/vote_token table
        # For simplicity, we compare YES vs NO in the submissions
        total_votes = len(votes)
        if total_votes == 0:
            # Business rule: If NO ONE votes, but they were active, 
            # we might need a default or treat as failure. 
            # Let's assume rejection if goal not met.
            yes_votes = 0
            no_votes = 0
            yes_pct = 0
        else:
            yes_votes = len([v for v in votes if v.vote_value == 'yes' or v.is_waived])
            no_votes = total_votes - yes_votes
            yes_pct = (yes_votes / total_votes) * 100

        outcome = 'approved' if yes_pct >= 75 else 'rejected'
        
        # Save Result
        result = VoteResult(
            milestone_id=milestone.milestone_id,
            total_yes=yes_votes,
            total_no=no_votes,
            yes_percentage=yes_pct,
            outcome=outcome
        )
        db.add(result)
        
        # Update Milestone
        milestone.status = 'approved' if outcome == 'approved' else 'rejected'
        if outcome == 'approved':
            milestone.approved_at = datetime.utcnow()
            milestone.campaign.milestones_approved_count += 1
        else:
            milestone.rejected_at = datetime.utcnow()
            milestone.campaign.milestones_rejected_count += 1
            
        db.commit()
        db.refresh(milestone)
        return milestone
