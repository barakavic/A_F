from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.vote import VoteSubmission, VoteResult
from app.models.milestone import Milestone
from app.models.campaign import Campaign
from datetime import datetime
import uuid
from eth_account import Account
from eth_account.messages import encode_defunct
from app.models.user import User, ContributorProfile

class VoteService:
    @staticmethod
    def cast_vote(
        db: Session,
        milestone_id: uuid.UUID,
        contributor_id: uuid.UUID,
        vote_value: str = None,
        vote_hash: str = None,
        signature: str = None,
        is_waived: bool = False
    ) -> VoteSubmission:
        """
        Record a vote submission.
        If is_waived=True, the vote counts as YES without requiring vote_value/signature.
        TODO: Add signature verification logic here using web3 or eth_account.
        """
        # 1. Fetch Milestone & Verify Window
        milestone = db.query(Milestone).filter(Milestone.milestone_id == milestone_id).first()
        if not milestone:
            raise ValueError("Milestone not found")
            
        now = datetime.utcnow()
        if milestone.vote_window_start and milestone.vote_window_end:
            if now < milestone.vote_window_start or now > milestone.vote_window_end:
                raise ValueError("Voting window is closed")

        # 2. Integrity: Check if voter has a valid VoteToken for this campaign
        from app.models.vote import VoteToken
        token = db.query(VoteToken).filter(
            VoteToken.campaign_id == milestone.campaign_id,
            VoteToken.contributor_id == contributor_id
        ).first()
        
        if not token:
            raise ValueError("Integrity Error: You need a valid VoteToken to participate in this election.")

        # 3. Signature Requirement & Verification
        if not is_waived:
            if not signature:
                raise ValueError("Signature Required: Manual votes must be digitally signed.")
            
            # Fetch public key from contributor profile
            user = db.query(User).filter(User.account_id == contributor_id).first()
            if not user or not user.contributor_profile:
                raise ValueError("Contributor profile not found.")
            
            pub_key = user.contributor_profile.public_key
            if not pub_key:
                raise ValueError("No digital identity (public key) found for this contributor.")

            # Create the message that was signed
            # The message format must be consistent between frontend and backend
            message_text = f"Vote {vote_value} for Milestone {milestone_id}"
            message = encode_defunct(text=message_text)
            
            try:
                recovered_address = Account.recover_message(message, signature=signature)
                # Verify recovered address matches our stored public_key (checksummed for safety)
                if recovered_address.lower() != pub_key.lower():
                    raise ValueError(f"Integrity Error: Signature mismatch. Recovered {recovered_address} does not match registered key.")
            except Exception as e:
                if "Integrity Error" in str(e):
                    raise e
                raise ValueError(f"Signature Verification Failed: {str(e)}")

        # 4. Create Submission
        # If waived, automatically set vote_value to 'yes'
        final_vote_value = 'yes' if is_waived else vote_value
        
        vote = VoteSubmission(
            milestone_id=milestone_id,
            contributor_id=contributor_id,
            vote_value=final_vote_value,
            vote_hash=vote_hash,
            signature=signature,
            is_waived=is_waived
        )
        db.add(vote)
        db.commit()
        db.refresh(vote)
        return vote

    @staticmethod
    def tally_votes(db: Session, milestone_id: uuid.UUID) -> VoteResult:
        """
        Count votes, update VoteResult, and determine outcome.
        """
        # 1. Count Yes/No
        # This query groups by vote_value and counts
        # Note: Waived votes are stored with vote_value='yes', so they are automatically counted as yes.
        # But to be explicit, we can check is_waived too if needed.
        # Since cast_vote sets vote_value='yes' when waived, simple grouping works.
        results = db.query(
            VoteSubmission.vote_value, 
            func.count(VoteSubmission.vote_id)
        ).filter(
            VoteSubmission.milestone_id == milestone_id
        ).group_by(VoteSubmission.vote_value).all()
        
        yes_count = 0
        no_count = 0
        
        for value, count in results:
            if value == 'yes':
                yes_count = count
            elif value == 'no':
                no_count = count
                
        total_votes = yes_count + no_count
        
        # 2. Calculate Outcome
        # Simple majority > 75%
        yes_pct = 0.0
        outcome = 'rejected'
        
        if total_votes > 0:
            yes_pct = (yes_count / total_votes) * 100
            # Require 75% consensus for approval
            if yes_pct >= 75:
                outcome = 'approved'
            else:
                outcome = 'rejected'
        
        # 3. Update or Create VoteResult
        vote_result = db.query(VoteResult).filter(VoteResult.milestone_id == milestone_id).first()
        if not vote_result:
            vote_result = VoteResult(milestone_id=milestone_id)
            db.add(vote_result)
            
        vote_result.total_yes = yes_count
        vote_result.total_no = no_count
        vote_result.yes_percentage = yes_pct
        vote_result.outcome = outcome
        vote_result.tallied_at = datetime.utcnow()
        
        # 4. Update Milestone Status based on outcome
        milestone = db.query(Milestone).filter(Milestone.milestone_id == milestone_id).first()
        if milestone:
            if outcome == 'approved':
                milestone.status = 'approved'
            else:
                milestone.status = 'rejected'
        
        db.commit()
        db.refresh(vote_result)
        return vote_result
