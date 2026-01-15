import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.db.base import Base
from app.models.campaign import Campaign
from app.models.user import User
from app.models.escrow import EscrowAccount
from app.models.transaction import Contribution, TransactionLedger
from app.models.vote import VoteToken
from app.services.payment_service import PaymentService
from app.core.redis import get_stk_session, delete_stk_session
import uuid

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

def test_stk_push_initiation(db):
    """
    Test that STK Push initiation creates a Redis session.
    """
    # Setup: Create fundraiser and campaign
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
        funding_goal_f=10000.0,
        status='active'
    )
    db.add(campaign)
    
    # Create escrow
    escrow = EscrowAccount(campaign_id=campaign.campaign_id, balance=0, total_contributions=0)
    db.add(escrow)
    
    # Create contributor
    contributor = User(
        account_id=uuid.uuid4(),
        email="contributor@test.com",
        password_hash="hash",
        role='contributor'
    )
    db.add(contributor)
    db.commit()
    
    # Action: Initiate STK Push
    result = PaymentService.initiate_stk_push(
        db=db,
        campaign_id=campaign.campaign_id,
        contributor_id=contributor.account_id,
        amount=500.0,
        phone_number="254712345678"
    )
    
    # Verify: Check response
    assert result["status"] == "pending"
    assert "checkout_request_id" in result
    assert result["checkout_request_id"].startswith("ws_CO_")
    
    # Verify: Check Redis session exists
    checkout_id = result["checkout_request_id"]
    session_data = get_stk_session(checkout_id)
    assert session_data is not None
    assert session_data["campaign_id"] == str(campaign.campaign_id)
    assert session_data["contributor_id"] == str(contributor.account_id)
    assert session_data["amount"] == 500.0
    
    # Cleanup
    delete_stk_session(checkout_id)

def test_successful_payment_callback(db):
    """
    Test that a successful callback creates a contribution and updates escrow.
    """
    # Setup: Create fundraiser, campaign, and contributor
    fundraiser = User(
        account_id=uuid.uuid4(),
        email="fundraiser@test.com",
        password_hash="hash",
        role='fundraiser'
    )
    contributor = User(
        account_id=uuid.uuid4(),
        email="contributor@test.com",
        password_hash="hash",
        role='contributor'
    )
    db.add_all([fundraiser, contributor])
    
    campaign = Campaign(
        campaign_id=uuid.uuid4(),
        fundraiser_id=fundraiser.account_id,
        title="Test Campaign",
        funding_goal_f=10000.0,
        status='active'
    )
    db.add(campaign)
    
    escrow = EscrowAccount(campaign_id=campaign.campaign_id, balance=0, total_contributions=0)
    db.add(escrow)
    db.commit()
    
    # Action 1: Initiate STK Push
    result = PaymentService.initiate_stk_push(
        db=db,
        campaign_id=campaign.campaign_id,
        contributor_id=contributor.account_id,
        amount=500.0,
        phone_number="254712345678"
    )
    checkout_id = result["checkout_request_id"]
    
    # Action 2: Simulate successful callback
    callback_result = PaymentService.process_stk_callback(
        db=db,
        checkout_request_id=checkout_id,
        result_code=0,  # Success
        result_desc="The service request is processed successfully."
    )
    
    # Verify: Callback processing succeeded
    assert callback_result["status"] == "success"
    
    # Verify: Contribution was created
    contribution = db.query(Contribution).filter(
        Contribution.campaign_id == campaign.campaign_id,
        Contribution.contributor_id == contributor.account_id
    ).first()
    assert contribution is not None
    assert float(contribution.amount) == 500.0
    assert contribution.status == 'completed'
    
    # Verify: Escrow was updated
    db.refresh(escrow)
    assert float(escrow.balance) == 500.0
    assert float(escrow.total_contributions) == 500.0
    
    # Verify: Ledger entry was created
    ledger = db.query(TransactionLedger).filter(
        TransactionLedger.contribution_id == contribution.contribution_id
    ).first()
    assert ledger is not None
    assert float(ledger.amount) == 500.0
    assert ledger.transaction_type == 'contribution'
    
    # Verify: Vote token was created
    vote_token = db.query(VoteToken).filter(
        VoteToken.campaign_id == campaign.campaign_id,
        VoteToken.contributor_id == contributor.account_id
    ).first()
    assert vote_token is not None
    
    # Verify: Redis session was deleted
    session_data = get_stk_session(checkout_id)
    assert session_data is None

def test_failed_payment_callback(db):
    """
    Test that a failed callback does NOT create a contribution.
    """
    # Setup
    fundraiser = User(
        account_id=uuid.uuid4(),
        email="fundraiser@test.com",
        password_hash="hash",
        role='fundraiser'
    )
    contributor = User(
        account_id=uuid.uuid4(),
        email="contributor@test.com",
        password_hash="hash",
        role='contributor'
    )
    db.add_all([fundraiser, contributor])
    
    campaign = Campaign(
        campaign_id=uuid.uuid4(),
        fundraiser_id=fundraiser.account_id,
        title="Test Campaign",
        funding_goal_f=10000.0,
        status='active'
    )
    db.add(campaign)
    
    escrow = EscrowAccount(campaign_id=campaign.campaign_id, balance=0, total_contributions=0)
    db.add(escrow)
    db.commit()
    
    # Action 1: Initiate STK Push
    result = PaymentService.initiate_stk_push(
        db=db,
        campaign_id=campaign.campaign_id,
        contributor_id=contributor.account_id,
        amount=500.0,
        phone_number="254712345678"
    )
    checkout_id = result["checkout_request_id"]
    
    # Action 2: Simulate failed callback (user cancelled)
    callback_result = PaymentService.process_stk_callback(
        db=db,
        checkout_request_id=checkout_id,
        result_code=1032,  # User cancelled
        result_desc="Request cancelled by user"
    )
    
    # Verify: Callback processing acknowledged failure
    assert callback_result["status"] == "failed"
    
    # Verify: NO contribution was created
    contribution = db.query(Contribution).filter(
        Contribution.campaign_id == campaign.campaign_id,
        Contribution.contributor_id == contributor.account_id
    ).first()
    assert contribution is None
    
    # Verify: Escrow balance unchanged
    db.refresh(escrow)
    assert float(escrow.balance) == 0.0
    
    # Verify: Redis session was deleted
    session_data = get_stk_session(checkout_id)
    assert session_data is None
