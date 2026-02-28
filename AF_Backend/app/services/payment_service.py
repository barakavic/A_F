from sqlalchemy.orm import Session
import requests
import base64
from datetime import datetime
import uuid
from typing import Dict, Any, Optional

from app.models.campaign import Campaign
from app.models.user import User
from app.services.contribution_service import ContributionService
from app.core.redis import save_stk_session, get_stk_session, delete_stk_session
from app.core.config import settings

class PaymentService:
    @staticmethod
    def _get_mpesa_access_token() -> Optional[str]:
        """Get OAuth2 access token from Safaricom."""
        url = "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"
        if settings.MPESA_ENVIRONMENT == "production":
            url = "https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"
            
        try:
            response = requests.get(
                url, 
                auth=(settings.MPESA_CONSUMER_KEY, settings.MPESA_CONSUMER_SECRET)
            )
            response.raise_for_status()
            return response.json().get("access_token")
        except Exception as e:
            print(f"Failed to get M-Pesa token: {e}")
            return None

    @staticmethod
    def initiate_stk_push(
        db: Session,
        campaign_id: uuid.UUID,
        contributor_id: uuid.UUID,
        amount: float,
        phone_number: str
    ) -> Dict[str, Any]:
        """
        Initiate a real M-Pesa STK Push via Daraja API.
        """
        # 1. Validation
        campaign = db.query(Campaign).filter(Campaign.campaign_id == campaign_id).first()
        if not campaign or campaign.status != 'active':
            raise ValueError("Campaign not found or not active")
        
        # 2. Get Access Token
        access_token = PaymentService._get_mpesa_access_token()
        if not access_token:
            raise Exception("Could not authenticate with Safaricom Daraja API")

        # 3. Prepare STK Push Request
        timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
        password_str = f"{settings.MPESA_SHORTCODE}{settings.MPESA_PASSKEY}{timestamp}"
        password = base64.b64encode(password_str.encode()).decode()
        
        url = "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest"
        if settings.MPESA_ENVIRONMENT == "production":
            url = "https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest"

        payload = {
            "BusinessShortCode": settings.MPESA_SHORTCODE,
            "Password": password,
            "Timestamp": timestamp,
            "TransactionType": "CustomerPayBillOnline",
            "Amount": 1, # TEST MODE: Only charge 1 KES regardless of actual contribution
            "PartyA": phone_number,
            "PartyB": settings.MPESA_SHORTCODE,
            "PhoneNumber": phone_number,
            "CallBackURL": settings.MPESA_CALLBACK_URL,
            "AccountReference": f"CAF-{campaign.campaign_id.hex[:6]}",
            "TransactionDesc": f"Contribution to {campaign.title[:20]}"
        }

        headers = {"Authorization": f"Bearer {access_token}"}
        
        try:
            response = requests.post(url, json=payload, headers=headers)
            response_data = response.json()
            
            if response.status_code == 200 and response_data.get("ResponseCode") == "0":
                checkout_request_id = response_data.get("CheckoutRequestID")
                
                # Save session to Redis for callback processing
                session_data = {
                    "campaign_id": str(campaign_id),
                    "contributor_id": str(contributor_id),
                    "amount": float(amount),
                    "phone_number": phone_number
                }
                save_stk_session(checkout_request_id, session_data)
                
                return {
                    "status": "pending",
                    "checkout_request_id": checkout_request_id,
                    "message": "STK Push sent. Please check your phone for the M-Pesa prompt."
                }
            else:
                error_msg = response_data.get("errorMessage", "Unknown Daraja error")
                raise Exception(f"Safaricom rejected request: {error_msg}")
                
        except Exception as e:
            print(f"STK Push Error: {e}")
            raise e
    
    @staticmethod
    def process_stk_callback(
        db: Session,
        checkout_request_id: str,
        result_code: int,
        result_desc: str
    ) -> Dict[str, Any]:
        """
        Process the callback from M-Pesa (or simulator).
        
        Args:
            db: Database session
            checkout_request_id: The CheckoutRequestID from the original request
            result_code: 0 for success, non-zero for failure
            result_desc: Description of the result
        
        Returns:
            Dictionary with processing status
        """
        # Retrieve session from Redis
        session_data = get_stk_session(checkout_request_id)
        
        if not session_data:
            return {
                "status": "error",
                "message": "Session not found or expired"
            }
        
        try:
            if result_code == 0:
                # Success - Create the contribution
                campaign_id = uuid.UUID(session_data["campaign_id"])
                contributor_id = uuid.UUID(session_data["contributor_id"])
                amount = session_data["amount"]
                
                # This triggers the entire flow: Escrow update, Ledger entry, Vote token
                ContributionService.create_contribution(
                    db=db,
                    campaign_id=campaign_id,
                    contributor_id=contributor_id,
                    amount=amount
                )
                
                # Clean up Redis session
                delete_stk_session(checkout_request_id)
                
                return {
                    "status": "success",
                    "message": "Payment processed successfully"
                }
            else:
                # Failure - Log and clean up
                print(f"Payment failed: {result_desc}")
                delete_stk_session(checkout_request_id)
                
                return {
                    "status": "failed",
                    "message": f"Payment failed: {result_desc}"
                }
        except Exception as e:
            # Clean up even on error
            delete_stk_session(checkout_request_id)
            raise e
