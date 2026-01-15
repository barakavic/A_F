import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.db.base import Base
from app.models.campaign import Campaign
from app.models.user import User
from app.models.milestone import Milestone
from app.models.escrow import EscrowAccount
from app.models.transaction import Contribution, TransactionLedger
from app.models.refund_event import RefundEvent
from app.services.contribution_service import ContributionService
from app.services.voting_service import VotingService
from app.services.escrow_service import EscrowService
import uuid
from decimal import Decimal

# Setup in-memory SQLite for testing
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture
def db():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)

def test_partial_refund_after_disbursement(db):
    """
    Test scenario with 3 contributors and a partial refund after one milestone is disbursed.
    """
    # 1. Create a Fundraiser and a Campaign
    fundraiser = User(
        account_id=uuid.uuid4(), 
        email="fundraiser@test.com", 
        password_hash="hash", 
        role='fundraiser'
    )
    db.add(fundraiser)
    
    campaign = Campaign(
        campaign_id=uuid.uuid4(),
        fundraiser_id=fundraiser.account_id,
        title="Advanced Test Campaign",
        funding_goal_f=1000.0,
        status='active'
    )
    db.add(campaign)
    
    # Create Escrow for campaign
    escrow = EscrowAccount(campaign_id=campaign.campaign_id, balance=0, total_contributions=0)
    db.add(escrow)
    db.commit()

    # 2. Create 3 Contributors and Contributions
    # User A: 500, User B: 300, User C: 200
    contributors = [
        User(account_id=uuid.uuid4(), email="a@test.com", password_hash="h", role='contributor'),
        User(account_id=uuid.uuid4(), email="b@test.com", password_hash="h", role='contributor'),
        User(account_id=uuid.uuid4(), email="c@test.com", password_hash="h", role='contributor')
    ]
    db.add_all(contributors)
    db.commit()

    ContributionService.create_contribution(db, campaign.campaign_id, contributors[0].account_id, 500.0)
    ContributionService.create_contribution(db, campaign.campaign_id, contributors[1].account_id, 300.0)
    ContributionService.create_contribution(db, campaign.campaign_id, contributors[2].account_id, 200.0)

    # Verify Escrow balance is 1000
    db.refresh(escrow)
    assert escrow.balance == 1000.0

    # 3. Create 2 Milestones
    m1 = Milestone(
        milestone_id=uuid.uuid4(),
        campaign_id=campaign.campaign_id,
        description="Milestone 1 (40%)",
        phase_weight_wi=0.4,
        status='approved' # Pre-approve for disbursement
    )
    m2 = Milestone(
        milestone_id=uuid.uuid4(),
        campaign_id=campaign.campaign_id,
        description="Milestone 2 (60%)",
        phase_weight_wi=0.6,
        status='pending'
    )
    db.add_all([m1, m2])
    db.commit()

    # 4. Disburse Milestone 1 (400.00)
    EscrowService.release_milestone_funds(db, m1.milestone_id)
    
    db.refresh(escrow)
    assert escrow.balance == 600.0
    assert escrow.total_released == 400.0

    # 5. Reject Milestone 2 to trigger partial refund
    # Add NO votes
    from app.models.vote import VoteSubmission
    for contributor in contributors:
        db.add(VoteSubmission(
            vote_id=uuid.uuid4(),
            milestone_id=m2.milestone_id,
            contributor_id=contributor.account_id,
            vote_value='no',
            vote_hash=f"hash-{contributor.account_id}",
            signature=f"sig-{contributor.account_id}"
        ))
    db.commit()

    # Tally votes - triggers RefundService
    VotingService.tally_votes(db, m2.milestone_id)

    # 6. Verify Partial Refunds (Pro-rata 60%)
    db.refresh(escrow)
    assert escrow.balance == 0
    
    # User A (500) -> 300 refund
    # User B (300) -> 180 refund
    # User C (200) -> 120 refund
    
    refund_a = db.query(RefundEvent).filter(RefundEvent.contributor_id == contributors[0].account_id).first()
    refund_b = db.query(RefundEvent).filter(RefundEvent.contributor_id == contributors[1].account_id).first()
    refund_c = db.query(RefundEvent).filter(RefundEvent.contributor_id == contributors[2].account_id).first()
    
    assert refund_a.amount_refunded == 300.0
    assert refund_b.amount_refunded == 180.0
    assert refund_c.amount_refunded == 120.0
    
    # Verify Ledger
    ledger_refunds = db.query(TransactionLedger).filter(TransactionLedger.transaction_type == 'refund').all()
    assert len(ledger_refunds) == 3
    assert sum(r.amount for r in ledger_refunds) == 600.0
