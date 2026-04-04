"""add_total_withdrawn_to_fundraiser

Revision ID: 8b1f2e3d4c5a
Revises: 7a0e1c2d3b4f
Create Date: 2026-04-04 13:40:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '8b1f2e3d4c5a'
down_revision = '7a0e1c2d3b4f'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add total_withdrawn column to fundraiser_profile table
    op.add_column('fundraiser_profile', sa.Column('total_withdrawn', sa.Numeric(precision=12, scale=2), nullable=True, server_default='0'))


def downgrade() -> None:
    op.drop_column('fundraiser_profile', 'total_withdrawn')
