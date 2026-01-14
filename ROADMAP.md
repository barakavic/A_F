# Ascent_Fin Project Roadmap

This document outlines the remaining tasks and the strategic approach for completing the Ascent_Fin crowdfunding platform.

## Phase 1: Backend API Completion & Core Logic
**Objective**: Finalize all business logic and expose it via secure REST endpoints.

### 1.1 Campaign Management
- [ ] **Endpoint Integration**: Connect `CampaignService` to `/api/v1/campaigns` routes.
- [ ] **Seeding Phase Logic**: Implement automatic date calculation for the seeding phase and subsequent milestones.
- [ ] **Validation**: Ensure campaign creation enforces risk bounds (C, P, Alpha).

### 1.2 Contribution & Voting System
- [ ] **Contribution Flow**: Implement `/api/v1/contributions` to handle pledges.
- [ ] **Vote Token Generation**: Automatically generate unique `VoteToken` entries upon successful contribution.
- [ ] **Digital Signatures**: Implement Keccak-256 hashing and signature verification for milestone approval.
- [ ] **Vote Tallying**: Build the background logic to check for 75% quorum and trigger fund release.
- [ ] **Vote Waiving**: Implement logic to allow contributors to pre-approve all milestones.

### 1.3 Financial Operations (Simulated Escrow)
- [ ] **Escrow Service**: Build logic to track "Held", "Released", and "Refunded" states per campaign.
- [ ] **M-Pesa Integration**: 
    - Implement STK Push for contributions.
    - Implement B2C for fund release to fundraisers.
    - Handle Daraja API callbacks and update `TransactionLedger`.
- [ ] **Refund Mechanism**: Automate refunds to contributors if a milestone fails the 75% vote threshold.

---

## Phase 2: Frontend Integration & UI Development
**Objective**: Connect the Flutter application to the backend and provide a premium user experience.

### 2.1 API Client & Auth
- [ ] **Dio/HTTP Setup**: Implement a robust API client with interceptors for JWT handling.
- [ ] **Auth Flow**: Connect Login/Signup screens to backend endpoints.

### 2.2 Fundraiser Experience
- [ ] **Campaign Wizard**: A multi-step form for creating campaigns with real-time algorithm previews.
- [ ] **Dashboard**: Track funding progress, upload milestone evidence, and view disbursement history.

### 2.3 Contributor Experience
- [ ] **Discovery**: Search and filter active campaigns.
- [ ] **Voting Portal**: Review milestone evidence and cast cryptographically signed votes.
- [ ] **Portfolio**: View active contributions and total impact.

---

## Phase 3: Testing, Security & Deployment
**Objective**: Ensure system stability and prepare for production.

### 3.1 Comprehensive Testing
- [ ] **Integration Tests**: End-to-end testing of the Contribution -> Voting -> Release flow.
- [ ] **Load Testing**: Ensure the voting engine handles concurrent submissions.

### 3.2 Security & Optimization
- [ ] **Rate Limiting**: Protect API endpoints from abuse.
- [ ] **Audit Logging**: Ensure every financial and voting event is logged in `TransactionLedger`.
- [ ] **HTTPS/SSL**: Configure secure communication.

### 3.3 Deployment
- [ ] **Production DB**: Set up a managed PostgreSQL instance.
- [ ] **CI/CD**: Automate testing and deployment via GitHub Actions or similar.

---

## Technical Approach

### Voting Integrity
We use **Keccak-256** hashing. When a contributor votes, their device signs a payload (CampaignID + MilestoneID + Vote + Nonce). The backend verifies this against the stored Public Key in the `VoteToken`. This ensures votes cannot be tampered with by the platform or the fundraiser.

### Phased Fund Release
Funds are never released in bulk. The `AlgorithmService` determines the number of phases ($P$) and weights ($W_i$). The system only triggers an M-Pesa B2C transaction when the `VotingService` confirms a 75% "Yes" consensus for the current milestone.

### M-Pesa Simulation
During development, we use the Daraja Sandbox. The `PaymentService` is designed to be swappable, allowing us to move from simulation to production by simply updating environment variables.
