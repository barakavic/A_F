import pytest
from sqlalchemy import create_engine, Column, String, ForeignKey, Numeric, Integer, DateTime, Boolean
from sqlalchemy.orm import sessionmaker, declarative_base, relationship
from decimal import Decimal
import uuid
from datetime import datetime
from app.services.escrow_service import EscrowService
from app.services.transaction_service import TransactionService

# Setup Base for testing
Base = declarative_base()

from sqlalchemy.dialects.postgresql import UUID

class Campaign(Base):
    __tablename__ = "campaign"
    campaign_id = Column(String, primary_key=True)
    target_amount = Column(Numeric(12, 2))

class Milestone(Base):
    __tablename__ = "milestone"
    milestone_id = Column(String, primary_key=True)
    campaign_id = Column(String, ForeignKey("campaign.campaign_id"))
    weight = Column(Numeric(5, 2))
    status = Column(String)
    campaign = relationship("Campaign")

class EscrowAccount(Base):
    __tablename__ = "escrow_account"
    escrow_id = Column(String, primary_key=True)
    campaign_id = Column(String, ForeignKey("campaign.campaign_id"))
    total_contributions = Column(Numeric(12, 2), default=0)
    total_released = Column(Numeric(12, 2), default=0)
    balance = Column(Numeric(12, 2), default=0)
    updated_at = Column(DateTime, default=datetime.utcnow)

class FundRelease(Base):
    __tablename__ = "fund_release"
    release_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    campaign_id = Column(String, ForeignKey("campaign.campaign_id"))
    milestone_id = Column(String, ForeignKey("milestone.milestone_id"))
    amount_released = Column(Numeric(12, 2))
    released_at = Column(DateTime, default=datetime.utcnow)

class TransactionLedger(Base):
    __tablename__ = "transaction_ledger"
    transaction_id = Column(String, primary_key=True)
    escrow_id = Column(String, ForeignKey("escrow_account.escrow_id"))
    transaction_type = Column(String)
    amount = Column(Numeric(12, 2))
    fund_release_id = Column(String, ForeignKey("fund_release.release_id"), nullable=True)
    contribution_id = Column(String, nullable=True)
    refund_event_id = Column(String, nullable=True)
    reference_code = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

# Mocking TransactionService for SQLite
class MockTransactionService:
    @staticmethod
    def record_disbursement(db, fund_release_id, escrow_id, amount):
        ledger = TransactionLedger(
            transaction_id=str(uuid.uuid4()),
            escrow_id=str(escrow_id),
            fund_release_id=str(fund_release_id),
            transaction_type='disbursement',
            amount=amount
        )
        db.add(ledger)
        escrow = db.query(EscrowAccount).filter_by(escrow_id=str(escrow_id)).first()
        escrow.total_released += amount
        escrow.balance -= amount
        db.commit()
        return ledger

# Patch EscrowService to use MockTransactionService and Test Models
import app.services.escrow_service
app.services.escrow_service.TransactionService = MockTransactionService
app.services.escrow_service.EscrowAccount = EscrowAccount
app.services.escrow_service.FundRelease = FundRelease
app.services.escrow_service.Milestone = Milestone
app.services.escrow_service.TransactionLedger = TransactionLedger

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
    c_id = str(uuid.uuid4())
    m_id = str(uuid.uuid4())
    e_id = str(uuid.uuid4())
    
    # Setup Campaign (Target: 100,000)
    db.add(Campaign(campaign_id=c_id, target_amount=Decimal("100000.00")))
    # Setup Milestone (Weight: 0.20 = 20,000)
    db.add(Milestone(milestone_id=m_id, campaign_id=c_id, weight=Decimal("0.20"), status='approved'))
    # Setup Escrow (Balance: 100,000)
    db.add(EscrowAccount(escrow_id=e_id, campaign_id=c_id, total_contributions=Decimal("100000.00"), balance=Decimal("100000.00")))
    db.commit()
    
    # Execute Release
    release = EscrowService.release_milestone_funds(db, m_id)
    
    assert release.amount_released == Decimal("20000.00")
    
    # Verify Escrow Update
    escrow = db.query(EscrowAccount).filter_by(escrow_id=e_id).first()
    assert escrow.balance == Decimal("80000.00")
    assert escrow.total_released == Decimal("20000.00")
    
    # Verify Ledger Entry
    ledger = db.query(TransactionLedger).filter_by(fund_release_id=release.release_id).first()
    assert ledger is not None
    assert ledger.amount == Decimal("20000.00")
    assert ledger.transaction_type == 'disbursement'

def test_release_milestone_funds_insufficient_balance(db):
    c_id = str(uuid.uuid4())
    m_id = str(uuid.uuid4())
    e_id = str(uuid.uuid4())
    
    db.add(Campaign(campaign_id=c_id, target_amount=Decimal("100000.00")))
    db.add(Milestone(milestone_id=m_id, campaign_id=c_id, weight=Decimal("0.20"), status='approved'))
    # Escrow has only 10,000
    db.add(EscrowAccount(escrow_id=e_id, campaign_id=c_id, total_contributions=Decimal("10000.00"), balance=Decimal("10000.00")))
    db.commit()
    
    with pytest.raises(ValueError, match="Insufficient escrow balance"):
        EscrowService.release_milestone_funds(db, m_id)
