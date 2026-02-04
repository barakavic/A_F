from sqlalchemy import Column, String, Date
from app.db.base_class import Base

class MockBRRegistry(Base):
    __tablename__ = "mock_br_registry"

    registration_number = Column(String(50), primary_key=True, index=True)
    business_name = Column(String(255), nullable=False)
    tax_pin = Column(String(20), nullable=True)
    registration_date = Column(Date, nullable=True)
    status = Column(String(20), default="ACTIVE", nullable=True)
