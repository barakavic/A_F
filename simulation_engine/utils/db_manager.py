import os
import psycopg2

class ProjectCleaner:
    """Utility to 'Drop' test data and reset the simulation workspace."""
    def __init__(self):
        self.db_url = os.getenv("DATABASE_URL", "postgresql://ascent_user:ascent_password@postgres:5432/ascent_fin_db")

    def drop_all_test_data(self):
        """Truncate specific tables to clear simulation history."""
        try:
            conn = psycopg2.connect(self.db_url)
            cur = conn.cursor()
            
            # Using actual table names from the SQLAlchemy models
            tables = [
                "vote_submission", "vote_token", "vote_result",
                "milestone_evidence", "fund_release", "refund_event",
                "milestone", "escrow_account", "campaign",
                "contributor_profile", "fundraiser_profile", "account"
            ]
            
            print(f"DEBUG: Attempting to truncate {len(tables)} tables...")
            for table in tables:
                try:
                    cur.execute(f"TRUNCATE TABLE {table} CASCADE;")
                except Exception as e:
                    print(f"   Skipping {table}: {str(e).splitlines()[0]}")
                    conn.rollback() # Continue with others
                
            conn.commit()
            cur.close()
            conn.close()
            return True
        except Exception as e:
            print(f"Cleanup failed: {e}")
            return False
