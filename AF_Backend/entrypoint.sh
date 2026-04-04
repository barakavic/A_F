#!/bin/bash
set -e

# Run database migrations
echo "Running database migrations..."
# Only run if alembic is initialized
if [ -f "alembic.ini" ]; then
    alembic upgrade head
else
    echo "Alembic not initialized, skipping migrations."
fi

# Start the application
# Use the PORT environment variable provided by Railway, defaulting to 8000
echo "Starting application on port ${PORT:-8000}..."
exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}
