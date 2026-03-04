from eth_account import Account
from eth_account.messages import encode_defunct
from eth_utils import keccak
import json

def get_vote_message(campaign_id: str, milestone_id: str, vote_value: str, nonce: str) -> str:
    """
    Generate the standardized message string for voting.
    This must match exactly what the frontend signs.
    """
    message_dict = {
        "campaign_id": str(campaign_id),
        "milestone_id": str(milestone_id),
        "vote": vote_value.upper(),
        "nonce": nonce,
        "app": "Ascent_Fin"
    }
    # Use sort_keys to ensure deterministic string representation
    return json.dumps(message_dict, sort_keys=True)

def get_waiver_message(campaign_id: str, nonce: str) -> str:
    """
    Generate the standardized message string for waiving all votes in a campaign.
    """
    message_dict = {
        "action": "WAIVE_ALL_VOTES",
        "campaign_id": str(campaign_id),
        "nonce": nonce,
        "app": "Ascent_Fin"
    }
    return json.dumps(message_dict, sort_keys=True)

def verify_vote_signature(
    campaign_id: str, 
    milestone_id: str, 
    vote_value: str, 
    nonce: str, 
    signature: str, 
    public_key: str
) -> bool:
    """
    Verify that a vote signature is valid and matches the expected public key.
    """
    message = get_vote_message(campaign_id, milestone_id, vote_value, nonce)
    signable_message = encode_defunct(text=message)
    
    try:
        recovered_address = Account.recover_message(signable_message, signature=signature)
        return recovered_address.lower() == public_key.lower()
    except Exception:
        return False

def verify_waiver_signature(
    campaign_id: str,
    nonce: str,
    signature: str,
    public_key: str
) -> bool:
    """
    Verify that a master waiver signature is valid.
    """
    message = get_waiver_message(campaign_id, nonce)
    signable_message = encode_defunct(text=message)
    
    try:
        recovered_address = Account.recover_message(signable_message, signature=signature)
        return recovered_address.lower() == public_key.lower()
    except Exception:
        return False

def generate_keccak_hash(text: str) -> str:
    """
    Utility for Keccak-256 hashing.
    """
    return keccak(text=text).hex()
