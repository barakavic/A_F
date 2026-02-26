from datetime import timedelta
from typing import Any
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.api.dependencies.deps import get_db, get_current_user
from app.core import security
from app.core.config import settings
from app.models.user import User, ContributorProfile, FundraiserProfile
from app.schemas.user import ContributorRegister, FundraiserRegister, Token, User as UserSchema, UserOut

router = APIRouter()

@router.post("/login", response_model=Token)
def login_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db) 
) -> Any:
    """
    OAuth2 compatible token login, get an access token for future requests
    """
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not security.verify_password(form_data.password, user.password_hash):
        raise HTTPException(status_code=400, detail="Incorrect email or password")
    
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
        
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = security.create_access_token(
        subject=user.account_id, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer", "role": user.role}

@router.post("/register/contributor", response_model=UserSchema)
def register_contributor(
    data: ContributorRegister,
    db: Session = Depends(get_db)
) -> Any:
    """
    Register a new contributor with profile.
    """
    # Check if user exists
    existing_user = db.query(User).filter(User.email == data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="User with this email already exists",
        )
    
    # Create account
    user = User(
        email=data.email,
        password_hash=security.get_password_hash(data.password),
        role='contributor',
        is_active=True
    )
    db.add(user)
    db.flush()  # Get account_id
    
    # Create contributor profile
    profile = ContributorProfile(
        contributor_id=user.account_id,
        uname=data.uname,
        phone_number=data.phone_number,
        public_key=data.public_key
    )
    db.add(profile)
    db.commit()
    db.refresh(user)
    return user

@router.post("/register/fundraiser", response_model=UserSchema)
def register_fundraiser(
    data: FundraiserRegister,
    db: Session = Depends(get_db)
) -> Any:
    """
    Register a new fundraiser with profile.
    """
    # Check if user exists
    existing_user = db.query(User).filter(User.email == data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="User with this email already exists",
        )
    
    # Create account
    user = User(
        email=data.email,
        password_hash=security.get_password_hash(data.password),
        role='fundraiser',
        is_active=True
    )
    db.add(user)
    db.flush()  # Get account_id
    
    # Create fundraiser profile
    profile = FundraiserProfile(
        fundraiser_id=user.account_id,
        company_name=data.company_name,
        br_number=data.br_number,
        industry_l1_id=data.industry_l1_id,
        industry_l2_id=data.industry_l2_id
    )
    db.add(profile)
    db.commit()
    db.refresh(user)
    return user

@router.get("/me", response_model=UserOut)
def read_user_me(
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Get current user.
    """
    return current_user

