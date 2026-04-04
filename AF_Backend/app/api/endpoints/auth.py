from datetime import timedelta
from typing import Any
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.api.dependencies.deps import get_db, get_current_user
from app.core import security
from app.core.config import settings
from app.models.user import User, ContributorProfile, FundraiserProfile
from app.schemas.user import ContributorRegister, FundraiserRegister, Token, User as UserSchema, UserOut, FCMTokenUpdate

router = APIRouter()

@router.post("/login", response_model=Token)
def login_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db) 
) -> Any:
    """
    OAuth2 compatible token login, supports Email, Username or Phone (for contributors)
    """
    user = db.query(User).filter(User.email == form_data.username).first()
    
    if not user:
        user = db.query(User)\
            .join(ContributorProfile, User.account_id == ContributorProfile.contributor_id)\
            .filter(
                or_(
                    ContributorProfile.uname == form_data.username,
                    ContributorProfile.phone_number == form_data.username
                )
            ).first()

    if not user or not security.verify_password(form_data.password, user.password_hash):
        raise HTTPException(status_code=400, detail="Incorrect email, username, or password")
    
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
        

    display_name = None
    if user.role == 'fundraiser' and user.fundraiser_profile:
        display_name = user.fundraiser_profile.company_name
    elif user.role == 'contributor' and user.contributor_profile:
        display_name = user.contributor_profile.uname
        
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = security.create_access_token(
        subject=user.account_id, expires_delta=access_token_expires
    )
    return {
        "access_token": access_token, 
        "token_type": "bearer", 
        "role": user.role, 
        "account_id": user.account_id,
        "email": user.email,
        "display_name": display_name
    }

@router.post("/register/contributor", response_model=UserSchema)
def register_contributor(
    data: ContributorRegister,
    db: Session = Depends(get_db)
) -> Any:
    """
    Register a new contributor with profile. Checks for duplicates.
    """
    def normalize_phone(phone: str) -> str:
        p = phone.strip().replace("+", "")
        if p.startswith("254"):
            p = p[3:]
        if p.startswith("0"):
            p = p[1:]
        return p

    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(status_code=400, detail="User with this email already exists")
    
    if db.query(ContributorProfile).filter(ContributorProfile.uname == data.uname).first():
        raise HTTPException(status_code=400, detail="Username is already taken")
    
    norm_phone = normalize_phone(data.phone_number)
    if db.query(ContributorProfile).filter(ContributorProfile.phone_number.like(f"%{norm_phone}")).first():
        raise HTTPException(status_code=400, detail="Phone number is already registered")
    
    user = User(
        email=data.email,
        password_hash=security.get_password_hash(data.password),
        role='contributor',
        is_active=True
    )
    db.add(user)
    db.flush()
    
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
    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(status_code=400, detail="User with this email already exists")
    
    user = User(
        email=data.email,
        password_hash=security.get_password_hash(data.password),
        role='fundraiser',
        is_active=True
    )
    db.add(user)
    db.flush()
    
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

@router.post("/fcm-token")
def update_fcm_token(
    data: FCMTokenUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Update the FCM token for the current user.
    """
    current_user.fcm_token = data.fcm_token
    db.add(current_user)
    db.commit()
    return {"status": "ok", "message": "FCM token updated successfully"}
