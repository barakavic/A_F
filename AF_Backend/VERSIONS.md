# Project Version History

## v0.1.0 - Backend Foundation Setup
**Date:** 2025-11-25
**Status:** Completed

### Added
- **Directory Structure:** Created modular `AF_Backend` architecture (app, core, api, db, models, services).
- **Configuration:**
  - `requirements.txt`: Defined Python dependencies (FastAPI, SQLAlchemy, Redis, etc.).
  - `.env`: Configured environment variables for DB, Redis, M-Pesa, and Security.
  - `docker-compose.yml`: Container orchestration for PostgreSQL, Redis, FastAPI, and pgAdmin.
  - `Dockerfile`: Python 3.10 slim image definition.
- **Core Application:**
  - `app/main.py`: Basic FastAPI entry point with CORS and Health Checks.
  - `app/core/config.py`: Pydantic-based settings management.
- **Documentation:**
  - `README.md`: Setup guide and development workflow.
  - `STRUCTURE.md`: Detailed architectural explanation.

## v0.2.0 - Core Backend Implementation
**Date:** 2025-11-29
**Status:** Completed

### Added
- **Database Layer:**
  - Implemented SQLAlchemy models for `User`, `ContributorProfile`, `FundraiserProfile`, `Campaign`, `Milestone`, `Vote`, `Escrow`.
  - Configured Alembic migrations and successfully migrated initial schema.
- **Authentication:**
  - Implemented role-based registration endpoints (`/register/contributor`, `/register/fundraiser`).
  - Added JWT token generation and password hashing (Bcrypt).
- **Risk Engine:**
  - Implemented `AlgorithmService` for Risk Factor, Alpha, and Phase Count calculations.
  - Note: Legacy FTI components were removed in subsequent versions to align with new documentation.
- **Testing:**
  - Added initial unit tests for `AlgorithmService`.

## v0.3.0 - Secure Governance & Contribution System
**Date:** 2026-01-14
**Status:** Completed

### Added
- **Legacy Cleanup:**
  - Removed all remnants of Fundraiser Trust Index (FTI) and Remedial Reserve.
  - Deleted `FundraiserCampaignHistory` and `CampaignHistory` models.
- **Campaign Management:**
  - Implemented full Campaign API (Create, List, Get).
  - Added automatic milestone deadline calculation based on seeding and active phases.
- **Contribution System:**
  - Implemented `ContributionService` for atomic pledge processing.
  - Integrated `EscrowAccount` balance tracking and `TransactionLedger` auditing.
- **Cryptographic Voting:**
  - Integrated `eth-account` for ECDSA signature verification.
  - Implemented Keccak-256 hashing for vote integrity.
  - Added **Master Waiver** functionality for passive contributors.
  - Implemented **Vote Tallying** with a strict 75% consensus threshold.
- **Testing & Quality:**
  - Expanded test suite to 11 unit tests covering all core services.
  - Created `TEST_REPORT.md` for automated verification tracking.
- **Documentation:**
  - Created `DIGITAL_SIGNATURES.md` explaining the cryptographic security model.
  - Updated `STRUCTURE.md` and `README.md` to reflect the new architecture.

### Technical Details
- **New Dependencies:** `eth-account`, `eth-utils`.
- **Security:** ECDSA (secp256k1), Keccak-256, EIP-191 message standard.
