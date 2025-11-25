"""
Account models with PostgreSQL partitioning.
"""
from sqlalchemy import Column, String, Boolean, DateTime, Enum, ForeignKey, Numeric, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.db.base import Base
import uuid
from datetime import datetime

class Account(Base):
    """
    Base Account table partitioned by role.
    """
    __tablename__ = "account"
    __table_args__ = (
        {"postgresql_partition_by": "LIST (role)"}
    )

    account_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(120), unique=True, nullable=False)
    password_hash = Column(String, nullable=False)
    role = Column(String, primary_key=True)  # Part of PK for partitioning
    email_verified = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class AccountContributor(Account):
    """
    Contributor partition of Account.
    """
    __tablename__ = "account_contributor"
    __mapper_args__ = {
        "polymorphic_identity": "contributor",
        "concrete": True
    }


class AccountFundraiser(Account):
    """
    Fundraiser partition of Account.
    """
    __tablename__ = "account_fundraiser"
    __mapper_args__ = {
        "polymorphic_identity": "fundraiser",
        "concrete": True
    }


class ContributorProfile(Base):
    """
    Profile details for contributors.
    """
    __tablename__ = "contributor_profile"

    contributor_id = Column(UUID(as_uuid=True), ForeignKey("account_contributor.account_id"), primary_key=True)
    uname = Column(String(120))
    phone_number = Column(String(20))
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    # account = relationship("AccountContributor", backref="profile")


class FundraiserProfile(Base):
    """
    Profile details for fundraisers.
    """
    __tablename__ = "fundraiser_profile"

    fundraiser_id = Column(UUID(as_uuid=True), ForeignKey("account_fundraiser.account_id"), primary_key=True)
    company_name = Column(String(200))
    br_number = Column(String(50))
    industry_l1_id = Column(UUID(as_uuid=True)) # FK to be added when category table exists
    industry_l2_id = Column(UUID(as_uuid=True), nullable=True) # FK to be added when category table exists
    risk_score_C = Column(Numeric(4, 3))
    br_verified = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    # account = relationship("AccountFundraiser", backref="profile")
