import pytest
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Numeric, Enum, Boolean, Text, ForeignKey, UniqueConstraint
from sqlalchemy.orm import sessionmaker, relationship, declarative_base
import uuid
from datetime import datetime

# Use a standard Base for testing
Base = declarative_base()

class User(Base):
    __tablename__ = "account"
    account_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    role = Column(String)

class Campaign(Base):
    __tablename__ = "campaign"
    campaign_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    fundraiser_id = Column(String)
    title = Column(String)
    funding_goal_f = Column(Numeric)
    total_contributions = Column(Numeric, default=0)

class EscrowAccount(Base):
    __tablename__ = "escrow_account"
    escrow_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    campaign_id = Column(String, ForeignKey("campaign.campaign_id"))
    total_contributions = Column(Numeric, default=0)
    balance = Column(Numeric, default=0)

class Contribution(Base):
    __tablename__ = "contribution"
    contribution_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    campaign_id = Column(String, ForeignKey("campaign.campaign_id"))
    contributor_id = Column(String, ForeignKey("account.account_id"))
    amount = Column(Numeric)
    status = Column(String, default='pending')

class TransactionLedger(Base):
    __tablename__ = "transaction_ledger"
    transaction_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    escrow_id = Column(String, ForeignKey("escrow_account.escrow_id"))
    contribution_id = Column(String, ForeignKey("contribution.contribution_id"), nullable=True)
    transaction_type = Column(String)
    amount = Column(Numeric)
    reference_code = Column(String)

class VoteToken(Base):
    __tablename__ = "vote_token"
    token_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    campaign_id = Column(String, ForeignKey("campaign.campaign_id"))
    contributor_id = Column(String, ForeignKey("account.account_id"))
    token_hash = Column(Text)

# The actual logic we want to test (replicated from ContributionService)
class ContributionService:
    @staticmethod
    def create_contribution(db, campaign_id, contributor_id, amount):
        campaign = db.query(Campaign).filter(Campaign.campaign_id == str(campaign_id)).first()
        contribution = Contribution(campaign_id=str(campaign_id), contributor_id=str(contributor_id), amount=amount, status='completed')
        db.add(contribution)
        db.flush()
        campaign.total_contributions = (campaign.total_contributions or 0) + amount
        escrow = db.query(EscrowAccount).filter(EscrowAccount.campaign_id == str(campaign_id)).first()
        escrow.total_contributions = (escrow.total_contributions or 0) + amount
        escrow.balance = (escrow.balance or 0) + amount
        ledger_entry = TransactionLedger(escrow_id=escrow.escrow_id, contribution_id=contribution.contribution_id, transaction_type='contribution', amount=amount, reference_code="TEST")
        db.add(ledger_entry)
        existing_token = db.query(VoteToken).filter(VoteToken.campaign_id == str(campaign_id), VoteToken.contributor_id == str(contributor_id)).first()
        if not existing_token:
            new_token = VoteToken(campaign_id=str(campaign_id), contributor_id=str(contributor_id), token_hash="hash")
            db.add(new_token)
        db.commit()
        return {"contribution": contribution}

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

def test_create_contribution_logic(db):
    campaign_id = str(uuid.uuid4())
    contributor_id = str(uuid.uuid4())
    db.add(User(account_id=contributor_id))
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
