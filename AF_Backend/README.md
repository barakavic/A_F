# Ascent Fin - Backend API

FastAPI backend for the Ascent Fin crowdfunding platform.

## Directory Structure

```
AF_Backend/
├── app/                      # Main application code
│   ├── api/                  # API layer
│   │   ├── dependencies/     # Dependency injection (auth, db sessions)
│   │   └── endpoints/        # API route handlers
│   ├── core/                 # Core configuration (settings, security)
│   ├── db/                   # Database connection and session management
│   ├── models/               # SQLAlchemy ORM models
│   ├── schemas/              # Pydantic schemas (request/response)
│   ├── services/             # Business logic layer
│   └── utils/                # Utility functions (hashing, algorithms)
├── alembic/                  # Database migrations
│   └── versions/             # Migration files
├── scripts/                  # Utility scripts (seed data, etc.)
├── tests/                    # Test suite
│   ├── unit/                 # Unit tests
│   └── integration/          # Integration tests
├── .env                      # Environment variables (not committed)
├── .env.example              # Example environment file
├── requirements.txt          # Python dependencies
├── docker-compose.yml        # Docker setup
└── Dockerfile                # Docker image definition
```

## Technology Stack

- **Framework**: FastAPI
- **Database**: PostgreSQL
- **ORM**: SQLAlchemy
- **Migrations**: Alembic
- **Cache**: Redis
- **Authentication**: JWT
- **Hashing**: Keccak-256 (SHA-3)
- **Payment**: M-Pesa Daraja API

## Setup Instructions

Coming soon...
