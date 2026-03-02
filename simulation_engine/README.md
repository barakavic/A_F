# Ascent_Fin Simulation Engine

A robust simulation engine for the Ascent_Fin platform. It allows for simulating campaign lifecycles, contributor behaviors (including COM/AI contributors), and various ecosystem events.

## Features
- **Campaign Lifecycle Simulation**: From draft to completion/failure.
- **Agent-based Modeling**: 
    - `HumanContributor`: Mimics real-user contribution patterns.
    - `COMContributor`: Scripted/Randomized contributions for testing high-load and edge cases.
    - `FundraiserActor`: Automatically submits milestones and evidence.
- **Event-Driven Architecture**: Simulate external events like M-Pesa callbacks, admin approvals, or project delays.
- **Timeline Management**: Accelerate or decelerate simulation time.
- **Interactive TUI**: A terminal-based dashboard with real-time stats and management commands.

## Architecture
- `core/`: Simulation loop, time manager, and event dispatcher.
- `agents/`: Definitions for human, COM, and fundraiser agents.
- `models/`: Simulation-specific data models.
- `config/`: Simulation parameters (e.g., contribution frequency, failure rates).

## Integration & Running
The simulation engine is integrated into the `AF_Backend` Docker environment.

### Running with Docker Compose
From the `AF_Backend` directory, you can start the simulator alongside the rest of the stack:

```bash
docker compose up -d
docker attach ascent_fin_simulator
```

### Clean Slate Feature
Within the TUI, you can use the `drop` command to clear all simulated campaigns and start with a clean state.

### Commands
- `drop`: Clear simulation state (remove all campaigns/events).
- `stop`: Stop the simulation loop.
- `help`: Show available commands.
- `exit`: Quit the simulation engine.
