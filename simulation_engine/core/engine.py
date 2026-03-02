from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional
import uuid
from datetime import datetime, timedelta
import logging
import httpx # For calling the real backend API

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("SimulationEngine")

class EvaluationMetrics(BaseModel):
    tp: int = 0
    fp: int = 0
    fn: int = 0
    tn: int = 0

    @property
    def accuracy(self):
        total = self.tp + self.tn + self.fp + self.fn
        return (self.tp + self.tn) / total if total > 0 else 0

    @property
    def precision(self):
        den = self.tp + self.fp
        return self.tp / den if den > 0 else 0

    @property
    def recall(self):
        den = self.tp + self.fn
        return self.tp / den if den > 0 else 0

    @property
    def f1_score(self):
        p = self.precision
        r = self.recall
        return 2 * (p * r) / (p + r) if (p + r) > 0 else 0

class SimulationState(BaseModel):
    simulation_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    start_time: datetime = Field(default_factory=datetime.utcnow)
    current_time: datetime = Field(default_factory=datetime.utcnow)
    time_scale: float = 1.0 
    is_running: bool = False
    campaigns: Dict[str, Any] = {}
    events: List[Any] = []
    metrics: EvaluationMetrics = Field(default_factory=EvaluationMetrics)

class SimulationEngine:
    def __init__(self, time_scale: float = 3600.0, db_manager=None):
        self.state = SimulationState(time_scale=time_scale)
        self.agents = []
        self.db_manager = db_manager
        self.api_url = "http://api:8000/api/v1" # Docker-compose service name

    def add_agent(self, agent):
        self.agents.append(agent)
        logger.info(f"Added agent: {agent.name}")

    def clear_state(self):
        self.state.campaigns = {}
        self.state.events = []
        self.state.metrics = EvaluationMetrics()
        if self.db_manager:
            self.db_manager.clear_all_data()
        logger.info("Simulation state and Database cleared (Clean Slate).")

    async def advance_campaign(self, campaign_id: str, scenario: str, ground_truth: bool):
        """Advances the next milestone of a campaign using a specific evaluation scenario."""
        campaign = self.state.campaigns.get(campaign_id)
        if not campaign:
            return

        # Simple simulation logic for a single "Phase" (Milestone)
        current_phase = campaign.get('current_phase', 0) + 1
        campaign['current_phase'] = current_phase
        
        # Scenario-based voting probabilities
        p_yes = 0.9 if scenario == "normal" else 0.5 if scenario == "mixed" else 0.1 if scenario == "incorrect" else 0.0
        p_vote = 1.0 if scenario != "missing" else 0.5
        
        num_voters = 10 
        yes_votes = 0
        total_votes = 0
        
        import random
        for _ in range(num_voters):
            if random.random() < p_vote:
                total_votes += 1
                if random.random() < p_yes:
                    yes_votes += 1

        # Decision threshold (from your document: 75%)
        approval_pct = (yes_votes / total_votes) if total_votes > 0 else 0
        system_decision = approval_pct >= 0.75

        # Update Evaluation Metrics based on Section 3.6
        if ground_truth and system_decision:
            self.state.metrics.tp += 1
        elif not ground_truth and system_decision:
            self.state.metrics.fp += 1
        elif ground_truth and not system_decision:
            self.state.metrics.fn += 1
        elif not ground_truth and not system_decision:
            self.state.metrics.tn += 1

        logger.info(f"Campaign {campaign_id[:5]} Phase {current_phase} Advanced. Scenario: {scenario}. Approval: {approval_pct:.1%}. System Decision: {system_decision}. Ground Truth: {ground_truth}")
        
        self.state.events.append({
            "type": "phase_advanced",
            "campaign_id": campaign_id,
            "phase": current_phase,
            "scenario": scenario,
            "decision": "approved" if system_decision else "rejected",
            "timestamp": self.state.current_time
        })
        
    async def run(self, duration_days: int = 30):
        self.state.is_running = True
        end_time = self.state.start_time + timedelta(days=duration_days)
        
        while self.state.current_time < end_time and self.state.is_running:
            sim_tick_hours = 1 
            self.state.current_time += timedelta(hours=sim_tick_hours)
            
            real_sleep = (sim_tick_hours * 3600) / self.state.time_scale
            await self.process_tick()
            
            if real_sleep > 0:
                await asyncio.sleep(real_sleep)

        self.state.is_running = False

    async def process_tick(self):
        for agent in self.agents:
            await agent.act(self.state)
            
    def stop(self):
        self.state.is_running = False
