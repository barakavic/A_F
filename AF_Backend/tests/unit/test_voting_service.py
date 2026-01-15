import pytest
from sqlalchemy import create_engine, Column, String, Integer, Text, ForeignKey
from sqlalchemy.orm import sessionmaker, declarative_base
from app.db.base import Base
from app.models.user import User, ContributorProfile
from app.models.campaign import Campaign
from app.models.milestone import Milestone
from app.models.vote import VoteToken, VoteSubmission
from app.utils.crypto import get_vote_message, verify_vote_signature
from eth_account import Account
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

def test_crypto_verification_logic():
    acc = Account.create()
    campaign_id = str(uuid.uuid4())
    milestone_id = str(uuid.uuid4())
    vote_value = "yes"
    nonce = "123456"
    
    message = get_vote_message(campaign_id, milestone_id, vote_value, nonce)
    from eth_account.messages import encode_defunct
    signable_message = encode_defunct(text=message)
    signed_message = Account.sign_message(signable_message, private_key=acc.key)
    signature = signed_message.signature.hex()
    
    is_valid = verify_vote_signature(
        campaign_id=campaign_id,
        milestone_id=milestone_id,
        vote_value=vote_value,
        nonce=nonce,
        signature=signature,
        public_key=acc.address
    )
    assert is_valid is True

def test_submit_vote_service_logic(db):
    acc = Account.create()
    contributor_id = uuid.uuid4()
    campaign_id = uuid.uuid4()
    milestone_id = uuid.uuid4()
    
    db.add(User(account_id=contributor_id, email="test@test.com", password_hash="h", role='contributor'))
    db.add(ContributorProfile(contributor_id=contributor_id, public_key=acc.address))
    db.add(Campaign(campaign_id=campaign_id, title="Test"))
    db.add(Milestone(milestone_id=milestone_id, campaign_id=campaign_id, description="M1"))
    db.add(VoteToken(campaign_id=campaign_id, contributor_id=contributor_id, token_hash="auth"))
    db.commit()
    
    vote_value = "yes"
    nonce = "1700000000"
    message = get_vote_message(str(campaign_id), str(milestone_id), vote_value, nonce)
    from eth_account.messages import encode_defunct
    signable_message = encode_defunct(text=message)
    signed_message = Account.sign_message(signable_message, private_key=acc.key)
    signature = signed_message.signature.hex()
    
    is_valid = verify_vote_signature(
        campaign_id=str(campaign_id),
        milestone_id=str(milestone_id),
        vote_value=vote_value,
        nonce=nonce,
        signature=signature,
        public_key=acc.address
    )
    assert is_valid is True
