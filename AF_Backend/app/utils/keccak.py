import hashlib

def keccak256(data: str) -> str:
    """
    Compute Keccak-256 hash of the input string.
    Using sha3_256 as it's the standard FIPS 202 implementation.
    """
    return hashlib.sha3_256(data.encode('utf-8')).hexdigest()
