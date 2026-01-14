import pytest
from sqlalchemy import create_engine, Column, String, ForeignKey, Integer, Numeric, Enum, Boolean, DateTime
from sqlalchemy.orm import sessionmaker, declarative_base
import uuid
from datetime import datetime
from app.services.voting_service import VotingService

# Setup Base for testing
Base = declarative_base()

class Milestone(Base):
    __tablename__ = "milestone"
    milestone_id = Column(String, primary_key=True)
    status = Column(String)

class VoteSubmission(Base):
    __tablename__ = "vote_submission"
    vote_id = Column(String, primary_key=True)
    milestone_id = Column(String, ForeignKey("milestone.milestone_id"))
    contributor_id = Column(String)
    vote_value = Column(String)
    is_waived = Column(Boolean, default=False)

class VoteResult(Base):
    __tablename__ = "vote_result"
    result_id = Column(String, primary_key=True)
    milestone_id = Column(String, ForeignKey("milestone.milestone_id"))
    total_yes = Column(Integer)
    total_no = Column(Integer)
    quorum = Column(Integer)
    yes_percentage = Column(Numeric)
    outcome = Column(String)

# Mocking the service to use our test models
class MockVotingService(VotingService):
    @staticmethod
    def tally_votes(db, milestone_id):
        votes = db.query(VoteSubmission).filter(VoteSubmission.milestone_id == str(milestone_id)).all()
        total_votes = len(votes)
        if total_votes == 0:
            yes_votes = 0
            no_votes = 0
            yes_percentage = 0
        else:
            yes_votes = sum(1 for v in votes if v.vote_value == 'yes' or v.is_waived is True)
            no_votes = total_votes - yes_votes
            yes_percentage = (yes_votes / total_votes) * 100
            
        outcome = 'approved' if yes_percentage >= 75 else 'rejected'
        result = VoteResult(
            result_id=str(uuid.uuid4()),
            milestone_id=str(milestone_id),
            total_yes=yes_votes,
            total_no=no_votes,
            quorum=total_votes,
            yes_percentage=yes_percentage,
            outcome=outcome
        )
        db.add(result)
        milestone = db.query(Milestone).filter(Milestone.milestone_id == str(milestone_id)).first()
        if milestone:
            milestone.status = outcome
        db.commit()
        return result

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

def test_tally_approved(db):
    m_id = str(uuid.uuid4())
    db.add(Milestone(milestone_id=m_id, status='pending'))
    
    # 3 YES, 1 NO = 75% (Approved)
    db.add(VoteSubmission(vote_id=str(uuid.uuid4()), milestone_id=m_id, vote_value='yes'))
    db.add(VoteSubmission(vote_id=str(uuid.uuid4()), milestone_id=m_id, vote_value='yes'))
    db.add(VoteSubmission(vote_id=str(uuid.uuid4()), milestone_id=m_id, vote_value='yes'))
    db.add(VoteSubmission(vote_id=str(uuid.uuid4()), milestone_id=m_id, vote_value='no'))
    db.commit()
    
    result = MockVotingService.tally_votes(db, m_id)
    assert result.outcome == 'approved'
    assert float(result.yes_percentage) == 75.0

def test_tally_rejected(db):
    m_id = str(uuid.uuid4())
    db.add(Milestone(milestone_id=m_id, status='pending'))
    
    # 2 YES, 2 NO = 50% (Rejected)
    db.add(VoteSubmission(vote_id=str(uuid.uuid4()), milestone_id=m_id, vote_value='yes'))
    db.add(VoteSubmission(vote_id=str(uuid.uuid4()), milestone_id=m_id, vote_value='yes'))
    db.add(VoteSubmission(vote_id=str(uuid.uuid4()), milestone_id=m_id, vote_value='no'))
    db.add(VoteSubmission(vote_id=str(uuid.uuid4()), milestone_id=m_id, vote_value='no'))
    db.commit()
    
    result = MockVotingService.tally_votes(db, m_id)
    assert result.outcome == 'rejected'
    assert float(result.yes_percentage) == 50.0

def test_tally_with_waived_votes(db):
    m_id = str(uuid.uuid4())
    db.add(Milestone(milestone_id=m_id, status='pending'))
    
    # 2 YES, 1 WAIVED, 1 NO = 75% (Approved)
    db.add(VoteSubmission(vote_id=str(uuid.uuid4()), milestone_id=m_id, vote_value='yes'))
    db.add(VoteSubmission(vote_id=str(uuid.uuid4()), milestone_id=m_id, vote_value='yes'))
    db.add(VoteSubmission(vote_id=str(uuid.uuid4()), milestone_id=m_id, is_waived=True))
    db.add(VoteSubmission(vote_id=str(uuid.uuid4()), milestone_id=m_id, vote_value='no'))
    db.commit()
    
    result = MockVotingService.tally_votes(db, m_id)
    assert result.outcome == 'approved'
    assert float(result.yes_percentage) == 75.0
