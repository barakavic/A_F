from typing import Optional
from pydantic import BaseModel, EmailStr
from uuid import UUID

class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str
    role: str # 'contributor' or 'fundraiser'

class UserLogin(UserBase):
    password: str

class User(UserBase):
    account_id: UUID
    is_active: bool
    role: str
    
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    account_id: Optional[str] = None
