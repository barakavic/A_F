from typing import Optional
from pydantic import BaseModel, EmailStr
from uuid import UUID

class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str
    role: str # 'contributor' or 'fundraiser'

class ContributorRegister(UserBase):
    password: str
    uname: str
    phone_number: str
    public_key: Optional[str] = None

class FundraiserRegister(UserBase):
    password: str
    company_name: str
    br_number: str
    industry_l1_id: Optional[UUID] = None
    industry_l2_id: Optional[UUID] = None

class UserLogin(UserBase):
    password: str

class User(UserBase):
    account_id: UUID
    is_active: bool
    role: str
    
    class Config:
        from_attributes = True

class ContributorProfileOut(BaseModel):
    uname: str
    phone_number: str
    public_key: Optional[str]

    class Config:
        from_attributes = True

class FundraiserProfileOut(BaseModel):
    company_name: str
    br_number: str

    class Config:
        from_attributes = True

class UserOut(User):
    contributor_profile: Optional[ContributorProfileOut] = None
    fundraiser_profile: Optional[FundraiserProfileOut] = None

class Token(BaseModel):
    access_token: str
    token_type: str
    role: str
    account_id: UUID

class TokenData(BaseModel):
    account_id: Optional[str] = None

