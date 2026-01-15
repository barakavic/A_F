import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.db.base import Base
from app.models.user import User
from app.models.campaign import Campaign
from app.models.escrow import EscrowAccount
from app.models.transaction import Contribution, TransactionLedger
from app.models.vote import VoteToken
from app.services.contribution_service import ContributionService
import uuid

# Setup in-memory SQLite
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

def test_create_contribution_logic(db):
    campaign_id = uuid.uuid4()
    contributor_id = uuid.uuid4()
    
    db.add(User(account_id=contributor_id, email="c@test.com", password_hash="h", role='contributor'))
    campaign = Campaign(campaign_id=campaign_id, title="Test", funding_goal_f=1000.0)
    db.add(campaign)
    escrow = EscrowAccount(campaign_id=campaign_id)
    db.add(escrow)
    db.commit()

    ContributionService.create_contribution(db, campaign_id, contributor_id, 500.0)

    db.refresh(campaign)
    assert float(campaign.total_contributions) == 500.0
    db.refresh(escrow)
    assert float(escrow.balance) == 500.0
    token = db.query(VoteToken).filter(VoteToken.contributor_id == contributor_id).first()
    assert token is not None
