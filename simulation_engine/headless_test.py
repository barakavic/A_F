import asyncio
import sys
import os
import logging

# Ensure simulation_engine is in the path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from drivers.api_driver import ApiDriver
from actors.population import PopulationManager
from core.coordinator import SimulationCoordinator
from utils.db_manager import ProjectCleaner

# Setup logging to see what's happening
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("HeadlessTest")

async def run_validation_cycle():
    driver = ApiDriver()
    pop = PopulationManager(driver)
    coord = SimulationCoordinator(driver, pop)
    cleaner = ProjectCleaner()

    print("--- STARTING ONE-SHOT VALIDATION CYCLE ---")
    
    # 1. Clear Database
    print("\n1. Wiping test data...")
    cleaner.drop_all_test_data()
    
    # 2. Provision Population
    print("\n2. Provisioning 20 users...")
    count = await coord.seed_population(20)
    print(f"   Result: {count} agents registered/logged-in.")
    
    # 3. Seed Campaign
    print("\n3. Creating test campaign...")
    campaign = await coord.create_test_campaign("One-Shot Validation Project")
    if not campaign:
        print("   FAILED to create campaign.")
        return
    print(f"   Result: Campaign {campaign['id'][:8]} is LIVE.")
    
    # 3.5. Fund Campaign
    print("\n3.5. Funding project (Collecting $50k)...")
    await coord.fund_campaign()
    print("\n4. Running Scenario: NORMAL (Ground Truth: VALID)...")
    result = await coord.run_voting_round("normal", True)
    print(f"   Result: {result}")
    
    # 5. Run 'Mixed' Scenario @ 60/40 (Ground Truth: INVALID)
    print("\n5. Resetting for second scenario...")
    campaign = await coord.create_test_campaign("Mixed Scenario Project")
    await coord.fund_campaign()

    print("\n6. Running Scenario: MIXED 60/40 (Ground Truth: INVALID)...")
    result = await coord.run_voting_round("mixed", False, "60/40")
    print(f"   Result: {result}")

    # 6. Final Audit Result
    print("\n" + "="*40)
    print("FINAL SECTION 3.6 METRICS")
    print("="*40)
    m = coord.brain.metrics
    print(f"TP: {m.tp} | TN: {m.tn} | FP: {m.fp} | FN: {m.fn}")
    print(f"Accuracy:  {m.accuracy:.2%}")
    print(f"Precision: {m.precision:.2%}")
    print(f"Recall:    {m.recall:.2%}")
    print(f"F1-Score:  {m.f1_score:.2%}")
    print("="*40)

if __name__ == "__main__":
    asyncio.run(run_validation_cycle())
