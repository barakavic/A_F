"""add_missing_milestone_statuses

Revision ID: 7a0e1c2d3b4f
Revises: f1a2b3c4d5e6
Create Date: 2026-04-04 13:30:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '7a0e1c2d3b4f'
down_revision = 'f1a2b3c4d5e6'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Use postgresql direct ALTER TYPE to add missing enum values
    # These must be done outside of a transaction block in Postgres
    op.execute("COMMIT")
    
    # Milestone Statuses
    for status in ['active', 'evidence_submitted', 'voting_open', 'voting_closed', 'revision_submitted', 'failed']:
        op.execute(f"ALTER TYPE milestone_status ADD VALUE IF NOT EXISTS '{status}'")
        
    # Campaign Statuses
    for status in ['pending_review']:
        op.execute(f"ALTER TYPE campaign_status ADD VALUE IF NOT EXISTS '{status}'")


def downgrade() -> None:
    # PostgreSQL doesn't support removing values from an enum type easily
    pass
