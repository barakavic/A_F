from sqlalchemy.orm import Session
import uuid
from app.models.vote import VoteResult, VoteSubmission, VoteToken
from app.models.milestone import Milestone
from app.models.user import ContributorProfile
from app.utils.crypto import verify_vote_signature, generate_keccak_hash

class VotingService:
    @staticmethod
    def generate_vote_token(db: Session, campaign_id: uuid.UUID, contributor_id: uuid.UUID) -> VoteToken:
        """
        Generate a vote token for a contributor.
        In the new system, this is mainly a record that the user is authorized to vote.
        """
        token = VoteToken(
            campaign_id=campaign_id,
            contributor_id=contributor_id,
            token_hash="authorized" # We use the public_key from profile for verification
        )
        db.add(token)
        db.commit()
        db.refresh(token)
        return token

    @staticmethod
    def submit_vote(
        db: Session, 
        milestone_id: uuid.UUID, 
        contributor_id: uuid.UUID, 
        vote_value: str, 
        signature: str, 
        nonce: str
    ) -> VoteSubmission:
        """
        Submit a vote with digital signature verification.
        """
        # 1. Verify Milestone exists
        milestone = db.query(Milestone).filter(Milestone.milestone_id == milestone_id).first()
        if not milestone:
            raise ValueError("Milestone not found")
            
        # 2. Verify Contributor is authorized (has a token)
        token = db.query(VoteToken).filter(
            VoteToken.campaign_id == milestone.campaign_id,
            VoteToken.contributor_id == contributor_id
        ).first()
        
        if not token:
            raise ValueError("You are not authorized to vote on this campaign")
            
        # 3. Get Contributor's Public Key
        profile = db.query(ContributorProfile).filter(ContributorProfile.contributor_id == contributor_id).first()
        if not profile or not profile.public_key:
            raise ValueError("Contributor public key not found. Please set up your profile.")

        # 4. Verify Digital Signature
        is_valid = verify_vote_signature(
            campaign_id=str(milestone.campaign_id),
            milestone_id=str(milestone_id),
            vote_value=vote_value,
            nonce=nonce,
            signature=signature,
            public_key=profile.public_key
        )
        
        if not is_valid:
            raise ValueError("Invalid cryptographic signature. Vote rejected.")

        # 5. Check if already voted
        existing_vote = db.query(VoteSubmission).filter(
            VoteSubmission.milestone_id == milestone_id,
            VoteSubmission.contributor_id == contributor_id
        ).first()
        
        if existing_vote:
            raise ValueError("Already voted on this milestone")
            
        # 6. Create vote hash for audit trail
        vote_hash = generate_keccak_hash(f"{signature}{nonce}")
        
        vote = VoteSubmission(
            milestone_id=milestone_id,
            contributor_id=contributor_id,
            vote_value=vote_value,
            vote_hash=vote_hash,
            signature=signature
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
