import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.db.base import Base
from app.models.campaign import Campaign
from app.models.milestone import Milestone
from app.models.escrow import EscrowAccount
from app.models.fund_release import FundRelease
from app.models.transaction import TransactionLedger
from app.services.escrow_service import EscrowService
from decimal import Decimal
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

def test_release_milestone_funds_success(db):
    c_id = uuid.uuid4()
    m_id = uuid.uuid4()
    
    # Setup Campaign (Target: 100,000)
    db.add(Campaign(campaign_id=c_id, funding_goal_f=Decimal("100000.00")))
    # Setup Milestone (Weight: 0.20 = 20,000)
    db.add(Milestone(milestone_id=m_id, campaign_id=c_id, phase_weight_wi=Decimal("0.20"), status='approved'))
    # Setup Escrow (Balance: 100,000)
    db.add(EscrowAccount(campaign_id=c_id, total_contributions=Decimal("100000.00"), balance=Decimal("100000.00")))
    db.commit()
    
    # Execute Release
    release = EscrowService.release_milestone_funds(db, m_id)
    
    assert release.amount_released == Decimal("20000.00")
    
    # Verify Escrow Update
    escrow = db.query(EscrowAccount).filter_by(campaign_id=c_id).first()
    assert escrow.balance == Decimal("80000.00")
    assert escrow.total_released == Decimal("20000.00")
    
    # Verify Ledger Entry
    ledger = db.query(TransactionLedger).filter_by(fund_release_id=release.release_id).first()
    assert ledger is not None
    assert ledger.amount == Decimal("20000.00")
    assert ledger.transaction_type == 'disbursement'

def test_release_milestone_funds_insufficient_balance(db):
    c_id = uuid.uuid4()
    m_id = uuid.uuid4()
    
    db.add(Campaign(campaign_id=c_id, funding_goal_f=Decimal("100000.00")))
    db.add(Milestone(milestone_id=m_id, campaign_id=c_id, phase_weight_wi=Decimal("0.20"), status='approved'))
    # Escrow has only 10,000
    db.add(EscrowAccount(campaign_id=c_id, total_contributions=Decimal("10000.00"), balance=Decimal("10000.00")))
    db.commit()
    
    with pytest.raises(ValueError, match="Insufficient escrow balance"):
        EscrowService.release_milestone_funds(db, m_id)
