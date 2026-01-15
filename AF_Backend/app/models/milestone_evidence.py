from sqlalchemy import Column, String, ForeignKey, DateTime, Boolean, JSON
from sqlalchemy.orm import relationship
from app.db.base_class import GUID
import uuid
from datetime import datetime
from app.db.base_class import Base

class MilestoneEvidence(Base):
    __tablename__ = "milestone_evidence"
    
    evidence_id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    milestone_id = Column(GUID(), ForeignKey("milestone.milestone_id"))
    
    file_path = Column(String(255))  # Relative path to storage
    file_type = Column(String(50))   # 'image/jpeg', 'video/mp4', etc.
    metadata_json = Column(JSON)     # EXIF data, device info, etc.
    is_verified = Column(Boolean, default=False) # Result of automated checks
    
    uploaded_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    milestone = relationship("Milestone", back_populates="evidence")
