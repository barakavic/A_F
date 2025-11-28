from sqlalchemy.orm import Session
from app.models.vote import VoteResult, VoteSubmission, VoteToken
from app.models.milestone import Milestone
from app.utils.keccak import keccak256
from datetime import datetime
import uuid

class VotingService:
    @staticmethod
    def generate_vote_token(db: Session, campaign_id: uuid.UUID, contributor_id: uuid.UUID) -> VoteToken:
        """
        Generate a vote token for a contributor.
        Token Hash = Keccak256(campaign_id + contributor_id + timestamp)
        """
        timestamp = datetime.utcnow().isoformat()
        raw_data = f"{campaign_id}{contributor_id}{timestamp}"
        token_hash = keccak256(raw_data)
        
        token = VoteToken(
            campaign_id=campaign_id,
            contributor_id=contributor_id,
            token_hash=token_hash
        )
        db.add(token)
        db.commit()
        db.refresh(token)
        return token

    @staticmethod
    def submit_vote(db: Session, milestone_id: uuid.UUID, contributor_id: uuid.UUID, vote_value: str, token_hash: str) -> VoteSubmission:
        """
        Submit a vote.
        Verifies token and creates submission.
        """
        # Verify token exists for this campaign (via milestone -> campaign)
        milestone = db.query(Milestone).filter(Milestone.milestone_id == milestone_id).first()
        if not milestone:
            raise ValueError("Milestone not found")
            
        token = db.query(VoteToken).filter(
            VoteToken.campaign_id == milestone.campaign_id,
            VoteToken.contributor_id == contributor_id,
            VoteToken.token_hash == token_hash
        ).first()
        
        if not token:
            raise ValueError("Invalid vote token")
            
        # Check if already voted
        existing_vote = db.query(VoteSubmission).filter(
            VoteSubmission.milestone_id == milestone_id,
            VoteSubmission.contributor_id == contributor_id
        ).first()
        
        if existing_vote:
            raise ValueError("Already voted on this milestone")
            
        # Create vote hash: Keccak256(token_hash + vote_value)
        vote_hash = keccak256(f"{token_hash}{vote_value}")
        
        vote = VoteSubmission(
            milestone_id=milestone_id,
            contributor_id=contributor_id,
            vote_value=vote_value,
            vote_hash=vote_hash
        )
        db.add(vote)
        db.commit()
        db.refresh(vote)
        return vote

    @staticmethod
    def tally_votes(db: Session, milestone_id: uuid.UUID) -> VoteResult:
        """
        Tally votes for a milestone and determine outcome.
        Consensus required: >= 75% YES.
        """
        votes = db.query(VoteSubmission).filter(VoteSubmission.milestone_id == milestone_id).all()
        
        total_votes = len(votes)
        yes_votes = sum(1 for v in votes if v.vote_value == 'yes')
        no_votes = sum(1 for v in votes if v.vote_value == 'no')
        
        if total_votes == 0:
            yes_percentage = 0
        else:
            yes_percentage = (yes_votes / total_votes) * 100
            
        outcome = 'approved' if yes_percentage >= 75 else 'rejected'
        
        result = VoteResult(
            milestone_id=milestone_id,
            total_yes=yes_votes,
            total_no=no_votes,
            quorum=total_votes,
            yes_percentage=yes_percentage,
            outcome=outcome
        )
        
        db.add(result)
        
        # Update milestone status
        milestone = db.query(Milestone).filter(Milestone.milestone_id == milestone_id).first()
        milestone.status = outcome
        
        db.commit()
        db.refresh(result)
        return result
