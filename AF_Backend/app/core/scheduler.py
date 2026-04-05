from apscheduler.schedulers.asyncio import AsyncIOScheduler
from app.tasks.campaign_monitor import check_funding_deadlines, check_voting_deadlines
from app.db.session import SessionLocal
import logging
import os

os.makedirs("logs", exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[
        logging.FileHandler("logs/automation.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("automation")

scheduler = AsyncIOScheduler()

def run_funding_check():
    db = SessionLocal()
    try:
        logger.info("CRON: Starting funding deadline check...")
        check_funding_deadlines(db)
        logger.info("CRON: Funding deadline check completed.")
    except Exception as e:
        logger.error(f"CRON_ERROR: Funding check failed: {str(e)}")
    finally:
        db.close()

def run_voting_check():
    db = SessionLocal()
    try:
        logger.info("CRON: Starting voting deadline check...")
        check_voting_deadlines(db)
        logger.info("CRON: Voting deadline check completed.")
    except Exception as e:
        logger.error(f"CRON_ERROR: Voting check failed: {str(e)}")
    finally:
        db.close()

def start_scheduler():
    scheduler.add_job(run_funding_check, 'interval', hours=1, id='funding_monitor')
    scheduler.add_job(run_voting_check, 'interval', hours=1, id='voting_monitor')
    
    scheduler.add_job(run_funding_check, 'date', run_date=None, id='funding_monitor_startup')
    scheduler.add_job(run_voting_check, 'date', run_date=None, id='voting_monitor_startup')
    
    scheduler.start()
    logger.info("Automation Scheduler started - monitoring every hour.")

def stop_scheduler():
    scheduler.shutdown()
    logger.info("Automation Scheduler stopped.")
