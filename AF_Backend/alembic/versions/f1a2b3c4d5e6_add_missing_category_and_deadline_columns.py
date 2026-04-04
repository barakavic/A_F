"""add_missing_category_and_deadline_columns

Revision ID: f1a2b3c4d5e6
Revises: 643405aba481
Create Date: 2026-04-04 12:10:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'f1a2b3c4d5e6'
down_revision = '643405aba481'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add campaign.category column (string category name, distinct from category_c which is a numeric risk score)
    op.add_column('campaign', sa.Column('category', sa.String(length=100), nullable=True))

    # Add milestone.target_deadline column
    op.add_column('milestone', sa.Column('target_deadline', sa.DateTime(), nullable=True))


def downgrade() -> None:
    op.drop_column('milestone', 'target_deadline')
    op.drop_column('campaign', 'category')
