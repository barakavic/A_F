from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
try:
    from app.core.config import settings
except ImportError:
    # Fallback for local development if needed
    from AF_Backend.app.core.config import settings
import logging

logger = logging.getLogger("DbManager")

class DbManager:
    def __init__(self):
        # When running in Docker, DATABASE_URL should point to the 'postgres' service
        # If running locally, it might need 'localhost'
        db_url = settings.DATABASE_URL
        if "postgres" not in db_url and "localhost" in db_url:
             # Heuristic: if we are in a container, 'localhost' won't work for reaching other containers
             # This is just a fallback, usually env vars handle this
             pass
             
        self.engine = create_engine(db_url)
        self.SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)

    def get_session(self):
        return self.SessionLocal()

    def clear_all_data(self):
        """Truncate all relevant tables for a clean slate."""
        session = self.get_session()
        try:
            # Order matters for foreign keys
            tables = [
                "vote_submission", "vote_result", "vote_token",
                "milestone_evidence", "milestone",
                "transaction_ledger", "contribution", "fund_release", "refund_event",
                "escrow_account", "campaign"
            ]
            for table in tables:
                session.execute(text(f"TRUNCATE TABLE {table} CASCADE;"))
            session.commit()
            logger.info("Database tables truncated successfully.")
        except Exception as e:
            session.rollback()
            logger.error(f"Failed to truncate tables: {e}")
        finally:
            session.close()
