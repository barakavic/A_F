import uuid
from decimal import Decimal
from typing import Dict, Any
from sqlalchemy.orm import Session
from app.services.contribution_service import ContributionService

class PaymentService:
    """
    Simulated M-Pesa Payment Service.
    In production, this would integrate with Safaricom Daraja API.
    """
    
    @staticmethod
    def initiate_stk_push(phone_number: str, amount: Decimal, campaign_id: uuid.UUID) -> str:
        """
        Simulate initiating an STK Push.
        Returns a mock MerchantRequestID.
        """
        # Mocking the response from Safaricom
        merchant_request_id = f"REQ-{uuid.uuid4().hex[:12].upper()}"
        print(f"[SIMULATION] STK Push initiated for {phone_number}, Amount: {amount}, Campaign: {campaign_id}")
        return merchant_request_id

    @staticmethod
    def handle_mpesa_callback(db: Session, callback_data: Dict[str, Any]):
        """
        Handle the callback from M-Pesa.
        Simulates processing a successful or failed payment.
        """
        # In a real app, callback_data would be the JSON from Safaricom
        # Example structure: {"Body": {"stkCallback": {"ResultCode": 0, "MerchantRequestID": "...", "CallbackMetadata": {...}}}}
        
        result_code = callback_data.get("ResultCode", 0)
        merchant_request_id = callback_data.get("MerchantRequestID")
        
        if result_code == 0:
            # Payment Successful
            amount = Decimal(str(callback_data.get("Amount", 0)))
            campaign_id = callback_data.get("CampaignID")
            contributor_id = callback_data.get("ContributorID")
            phone_number = callback_data.get("PhoneNumber")
            
            print(f"[SIMULATION] Payment SUCCESS for {phone_number}, Amount: {amount}")
            
            # Process the contribution in the system
            contribution_result = ContributionService.create_contribution(
                db=db,
                campaign_id=uuid.UUID(str(campaign_id)),
                contributor_id=uuid.UUID(str(contributor_id)),
                amount=float(amount),
                reference_code=f"MPESA-{uuid.uuid4().hex[:8].upper()}"
            )
            return {"status": "success", "data": contribution_result}
        else:
            # Payment Failed
            print(f"[SIMULATION] Payment FAILED with code {result_code}")
            return {"status": "failed", "error_code": result_code}
