"""add deadline to milestone

Revision ID: 306471068e06
Revises: 92a43bf1d355
Create Date: 2026-01-14 15:57:08.065465

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '306471068e06'
down_revision = '92a43bf1d355'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('milestone', sa.Column('deadline', sa.DateTime(), nullable=True))


def downgrade() -> None:
    op.drop_column('milestone', 'deadline')
