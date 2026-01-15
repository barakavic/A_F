from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, Field
from app.db.session import get_db
from app.services.payment_service import PaymentService
from app.api.deps import get_current_user
from app.models.user import User
import uuid
from typing import Optional

router = APIRouter()

# Request/Response Models
class STKPushRequest(BaseModel):
    campaign_id: str = Field(..., description="UUID of the campaign")
    amount: float = Field(..., gt=0, description="Amount to contribute (must be positive)")
    phone_number: str = Field(..., pattern=r"^254\d{9}$", description="M-Pesa phone number (format: 254XXXXXXXXX)")

class STKPushResponse(BaseModel):
    status: str
    checkout_request_id: str
    message: str

class CallbackRequest(BaseModel):
    """
    Mimics the structure of Safaricom's callback payload.
    In production, this will be the actual Safaricom format.
    """
    Body: dict

@router.post("/stk-push", response_model=STKPushResponse, status_code=status.HTTP_200_OK)
def initiate_stk_push(
    request: STKPushRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Initiate an M-Pesa STK Push for a campaign contribution.
    
    The user will receive a PIN prompt on their phone.
    Once they enter the PIN, Safaricom will send a callback to our server.
    """
    try:
        campaign_id = uuid.UUID(request.campaign_id)
        contributor_id = current_user.account_id
        
        result = PaymentService.initiate_stk_push(
            db=db,
            campaign_id=campaign_id,
            contributor_id=contributor_id,
            amount=request.amount,
            phone_number=request.phone_number
        )
        
        return STKPushResponse(**result)
    
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Payment initiation failed: {str(e)}")

@router.post("/callback", status_code=status.HTTP_200_OK)
def mpesa_callback(
    callback_data: CallbackRequest,
    db: Session = Depends(get_db)
):
    """
    Handle M-Pesa STK Push callback.
    
    This endpoint is called by Safaricom (or our simulator) after the user enters their PIN.
    It's a public endpoint (no authentication) because Safaricom doesn't have a login token.
    
    In production, we'll add IP whitelisting to only accept requests from Safaricom's servers.
    """
    try:
        # Parse the callback payload
        stk_callback = callback_data.Body.get("stkCallback", {})
        checkout_request_id = stk_callback.get("CheckoutRequestID")
        result_code = stk_callback.get("ResultCode", -1)
        result_desc = stk_callback.get("ResultDesc", "Unknown error")
        
        if not checkout_request_id:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Missing CheckoutRequestID")
        
        # Process the callback
        result = PaymentService.process_stk_callback(
            db=db,
            checkout_request_id=checkout_request_id,
            result_code=result_code,
            result_desc=result_desc
        )
        
        return {"ResultCode": 0, "ResultDesc": "Callback processed successfully"}
    
    except Exception as e:
        # Always return 200 to Safaricom to prevent retries
        # Log the error internally
        print(f"Callback processing error: {e}")
        return {"ResultCode": 1, "ResultDesc": f"Processing failed: {str(e)}"}
