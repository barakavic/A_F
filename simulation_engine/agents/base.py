from abc import ABC, abstractmethod
import uuid
import logging

logger = logging.getLogger("SimulationAgent")

class BaseAgent(ABC):
    def __init__(self, name: str, agent_type: str = "base"):
        self.id = str(uuid.uuid4())
        self.name = name
        self.type = agent_type
        self.state = {}

    @abstractmethod
    async def act(self, sim_state):
        """Perform an action in the simulation based on the current state."""
        pass

    def __repr__(self):
        return f"<{self.type.capitalize()} Agent: {self.name} ({self.id[:8]})>"
