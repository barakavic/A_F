# Backend Directory Structure Documentation

## Directory Purposes

### `/app` - Main Application Code
Core application logic and API implementation.

#### `/app/api` - API Layer
- **`/endpoints`** - Route handlers organized by resource (campaigns, users, votes, etc.)
- **`/dependencies`** - Dependency injection functions (authentication, database sessions, permissions)

#### `/app/core` - Core Configuration
- **Purpose**: Application settings, security configurations, constants
- **Files**: `config.py`, `security.py`, `constants.py`

#### `/app/db` - Database Layer
- **Purpose**: Database connection, session management, base classes
- **Files**: `base.py`, `session.py`, `init_db.py`

#### `/app/models` - SQLAlchemy ORM Models
- **Purpose**: Database table definitions
- **Files**: `user.py`, `campaign.py`, `milestone.py`, `vote.py`, `escrow.py`, `transaction.py`

#### `/app/schemas` - Pydantic Schemas
- **Purpose**: Request/response validation and serialization
- **Files**: `user.py`, `campaign.py`, `milestone.py`, `vote.py`, `contribution.py`

#### `/app/services` - Business Logic Layer
- **Purpose**: Core business logic separated from API routes
- **Files**: 
  - `campaign_service.py` - Campaign CRUD and algorithms
  - `voting_service.py` - Vote validation and tallying
  - `escrow_service.py` - Fund management logic
  - `payment_service.py` - M-Pesa integration
  - `algorithm_service.py` - Risk Factor, Alpha, and Phase Count calculations

#### `/app/utils` - Utility Functions
- **Purpose**: Helper functions and shared utilities
- **Files**:
  - `keccak.py` - Keccak-256 hashing
  - `validators.py` - Custom validators
  - `formatters.py` - Data formatting
  - `file_handler.py` - File upload/storage

---

### `/alembic` - Database Migrations
- **Purpose**: Version control for database schema changes
- **`/versions`** - Individual migration files

---

### `/scripts` - Utility Scripts
- **Purpose**: Development and deployment helpers
- **Examples**:
  - `seed_db.py` - Populate test data
  - `reset_db.py` - Reset database
  - `generate_tokens.py` - Generate test vote tokens

---

### `/tests` - Test Suite
- **`/unit`** - Unit tests for individual functions/classes
- **`/integration`** - End-to-end API tests

---

## Root Files (To Be Created)

- **`.env`** - Environment variables (secrets, DB credentials) - **NOT committed to Git**
- **`.env.example`** - Template for environment variables
- **`.gitignore`** - Files to exclude from version control
- **`requirements.txt`** - Python dependencies
- **`Dockerfile`** - Docker image definition
- **`docker-compose.yml`** - Multi-container setup (API + PostgreSQL + Redis)
- **`alembic.ini`** - Alembic configuration
- **`main.py`** - Application entry point

---

## Planned File Organization

### API Endpoints Structure
```
/app/api/endpoints/
├── auth.py           # Login, register, token refresh
├── users.py          # User profile management
├── campaigns.py      # Campaign CRUD
├── contributions.py  # Pledge/contribute to campaigns
├── milestones.py     # Milestone management
├── votes.py          # Vote submission and results
├── escrow.py         # Escrow status queries
└── payments.py       # M-Pesa callbacks
```

### Models Structure
```
/app/models/
├── user.py           # User, Fundraiser, Contributor
├── campaign.py       # Campaign, CampaignHistory
├── milestone.py      # Milestone
├── contribution.py   # Contribution
├── vote.py           # VoteToken, VoteSubmission, VoteResult
├── escrow.py         # EscrowLedger
└── transaction.py    # TransactionLedger
```

---

## Design Principles

1. **Separation of Concerns**
   - Routes (endpoints) handle HTTP
   - Services handle business logic
   - Models handle data persistence

2. **Dependency Injection**
   - Database sessions injected via dependencies
   - Authentication handled via dependencies

3. **Testability**
   - Business logic in services (easy to unit test)
   - API routes thin (integration tests)

4. **Scalability**
   - Modular structure allows easy feature addition
   - Clear boundaries between layers

---

*This structure follows FastAPI best practices and supports the complex business logic required for the Ascent Fin platform.*
