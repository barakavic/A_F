import pytest
from eth_account import Account
from app.utils.crypto import get_waiver_message, verify_waiver_signature
from sqlalchemy import create_engine, Column, String, ForeignKey, Boolean, Text
from sqlalchemy.orm import sessionmaker, declarative_base
import uuid
import json

# Setup Base for testing
Base = declarative_base()

class User(Base):
    __tablename__ = "account"
    account_id = Column(String, primary_key=True)
    role = Column(String)

class ContributorProfile(Base):
    __tablename__ = "contributor_profile"
    contributor_id = Column(String, ForeignKey("account.account_id"), primary_key=True)
    public_key = Column(String)

class Campaign(Base):
    __tablename__ = "campaign"
    campaign_id = Column(String, primary_key=True)

class Milestone(Base):
    __tablename__ = "milestone"
    milestone_id = Column(String, primary_key=True)
    campaign_id = Column(String, ForeignKey("campaign.campaign_id"))

class VoteToken(Base):
    __tablename__ = "vote_token"
    token_id = Column(String, primary_key=True)
    campaign_id = Column(String, ForeignKey("campaign.campaign_id"))
    contributor_id = Column(String, ForeignKey("account.account_id"))

class VoteSubmission(Base):
    __tablename__ = "vote_submission"
    vote_id = Column(String, primary_key=True)
    milestone_id = Column(String, ForeignKey("milestone.milestone_id"))
    contributor_id = Column(String, ForeignKey("account.account_id"))
    vote_value = Column(String)
    is_waived = Column(Boolean, default=False)
    signature = Column(Text)
    vote_hash = Column(Text)

# Mocking the service logic for SQLite
class MockVotingService:
    @staticmethod
    def waive_all_votes(db, campaign_id, contributor_id, signature, nonce):
        profile = db.query(ContributorProfile).filter_by(contributor_id=str(contributor_id)).first()
        # Verify signature
        message = get_waiver_message(str(campaign_id), nonce)
        from eth_account.messages import encode_defunct
        signable_message = encode_defunct(text=message)
        recovered_address = Account.recover_message(signable_message, signature=signature)
        if recovered_address.lower() != profile.public_key.lower():
            raise ValueError("Invalid signature")
            
        milestones = db.query(Milestone).filter_by(campaign_id=str(campaign_id)).all()
        count = 0
        for m in milestones:
            vote = VoteSubmission(
                vote_id=str(uuid.uuid4()),
                milestone_id=m.milestone_id,
                contributor_id=str(contributor_id),
                vote_value='yes',
                is_waived=True,
                signature=signature,
                vote_hash="hash"
            )
            db.add(vote)
            count += 1
        db.commit()
        return count

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

def test_waive_all_votes_logic(db):
    acc = Account.create()
    contributor_id = str(uuid.uuid4())
    campaign_id = str(uuid.uuid4())
    
    db.add(User(account_id=contributor_id, role='contributor'))
    db.add(ContributorProfile(contributor_id=contributor_id, public_key=acc.address))
    db.add(Campaign(campaign_id=campaign_id))
    # Add 3 milestones
    db.add(Milestone(milestone_id=str(uuid.uuid4()), campaign_id=campaign_id))
    db.add(Milestone(milestone_id=str(uuid.uuid4()), campaign_id=campaign_id))
    db.add(Milestone(milestone_id=str(uuid.uuid4()), campaign_id=campaign_id))
    db.add(VoteToken(token_id=str(uuid.uuid4()), campaign_id=campaign_id, contributor_id=contributor_id))
    db.commit()
    
    # Sign waiver
    nonce = "999999"
    message = get_waiver_message(campaign_id, nonce)
    from eth_account.messages import encode_defunct
    signable_message = encode_defunct(text=message)
    signed_message = Account.sign_message(signable_message, private_key=acc.key)
    signature = signed_message.signature.hex()
    
    # Execute
    count = MockVotingService.waive_all_votes(db, campaign_id, contributor_id, signature, nonce)
    
    assert count == 3
    votes = db.query(VoteSubmission).filter_by(contributor_id=contributor_id).all()
    assert len(votes) == 3
    for v in votes:
        assert v.is_waived is True
        assert v.vote_value == 'yes'
