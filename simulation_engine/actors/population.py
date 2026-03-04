import random

class PopulationManager:
    """Manages synthetic users and their lifecycle profiles."""
    def __init__(self, driver):
        self.driver = driver
        self.users = [] # List of {email, password, token, role, account_id}
        
        # Predefined data pool
        self.first_names = ["James", "Mary", "Robert", "Patricia", "John", "Jennifer", "Michael", "Linda"]
        self.last_names = ["Mulei", "Otieno", "Wanjiku", "Njoroge", "Kamau", "Ochieng", "Maina", "Mutua"]
        self.domains = ["sim.ascent.com", "test.fin.ke", "lab.node.io"]

    def generate_random_user(self, index, role="contributor"):
        # Deterministic choice based on index to avoid random email/uname mismatches
        f = self.first_names[index % len(self.first_names)]
        l = self.last_names[index % len(self.last_names)]
        uname = f"{f.lower()}.{l.lower()}.{index}"
        domain = "sim.ascent.com" # Fixed domain for consistency
        email = f"{uname}@{domain}"
        password = "Password123!"
        
        data = {
            "email": email,
            "password": password,
            "role": role
        }
        
        if role == "contributor":
            data.update({
                "uname": uname,
                "phone_number": f"+254700{index:06d}",
                "public_key": f"0xSimulatedKey{index:08d}"
            })
        else:
            data.update({
                "company_name": f"{f} {l} Ventures",
                "br_number": f"BN-{index:05d}",
                "industry_l1_id": "11111111-1111-1111-1111-111111111111",
                "industry_l2_id": None
            })
        return data

    async def seed_population(self, count=20):
        """Register and login a batch of users. Handles existing users gracefully."""
        self.users = []
        # 1. Register a Lead Fundraiser
        owner_data = self.generate_random_user(0, role="fundraiser")
        res = await self.driver.register_user(owner_data)
        
        # Attempt login
        auth = await self.driver.login(owner_data['email'], owner_data['password'])
        if isinstance(auth, dict) and 'access_token' in auth:
            owner_data.update(auth)
            self.users.append(owner_data)
        
        # 2. Register Contributors
        for i in range(1, count + 1):
            u_data = self.generate_random_user(i, role="contributor")
            await self.driver.register_user(u_data)
            auth = await self.driver.login(u_data['email'], u_data['password'])
            if isinstance(auth, dict) and 'access_token' in auth:
                u_data.update(auth)
                self.users.append(u_data)
        
        return len(self.users)

    def get_fundraiser(self):
        return next((u for u in self.users if u['role'] == 'fundraiser'), None)

    def get_contributors(self):
        return [u for u in self.users if u['role'] == 'contributor']
