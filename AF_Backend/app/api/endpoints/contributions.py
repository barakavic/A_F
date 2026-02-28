from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api.dependencies.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.contribution import (
    ContributionCreate, 
    ContributionResponse, 
    UserContributionOut, 
    ContributorStats, 
    ContributorWalletStats, 
    WalletLedgerEntry
)
from app.models.transaction import Contribution
from app.models.campaign import Campaign
from app.models.escrow import EscrowAccount
from app.services.contribution_service import ContributionService
from sqlalchemy import func

router = APIRouter()

@router.get("/wallet-stats", response_model=ContributorWalletStats)
def get_contributor_wallet_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Get detailed wallet stats and history for the contributor.
    """
    if current_user.role != 'contributor':
        raise HTTPException(status_code=403, detail="Stats only available for contributors")

    # 1. Lifetime Invested Funds (All successful pledges)
    invested_funds = db.query(func.sum(Contribution.amount))\
        .filter(Contribution.contributor_id == current_user.account_id, Contribution.status == 'completed')\
        .scalar() or 0

    # 2. Available Funds (Safety Net / Escrow Balance)
    # Calculate share of escrow balance based on contributor's percentage share of the campaign
    contributions = db.query(Contribution, EscrowAccount)\
        .join(EscrowAccount, Contribution.campaign_id == EscrowAccount.campaign_id)\
        .filter(Contribution.contributor_id == current_user.account_id, Contribution.status == 'completed')\
        .all()
    
    available_funds = 0
    ledger_entries = []
    print(f"[DEBUG] Wallet Stats for {current_user.account_id}: found {len(contributions)} contribution segments")
    for contr, escrow in contributions:
        # Calculate current share of the escrow balance
        if escrow.total_contributions > 0:
            share_percentage = float(contr.amount) / float(escrow.total_contributions)
            user_available_share = float(escrow.balance) * share_percentage
            available_funds += user_available_share
            print(f"  - Segment: Amt={contr.amount}, EscrowBal={escrow.balance}, TotalContr={escrow.total_contributions}, Share={share_percentage}, UserShare={user_available_share}")
        else:
            print(f"  - Warning: escrow {escrow.escrow_id} has 0 total_contributions")
        
        # Add to ledger
        campaign = db.query(Campaign).filter(Campaign.campaign_id == contr.campaign_id).first()
        ledger_entries.append({
            "id": contr.contribution_id,
            "campaign_title": campaign.title if campaign else "Unknown",
            "amount": contr.amount,
            "type": "contribution",
            "status": contr.status,
            "date": contr.created_at
        })

    print(f"[DEBUG] Wallet Stats Final: Available={available_funds}, Invested={invested_funds}")
    return {
        "available_funds": available_funds,
        "invested_funds": invested_funds,
        "ledger": sorted(ledger_entries, key=lambda x: x['date'], reverse=True)
    }

@router.get("/stats", response_model=ContributorStats)
def get_contributor_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Get portfolio stats for the current contributor.
    """
    if current_user.role != 'contributor':
        raise HTTPException(status_code=403, detail="Stats only available for contributors")

    # Aggregate total portfolio value
    total_value = db.query(func.sum(Contribution.amount))\
        .filter(Contribution.contributor_id == current_user.account_id, Contribution.status == 'completed')\
        .scalar() or 0

    # Count unique active campaigns invested in
    active_count = db.query(func.count(func.distinct(Contribution.campaign_id)))\
        .filter(Contribution.contributor_id == current_user.account_id, Contribution.status == 'completed')\
        .scalar() or 0

    print(f"[DEBUG] Stats for {current_user.account_id}: Value={total_value}, Count={active_count}")

    return {
        "total_portfolio_value": total_value,
        "active_investments_count": active_count
    }

@router.post("/", response_model=ContributionResponse)
def create_contribution(
    contribution_in: ContributionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Pledge a contribution to a campaign.
    Only users with 'contributor' role can perform this action.
    """
    if current_user.role != 'contributor':
        raise HTTPException(
            status_code=403, 
            detail="Only contributors can pledge to campaigns"
        )
        
    try:
        result = ContributionService.create_contribution(
            db=db,
            campaign_id=contribution_in.campaign_id,
            contributor_id=current_user.account_id,
            amount=float(contribution_in.amount)
        )
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")

@router.get("/my-contributions", response_model=List[UserContributionOut])
def get_my_contributions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Get all contributions made by the current user.
    """
    contributions = db.query(Contribution).join(Campaign).filter(
        Contribution.contributor_id == current_user.account_id
    ).all()
    
    result = []
    for c in contributions:
        result.append({
            "contribution_id": c.contribution_id,
            "campaign_id": c.campaign_id,
            "campaign_title": c.campaign.title,
            "campaign_status": c.campaign.status,
            "amount": c.amount,
            "status": c.status,
            "created_at": c.created_at
        })
    
    return result
