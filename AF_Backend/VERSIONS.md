# Project Version History

## v0.1.0 - Backend Foundation Setup
**Date:** 2025-11-25
**Status:** Initial Setup

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

### Technical Details
- **Framework:** FastAPI
- **Database:** PostgreSQL (configured in docker-compose)
- **Cache:** Redis (configured in docker-compose)
- **Python Version:** 3.10+
