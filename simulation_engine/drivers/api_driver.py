import httpx
import logging
import os

class ApiDriver:
    """Loosely coupled driver to talk to the Backend API."""
    def __init__(self, base_url=None):
        # Using service name 'api' instead of container name for docker networking
        self.base_url = base_url or os.getenv("API_URL", "http://api:8000/api/v1")
        self.client = httpx.AsyncClient(timeout=30.0)
        self.log = logging.getLogger("ApiDriver")

    async def register_user(self, data):
        """Register a new user (contributor or fundraiser)."""
        role = data.get('role', 'contributor')
        path = f"/auth/register/{role}"
        try:
            resp = await self.client.post(f"{self.base_url}{path}", json=data)
            if resp.status_code >= 400:
                return {"error": resp.json().get('detail', 'Unknown error'), "status_code": resp.status_code}
            return resp.json()
        except Exception as e:
            return {"error": str(e)}

    async def login(self, username, password):
        """Get access token for a user."""
        try:
            resp = await self.client.post(
                f"{self.base_url}/auth/login",
                data={"username": username, "password": password}
            )
            if resp.status_code != 200:
                # print(f"DEBUG: Login failed for {username}: {resp.text}")
                return {"error": resp.json().get('detail', 'Login failed'), "status_code": resp.status_code}
            return resp.json()
        except Exception as e:
            return {"error": str(e)}

    async def create_campaign(self, token, data):
        """Create a new campaign."""
        headers = {"Authorization": f"Bearer {token}"}
        try:
            resp = await self.client.post(f"{self.base_url}/campaigns/", json=data, headers=headers)
            return resp.json() if resp.status_code < 400 else None
        except Exception as e:
            return None

    async def launch_campaign(self, token, campaign_id):
        """Moves campaign from draft to active."""
        headers = {"Authorization": f"Bearer {token}"}
        try:
            resp = await self.client.post(f"{self.base_url}/campaigns/{campaign_id}/launch", headers=headers)
            return resp.status_code < 400
        except Exception:
            return False

    async def transition_to_funded(self, token, campaign_id):
        """Moves campaign to funded status."""
        headers = {"Authorization": f"Bearer {token}"}
        try:
            resp = await self.client.post(f"{self.base_url}/campaigns/{campaign_id}/funded", headers=headers)
            return resp.status_code < 400
        except Exception:
            return False

    async def transition_to_phases(self, token, campaign_id):
        """Moves campaign to in_phases status and activates first milestone."""
        headers = {"Authorization": f"Bearer {token}"}
        try:
            resp = await self.client.post(f"{self.base_url}/campaigns/{campaign_id}/start-phases", headers=headers)
            return resp.status_code < 400
        except Exception:
            return False

    async def contribute(self, token, campaign_id, amount):
        """Pledge a contribution to a campaign."""
        headers = {"Authorization": f"Bearer {token}"}
        data = {"campaign_id": str(campaign_id), "amount": float(amount)}
        try:
            resp = await self.client.post(f"{self.base_url}/contributions/", json=data, headers=headers)
            return resp.status_code < 400
        except Exception:
            return False

    async def submit_evidence(self, token, milestone_id, description="Simulated evidence"):
        """Fundraiser submits evidence for a milestone."""
        headers = {"Authorization": f"Bearer {token}"}
        # Note: Backend uses Form data for this endpoint
        data = {"description": description}
        try:
            resp = await self.client.post(f"{self.base_url}/milestones/{milestone_id}/submit-evidence", data=data, headers=headers)
            return resp.status_code < 400
        except Exception:
            return False

    async def start_voting(self, token, milestone_id):
        """Fundraiser starts the voting period."""
        headers = {"Authorization": f"Bearer {token}"}
        try:
            resp = await self.client.post(f"{self.base_url}/milestones/{milestone_id}/start-voting", headers=headers)
            return resp.status_code < 400
        except Exception:
            return False

    async def generate_vote_token(self, token, campaign_id):
        """Contributor generates a vote token for a campaign."""
        headers = {"Authorization": f"Bearer {token}"}
        try:
            resp = await self.client.post(f"{self.base_url}/votes/token/{campaign_id}", headers=headers)
            return resp.status_code < 400
        except Exception:
            return False

    async def cast_vote(self, token, milestone_id, vote_value):
        """Submit a vote for a milestone."""
        headers = {"Authorization": f"Bearer {token}"}
        # Matches app.api.endpoints.votes.VoteSubmit
        data = {
            "milestone_id": str(milestone_id),
            "vote_value": "yes" if vote_value else "no",
            "signature": "0x_MOCKED_SIGNATURE_FOR_DEMO",
            "nonce": "sim_nonce_123"
        }
        try:
            resp = await self.client.post(f"{self.base_url}/votes/submit", json=data, headers=headers)
            # if resp.status_code >= 400:
            #     print(f"DEBUG: Vote failed ({resp.status_code}): {resp.text}")
            return resp.status_code < 400
        except Exception:
            return False

    async def tally_votes(self, milestone_id):
        """Tally votes for a milestone."""
        try:
            resp = await self.client.post(f"{self.base_url}/votes/tally/{milestone_id}")
            return resp.json() if resp.status_code < 400 else None
        except Exception:
            return None

    async def get_campaign_status(self, campaign_id):
        """Fetch current status of a campaign."""
        try:
            resp = await self.client.get(f"{self.base_url}/campaigns/{campaign_id}")
            return resp.json() if resp.status_code == 200 else None
        except Exception:
            return None
