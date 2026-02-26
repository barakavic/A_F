import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.session import SessionLocal
from app.models.user import User, FundraiserProfile
from app.services.campaign_service import CampaignService
import time
import uuid

def load_test():
    db = SessionLocal()
    print("Starting Batch Load Test (50 Campaigns)...")
    
    start_time = time.time()
    
    try:
        # Create a fundraiser
        email = f"loadtest_{uuid.uuid4().hex[:6]}@example.com"
        user = User(email=email, password_hash="pw", role='fundraiser', is_active=True)
        db.add(user)
        db.flush()
        profile = FundraiserProfile(fundraiser_id=user.account_id, company_name="LoadTest Corp")
        db.add(profile)
        db.flush()

        for i in range(50):
            CampaignService.create_campaign(
                db=db, fundraiser_id=user.account_id,
                title=f"Bulk Project {i+1}", description="Load testing campaign creation.",
                funding_goal=1000 * (i+1), duration_months=12, campaign_type='donation'
            )
            if (i+1) % 10 == 0:
                print(f"Created {i+1} projects...")
        
        db.commit()
        end_time = time.time()
        
        print("\nLoad Test Finished!")
        print(f"Total Time for 50 campaigns: {end_time - start_time:.2f}s")
        print(f"Average time per campaign: {(end_time - start_time)/50:.4f}s")

    except Exception as e:
        print(f" Load Test Failed: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    load_test()
