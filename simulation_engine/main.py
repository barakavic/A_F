import asyncio
import sys
import os

# Ensure simulation_engine is in the path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import aioconsole
import logging
from drivers.api_driver import ApiDriver
from actors.population import PopulationManager
from core.coordinator import SimulationCoordinator
from core.interface import WindowedInterface
from utils.db_manager import ProjectCleaner

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
    handlers=[
        logging.FileHandler("/app/simulation_engine/sim_debug.log"),
    ]
)
log = logging.getLogger("Simulator")

async def main():
    driver = ApiDriver()
    pop = PopulationManager(driver)
    coord = SimulationCoordinator(driver, pop)
    ui = WindowedInterface(coord)
    cleaner = ProjectCleaner()

    while True:
        ui.refresh()
        cmd_raw = await aioconsole.ainput("\n (SIM) > ")
        cmd_parts = cmd_raw.strip().split()
        
        if not cmd_parts:
            continue
            
        cmd = cmd_parts[0].lower()
        
        if cmd == "exit":
            print("Shutting down simulation...")
            break
            
        elif cmd == "pop":
            count = int(cmd_parts[1]) if len(cmd_parts) > 1 else 10
            await coord.seed_population(count)
            
        elif cmd == "seed":
            print("Creating test campaign...")
            await coord.create_test_campaign()
            
        elif cmd == "jump":
            days = int(cmd_parts[1]) if len(cmd_parts) > 1 else 1
            coord.advance_time(days=days)
            
        elif cmd == "vote":
            # Usage: vote scenario gt [ratio]
            if len(cmd_parts) < 3:
                print("Error: Too few arguments. Use: vote scenario gt [ratio]")
                await asyncio.sleep(2)
                continue
                
            scenario = cmd_parts[1]
            gt = True if cmd_parts[2].lower() in ['y', 'yes', 'true'] else False
            ratio = cmd_parts[3] if len(cmd_parts) > 3 else "75/25"
            
            print(f"Injecting {scenario} votes (Ground Truth: {gt})...")
            result = await coord.run_voting_round(scenario, gt, ratio)
            print(result)
            await asyncio.sleep(2)

        elif cmd == "drop":
            print("Wiping all test data. Please wait...")
            if cleaner.drop_all_test_data():
                print("SUCCESS: System reset.")
                coord.active_campaign = None
                pop.users = []
            else:
                print("FAILURE: System reset failed.")
            await asyncio.sleep(2)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
