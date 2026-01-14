from sqlalchemy import Boolean, Column, Integer, String, ForeignKey, DateTime, Numeric, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime
from app.db.base_class import Base

class User(Base):
    __tablename__ = "account"
    
    account_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    role = Column(Enum('admin', 'contributor', 'fundraiser', name='user_role'), nullable=False)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    contributor_profile = relationship("ContributorProfile", back_populates="user", uselist=False)
    fundraiser_profile = relationship("FundraiserProfile", back_populates="user", uselist=False)

class ContributorProfile(Base):
    __tablename__ = "contributor_profile"
    
    contributor_id = Column(UUID(as_uuid=True), ForeignKey("account.account_id"), primary_key=True)
    uname = Column(String(120))
    phone_number = Column(String(20))
    public_key = Column(String(66), nullable=True) # For digital signatures
    created_at = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("User", back_populates="contributor_profile")

class FundraiserProfile(Base):
    __tablename__ = "fundraiser_profile"
    
    fundraiser_id = Column(UUID(as_uuid=True), ForeignKey("account.account_id"), primary_key=True)
    company_name = Column(String(200))
    br_number = Column(String(50))
    industry_l1_id = Column(UUID(as_uuid=True), ForeignKey("company_category_l1.l1_id"))
    industry_l2_id = Column(UUID(as_uuid=True), ForeignKey("company_category_l2.l2_id"), nullable=True)
    risk_score_c = Column(Numeric(4, 3))
    br_verified = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("User", back_populates="fundraiser_profile")
    industry_l1 = relationship("CompanyCategoryL1")
    industry_l2 = relationship("CompanyCategoryL2")
    campaigns = relationship("Campaign", back_populates="fundraiser")

class CompanyCategoryL1(Base):
    __tablename__ = "company_category_l1"
    
    l1_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    l1_name = Column(String(100))
    l1_risk_weight = Column(Numeric(4, 3))

class CompanyCategoryL2(Base):
    __tablename__ = "company_category_l2"
    
    l2_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    l1_id = Column(UUID(as_uuid=True), ForeignKey("company_category_l1.l1_id"))
    l2_name = Column(String(100))
    l2_risk_weight = Column(Numeric(4, 3))

class CompanyRiskMapping(Base):
    __tablename__ = "company_risk_mapping"
    
    mapping_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    l1_weight = Column(Numeric(3, 2), default=0.70)
    l2_weight = Column(Numeric(3, 2), default=0.30)
    default_l2_adjust = Column(Numeric(4, 3), default=0.06)
    min_risk = Column(Numeric(4, 3))
    max_risk = Column(Numeric(4, 3))
