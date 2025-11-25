# Ascent Fin Backend - Setup Guide

[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](VERSIONS.md)
> **Track changes in [VERSIONS.md](VERSIONS.md)**

## 🚀 Quick Start

### Prerequisites
- Python 3.10+
- Docker & Docker Compose
- Git

### 1. Install Dependencies

```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Linux/Mac:
source venv/bin/activate
# On Windows:
# venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Configure Environment

The `.env` file is already created with development defaults. Update the following if needed:
- M-Pesa API credentials (get from Daraja Portal)
- SECRET_KEY (generate with: `openssl rand -hex 32`)
- Database credentials (if not using Docker)

### 3. Start Services with Docker

```bash
# Start all services (PostgreSQL, Redis, API, pgAdmin)
docker-compose up -d

# View logs
docker-compose logs -f api

# Stop services
docker-compose down
```

**Services will be available at:**
- API: http://localhost:8000
- API Docs: http://localhost:8000/docs
- pgAdmin: http://localhost:5050 (admin@ascentfin.com / admin)
- PostgreSQL: localhost:5432
- Redis: localhost:6379

### 4. Run Without Docker (Local Development)

```bash
# Make sure PostgreSQL and Redis are running locally

# Run the API
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

## 📁 Project Structure

```
AF_Backend/
├── app/
│   ├── api/
│   │   ├── dependencies/     # Auth, DB session injection
│   │   └── endpoints/        # API routes
│   ├── core/
│   │   └── config.py        # ✅ Application settings
│   ├── db/                   # Database connection
│   ├── models/               # SQLAlchemy models
│   ├── schemas/              # Pydantic schemas
│   ├── services/             # Business logic
│   ├── utils/                # Helper functions
│   └── main.py              # ✅ FastAPI app entry point
├── alembic/                  # Database migrations
├── tests/                    # Test suite
├── .env                      # ✅ Environment variables
├── requirements.txt          # ✅ Python dependencies
├── docker-compose.yml        # ✅ Docker services
├── Dockerfile                # ✅ API container
└── README.md                 # This file
```

---

## 🔧 Development Workflow

### Database Migrations (Coming Soon)

```bash
# Initialize Alembic
alembic init alembic

# Create migration
alembic revision --autogenerate -m "Create initial tables"

# Apply migrations
alembic upgrade head

# Rollback
alembic downgrade -1
```

### Testing (Coming Soon)

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app tests/

# Run specific test file
pytest tests/test_campaigns.py
```

---

## 📚 API Documentation

Once the server is running, visit:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

---

## 🔐 Environment Variables

Key variables in `.env`:

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://...` |
| `REDIS_URL` | Redis connection string | `redis://localhost:6379/0` |
| `SECRET_KEY` | JWT signing key | Change in production! |
| `MPESA_CONSUMER_KEY` | M-Pesa API key | Get from Daraja |
| `MPESA_CONSUMER_SECRET` | M-Pesa API secret | Get from Daraja |

---

## 🐳 Docker Commands

```bash
# Build and start
docker-compose up --build

# Rebuild specific service
docker-compose up --build api

# View logs
docker-compose logs -f api

# Execute command in container
docker-compose exec api bash

# Stop and remove volumes
docker-compose down -v
```

---

## 📝 Next Steps

1. ✅ Configuration files created
2. ⏳ Create database models (SQLAlchemy)
3. ⏳ Set up Alembic migrations
4. ⏳ Implement authentication endpoints
5. ⏳ Build campaign management APIs
6. ⏳ Implement voting system
7. ⏳ Integrate M-Pesa payments

---

## 🆘 Troubleshooting

### Port already in use
```bash
# Find process using port 8000
lsof -i :8000
# Kill the process
kill -9 <PID>
```

### Database connection error
- Ensure PostgreSQL is running
- Check DATABASE_URL in `.env`
- Verify credentials match docker-compose.yml

### Module not found
```bash
# Reinstall dependencies
pip install -r requirements.txt
```

---

**Status**: ✅ Backend foundation ready for development!
