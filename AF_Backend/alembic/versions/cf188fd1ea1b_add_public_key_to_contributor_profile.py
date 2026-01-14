"""add public_key to contributor profile

Revision ID: cf188fd1ea1b
Revises: 306471068e06
Create Date: 2026-01-14 20:43:55.262526

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'cf188fd1ea1b'
down_revision = '306471068e06'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('contributor_profile', sa.Column('public_key', sa.String(length=66), nullable=True))


def downgrade() -> None:
    op.drop_column('contributor_profile', 'public_key')
