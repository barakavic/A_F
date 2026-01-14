from sqlalchemy.orm import Session
from app.models.transaction import Contribution, TransactionLedger
from app.models.campaign import Campaign
from app.models.escrow import EscrowAccount
from app.models.vote import VoteToken
from app.models.user import User
from datetime import datetime
import uuid
import hashlib

class ContributionService:
    @staticmethod
    def create_contribution(
        db: Session,
        campaign_id: uuid.UUID,
        contributor_id: uuid.UUID,
        amount: float,
        reference_code: str = None
    ):
        """
        Process a contribution:
        1. Verify campaign is active
        2. Create Contribution record
        3. Update Campaign totals
        4. Update Escrow balance
        5. Create Transaction Ledger entry
        6. Generate Vote Token if not exists
        """
        # 1. Verify Campaign
        campaign = db.query(Campaign).filter(Campaign.campaign_id == campaign_id).first()
        if not campaign:
            raise ValueError("Campaign not found")
        
        # In a real app, we'd check if status is 'active' or 'funded'
        # For now, let's allow contributions to 'active' or 'draft' (for testing)
        # But ideally: if campaign.status != 'active': raise ValueError("Campaign is not active")

        # 2. Create Contribution
        contribution = Contribution(
            campaign_id=campaign_id,
            contributor_id=contributor_id,
            amount=amount,
            status='completed' # Assuming payment is successful for this logic
        )
        db.add(contribution)
        db.flush() # Get contribution_id

        # 3. Update Campaign
        campaign.total_contributions = (campaign.total_contributions or 0) + amount
        
        # 4. Update Escrow
        escrow = db.query(EscrowAccount).filter(EscrowAccount.campaign_id == campaign_id).first()
        if not escrow:
            # Should have been created with campaign, but fallback just in case
            escrow = EscrowAccount(campaign_id=campaign_id)
            db.add(escrow)
            db.flush()
            
        escrow.total_contributions = (escrow.total_contributions or 0) + amount
        escrow.balance = (escrow.balance or 0) + amount
        
        # 5. Transaction Ledger
        ledger_entry = TransactionLedger(
            escrow_id=escrow.escrow_id,
            contribution_id=contribution.contribution_id,
            transaction_type='contribution',
            amount=amount,
            reference_code=reference_code or f"SIM-{uuid.uuid4().hex[:8].upper()}"
        )
        db.add(ledger_entry)

        # 6. Generate Vote Token
        # Check if contributor already has a token for this campaign
        existing_token = db.query(VoteToken).filter(
            VoteToken.campaign_id == campaign_id,
            VoteToken.contributor_id == contributor_id
        ).first()
        
        vote_token_id = None
        if not existing_token:
            # Generate a simple hash for the token (Keccak256 would be better, using sha256 for now)
            token_raw = f"{campaign_id}-{contributor_id}-{datetime.utcnow().timestamp()}"
            token_hash = hashlib.sha256(token_raw.encode()).hexdigest()
            
            new_token = VoteToken(
                campaign_id=campaign_id,
                contributor_id=contributor_id,
                token_hash=token_hash
            )
            db.add(new_token)
            db.flush()
            vote_token_id = new_token.token_id
        else:
            vote_token_id = existing_token.token_id

        db.commit()
        db.refresh(contribution)
        db.refresh(campaign)
        db.refresh(escrow)
        
        return {
            "contribution": contribution,
            "campaign_total_raised": campaign.total_contributions,
            "escrow_balance": escrow.balance,
            "vote_token_id": vote_token_id
        }
