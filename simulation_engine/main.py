import asyncio
import logging
import sys
import os
from datetime import datetime

# Set up logging to a file
logging.basicConfig(
    filename='simulation.log',
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# Fix Paths for Docker/Local
sim_root = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(sim_root) # Ascent_Fin root

if project_root not in sys.path:
    sys.path.append(project_root)
if sim_root not in sys.path:
    sys.path.append(sim_root)

# Correct the backend path specifically for the 'app' module
backend_path = os.path.join(project_root, "AF_Backend")
if os.path.exists(backend_path) and backend_path not in sys.path:
    sys.path.append(backend_path)

from core.engine import SimulationEngine
from agents.com_contributor import COMContributor
from agents.fundraiser_actor import FundraiserActor
from utils.db_manager import DbManager

# UI Imports
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from prompt_toolkit import PromptSession
from prompt_toolkit.patch_stdout import patch_stdout

console = Console()

def print_dashboard(engine: SimulationEngine):
    """Prints a static version of the dashboard."""
    m = engine.state.metrics
    
    # Header
    console.print(Panel(
        f"[bold white]Ascent_Fin Simulation Oversight[/bold white]\n"
        f"Time: {engine.state.current_time.strftime('%Y-%m-%d %H:%M:%S')} | Status: [green]RUNNING[/green]",
        style="blue"
    ))

    # Metrics (Section 3.6)
    metrics_table = Table(title="Evaluation Metrics (Section 3.6)")
    metrics_table.add_column("Metric", style="cyan")
    metrics_table.add_column("Value", style="bold yellow")
    
    metrics_table.add_row("True Positives (TP)", str(m.tp))
    metrics_table.add_row("False Positives (FP)", str(m.fp))
    metrics_table.add_row("Accuracy", f"{m.accuracy:.1%}")
    metrics_table.add_row("F1-Score", f"{m.f1_score:.1%}")
    console.print(metrics_table)

    # Campaigns
    camp_table = Table(title="Active Campaigns")
    camp_table.add_column("ID (Short)")
    camp_table.add_column("Title")
    camp_table.add_column("Goal")
    camp_table.add_column("Status")
    camp_table.add_column("Phases")

    for cid, camp in list(engine.state.campaigns.items())[:8]:
        camp_table.add_row(
            cid[:5],
            camp['title'][:20],
            f"${camp['funding_goal']:,.0f}",
            camp['status'],
            str(camp.get('current_phase', 0))
        )
    console.print(camp_table)
    console.print("\n[dim]Commands: advance [id] [scenario] | drop | exit | help[/dim]\n")

async def main():
    # DB Connection
    db_mgr = None
    try:
        db_mgr = DbManager()
    except Exception as e:
        logger = logging.getLogger("Main")
        logger.error(f"DB Connection failed: {e}")

    engine = SimulationEngine(time_scale=3600.0, db_manager=db_mgr)
    
    # Add a Tutorial Campaign immediately so the user doesn't have an empty table
    engine.state.campaigns["tutorial-101"] = {
        "campaign_id": "tutorial-101",
        "title": "Tutorial-Project",
        "description": "A pre-loaded project for evaluation testing.",
        "funding_goal": 25000,
        "total_contributions": 25000,
        "status": "active",
        "current_phase": 0
    }
    
    # Initial Agents
    engine.add_agent(FundraiserActor("Alpha_Actor", create_campaign_probability=0.04))
    engine.add_agent(COMContributor("Donor_1", contribution_probability=0.1))
    
    # Start simulation loop in background
    sim_task = asyncio.create_task(engine.run(duration_days=30))
    
    session = PromptSession()
    
    # Show initial dashboard
    print_dashboard(engine)

    while True:
        with patch_stdout():
            try:
                # Prompt for command
                command = await session.prompt_async("Oversight >> ")
                command = command.strip().lower()

                if not command:
                    # Just pressing enter refreshes the view
                    print_dashboard(engine)
                    continue

                if command == 'exit':
                    engine.stop()
                    break
                elif command == 'drop':
                    engine.clear_state()
                    console.print("[bold red]Database and simulation state wiped.[/bold red]")
                elif command.startswith('advance'):
                    parts = command.split()
                    if len(parts) < 3:
                        console.print("[red]Usage: advance <id> <scenario>[/red]")
                    else:
                        target_id = parts[1]
                        scenario = parts[2]
                        match = [cid for cid in engine.state.campaigns.keys() if cid.startswith(target_id)]
                        if match:
                            ground_truth = "fail" not in scenario.lower()
                            await engine.advance_campaign(match[0], scenario, ground_truth)
                            console.print(f"[green]Executed {scenario} on {target_id}[/green]")
                        else:
                            console.print(f"[red]Campaign {target_id} not found.[/red]")
                elif command == 'help':
                    console.print("Commands: advance, drop, exit, help, or press Enter to refresh.")
                else:
                    console.print(f"[yellow]Unknown: {command}[/yellow]")
                
                # Update visual after any command
                print_dashboard(engine)

            except EOFError:
                break
            except Exception as e:
                console.print(f"[bold red]Error: {e}[/bold red]")

    sim_task.cancel()
    console.print("Oversight Dashboard closed.")

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
