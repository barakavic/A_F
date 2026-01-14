# Ascent_Fin Testing Documentation

This directory contains the unit and integration tests for the Ascent_Fin backend.

## 1. Testing Strategy
We use **pytest** as our primary testing framework. Our strategy focuses on:
- **Unit Tests**: Testing individual services and utilities in isolation.
- **Mocking**: Using in-memory SQLite databases for fast, isolated tests.
- **Cryptographic Verification**: Ensuring that digital signatures and hashing logic are mathematically sound.

## 2. Test Suites

### Algorithm Service (`tests/unit/test_algorithm_service.py`)
Verifies the core risk and fund allocation formulas:
- **Risk Factor (C)**: Clamping and industry-based weights.
- **Alpha**: Skewness of fund distribution based on duration.
- **Phase Count (P)**: Dynamic calculation of milestones.
- **Milestone Weights**: Exponential distribution of funds.

### Contribution Service (`tests/unit/test_contribution_service.py`)
Verifies the financial flow:
- Campaign total updates.
- Escrow balance updates.
- Transaction ledger logging.
- Automatic Vote Token generation.

### Voting Service (`tests/unit/test_voting_service.py`)
Verifies the governance and security:
- **Keccak-256 Hashing**: Deterministic message generation.
- **ECDSA Signature Verification**: Ensuring only valid signatures from authorized contributors are accepted.
- **Tamper Detection**: Verifying that altered messages fail signature checks.

## 3. How to Run Tests

### Prerequisites
Ensure your virtual environment is activated and dependencies are installed:
```bash
source setup_env.sh
```

### Run All Tests
```bash
pytest
```

### Run Specific Test File
```bash
pytest tests/unit/test_voting_service.py
```

## 4. Notes on Database Testing
Since the production database is PostgreSQL (using UUIDs) and the test database is SQLite (using Strings), we use simplified models in unit tests to ensure compatibility while maintaining logic integrity.
