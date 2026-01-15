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
from app.services.refund_service import RefundService
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

def test_full_refund_flow(db):
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
        title="Test Campaign",
        funding_goal_f=1000.0,
        status='active'
    )
    db.add(campaign)
    
    # Create Escrow for campaign
    escrow = EscrowAccount(campaign_id=campaign.campaign_id, balance=0, total_contributions=0)
    db.add(escrow)
    db.commit()

    # 2. Create Contributors and Contributions
    contributor1 = User(
        account_id=uuid.uuid4(), 
        email="c1@test.com", 
        password_hash="hash", 
        role='contributor'
    )
    contributor2 = User(
        account_id=uuid.uuid4(), 
        email="c2@test.com", 
        password_hash="hash", 
        role='contributor'
    )
    db.add_all([contributor1, contributor2])
    db.commit()

    # Use ContributionService to process contributions (this also updates escrow and ledger)
    ContributionService.create_contribution(db, campaign.campaign_id, contributor1.account_id, 600.0)
    ContributionService.create_contribution(db, campaign.campaign_id, contributor2.account_id, 400.0)

    # Verify Escrow balance
    db.refresh(escrow)
    assert escrow.balance == 1000.0
    assert escrow.total_contributions == 1000.0

    # 3. Create a Milestone
    milestone = Milestone(
        milestone_id=uuid.uuid4(),
        campaign_id=campaign.campaign_id,
        description="Milestone 1",
        phase_weight_wi=0.5,
        status='pending'
    )
    db.add(milestone)
    db.commit()

    # 4. Simulate Milestone Rejection via VotingService
    # We need to add vote submissions first
    from app.models.vote import VoteSubmission, VoteToken
    
    # Ensure they have tokens (ContributionService should have created them)
    tokens = db.query(VoteToken).filter(VoteToken.campaign_id == campaign.campaign_id).all()
    assert len(tokens) == 2

    # Add NO votes to trigger rejection
    db.add(VoteSubmission(
        vote_id=uuid.uuid4(),
        milestone_id=milestone.milestone_id,
        contributor_id=contributor1.account_id,
        vote_value='no',
        vote_hash="hash1",
        signature="sig1"
    ))
    db.add(VoteSubmission(
        vote_id=uuid.uuid4(),
        milestone_id=milestone.milestone_id,
        contributor_id=contributor2.account_id,
        vote_value='no',
        vote_hash="hash2",
        signature="sig2"
    ))
    db.commit()

    # Tally votes - this should trigger RefundService.process_campaign_refunds
    VotingService.tally_votes(db, milestone.milestone_id)

    # 5. Verify Results
    db.refresh(milestone)
    assert milestone.status == 'rejected'

    # Check Escrow balance (should be 0 after full refund)
    db.refresh(escrow)
    assert escrow.balance == 0

    # Check RefundEvents
    refunds = db.query(RefundEvent).filter(RefundEvent.campaign_id == campaign.campaign_id).all()
    assert len(refunds) == 2
    
    # Check individual refund amounts
    refund1 = db.query(RefundEvent).filter(RefundEvent.contributor_id == contributor1.account_id).first()
    refund2 = db.query(RefundEvent).filter(RefundEvent.contributor_id == contributor2.account_id).first()
    
    assert refund1.amount_refunded == 600.0
    assert refund2.amount_refunded == 400.0

    # Check Ledger entries
    ledger_refunds = db.query(TransactionLedger).filter(TransactionLedger.transaction_type == 'refund').all()
    assert len(ledger_refunds) == 2

    # Check Contribution statuses
    c1_record = db.query(Contribution).filter(Contribution.contributor_id == contributor1.account_id).first()
    assert c1_record.status == 'refunded'
