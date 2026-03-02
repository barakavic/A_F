from .base import BaseAgent
import random
import logging
from datetime import datetime

logger = logging.getLogger("COMContributor")

class COMContributor(BaseAgent):
    def __init__(self, name: str, min_contribution: float = 10.0, max_contribution: float = 500.0, contribution_probability: float = 0.05):
        super().__init__(name, agent_type="com_contributor")
        self.min_contribution = min_contribution
        self.max_contribution = max_contribution
        self.contribution_probability = contribution_probability

    async def act(self, sim_state):
        """Randomly decide to contribute to an active campaign."""
        # Simple probability check per tick
        if random.random() < self.contribution_probability:
            # Pick a random active campaign from the simulation state
            active_campaigns = [cid for cid, c in sim_state.campaigns.items() if c['status'] == 'active']
            
            if not active_campaigns:
                return

            campaign_id = random.choice(active_campaigns)
            amount = round(random.uniform(self.min_contribution, self.max_contribution), 2)
            
            # Record the contribution in the simulation (placeholder for actual API call later)
            logger.info(f"Agent {self.name} contributing {amount} to campaign {campaign_id}")
            
            # Update simulation state
            sim_state.campaigns[campaign_id]['total_contributions'] += amount
            
            # Record events
            sim_state.events.append({
                "type": "contribution",
                "agent_id": self.id,
                "agent_name": self.name,
                "campaign_id": campaign_id,
                "amount": amount,
                "timestamp": sim_state.current_time
            })
