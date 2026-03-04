import asyncio
from datetime import datetime, timedelta
from .validator import ValidationBrain

class SimulationCoordinator:
    """The 'Brain' that manages the campaign lifecycle and time machine."""
    def __init__(self, driver, population):
        self.driver = driver
        self.pop = population
        self.brain = ValidationBrain()
        self.status_message = "Ready"
        
        self.virtual_clock = datetime.now()
        self.active_campaign = None # {id, title, current_phase, milestones}
        self.is_running = False

    async def seed_population(self, count=20):
        self.status_message = f"Provisioning {count} users..."
        added = await self.pop.seed_population(count)
        self.status_message = f"SUCCESS: {added} agents active in crowd."
        return added

    def reset_clock(self):
        self.virtual_clock = datetime.now()

    def advance_time(self, days=0, hours=0):
        self.virtual_clock += timedelta(days=days, hours=hours)
        return self.virtual_clock

    async def create_test_campaign(self, title="Simulated Project"):
        owner = self.pop.get_fundraiser()
        if not owner: 
            self.status_message = "ERROR: No fundraiser found. Run 'pop' first."
            return None
        
        data = {
            "title": title,
            "description": "System generated test campaign for Section 3.6 validation.",
            "funding_goal": 50000.0,
            "duration_months": 6,
            "campaign_type": "donation"
        }
        
        res = await self.driver.create_campaign(owner.get('access_token'), data)
        if res:
            # Ensure milestones are sorted by number to match phase indices
            raw_milestones = res.get('milestones', [])
            sorted_milestones = sorted(raw_milestones, key=lambda x: x.get('milestone_number', 0))
            
            self.active_campaign = {
                "id": res['campaign_id'],
                "title": title,
                "current_phase": 0,
                "milestones": sorted_milestones
            }
            
            # Authorization: Give all contributors a vote token for this campaign
            contributors = self.pop.get_contributors()
            auth_tasks = [self.driver.generate_vote_token(u['access_token'], res['campaign_id']) for u in contributors]
            await asyncio.gather(*auth_tasks)
            
            self.status_message = f"SUCCESS: Campaign {res['campaign_id'][:8]} created."
            return self.active_campaign
        else:
            self.status_message = "ERROR: Campaign creation failed on Backend."
            return None

    async def fund_campaign(self):
        """Simulate a funding round to reach the goal."""
        if not self.active_campaign: return False
        
        owner = self.pop.get_fundraiser()
        camp_id = self.active_campaign['id']
        
        self.status_message = "Launching campaign and funding..."
        
        # 1. Launch
        await self.driver.launch_campaign(owner['access_token'], camp_id)
        
        # 2. Contribute from all agents
        contributors = self.pop.get_contributors()
        goal = 50000.0
        share = goal / len(contributors)
        
        tasks = [self.driver.contribute(u['access_token'], camp_id, share) for u in contributors]
        await asyncio.gather(*tasks)
        
        # 3. Transition to phases
        await self.driver.transition_to_funded(owner['access_token'], camp_id)
        await self.driver.transition_to_phases(owner['access_token'], camp_id)
        
        self.status_message = "SUCCESS: Campaign reached 100% funding and entered PHASE 1."
        return True

    async def run_voting_round(self, scenario, ground_truth, ratio="75/25"):
        """Execute a full voting round based on a scenario."""
        if not self.active_campaign: 
            self.status_message = "ERROR: No active campaign."
            return "No active campaign"
        
        camp_id = self.active_campaign['id']
        current_idx = self.active_campaign['current_phase']
        if current_idx >= len(self.active_campaign['milestones']): 
            self.status_message = "ERROR: Campaign completed."
            return "Campaign Completed"
        
        milestone_id = self.active_campaign['milestones'][current_idx]['milestone_id']
        owner = self.pop.get_fundraiser()
        contributors = self.pop.get_contributors()
        
        self.status_message = f"Starting {scenario} flow for Phase {current_idx+1}..."

        # 1. Fundraiser submits evidence
        await self.driver.submit_evidence(owner['access_token'], milestone_id)
        
        # 2. Fundraiser starts voting
        await self.driver.start_voting(owner['access_token'], milestone_id)
        
        # 3. Generate voting pattern
        pattern = self.brain.get_voting_pattern(scenario, len(contributors), ratio)
        
        # 4. Cast Votes (Parallel)
        tasks = []
        # Yes votes
        for i in range(pattern['yes']):
            tasks.append(self.driver.cast_vote(contributors[i]['access_token'], milestone_id, True))
        
        # No votes
        idx_start = pattern['yes']
        for i in range(idx_start, idx_start + pattern['no']):
            tasks.append(self.driver.cast_vote(contributors[i]['access_token'], milestone_id, False))
        
        results = await asyncio.gather(*tasks)
        votes_cast = sum(1 for r in results if r)
                
        # 5. Tally Votes
        await self.driver.tally_votes(milestone_id)
        
        # 6. Decision Audit (Real system check)
        system_decision = False
        print(f"[AUDIT] Checking status for milestone {milestone_id[:8]}...", flush=True)
        for i in range(5): # Retry for DB sync
            await asyncio.sleep(1.0) 
            status = await self.driver.get_campaign_status(camp_id)
            if not status: continue
            
            # Sort milestones from API to ensure index matches
            api_milestones = sorted(status['milestones'], key=lambda x: x.get('milestone_number', 0))
            current_milestone = api_milestones[current_idx]
            current_status = current_milestone['status']
            print(f"   [AUDIT] Attempt {i+1}: Backend status is '{current_status}'", flush=True)
            
            if current_status == 'approved':
                system_decision = True
                break
            elif current_status == 'rejected':
                system_decision = False
                break
        
        judgment = self.brain.judge_decision(ground_truth, system_decision)
        self.status_message = f"JUDGMENT: {judgment} ({votes_cast} votes recorded)"
        
        if system_decision:
            self.active_campaign['current_phase'] += 1
            
        return f"Round Done: {votes_cast} votes. Result: {judgment}"
