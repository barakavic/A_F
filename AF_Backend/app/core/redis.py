import redis
from app.core.config import settings
import json
from typing import Optional, Dict, Any

def get_redis_client() -> redis.Redis:
    """
    Get a Redis client instance connected to the configured Redis server.
    """
    return redis.from_url(
        settings.REDIS_URL,
        decode_responses=True  # Automatically decode bytes to strings
    )

def save_stk_session(checkout_id: str, session_data: Dict[str, Any]) -> bool:
    """
    Save STK Push session data to Redis with a 10-minute TTL.
    
    Args:
        checkout_id: The CheckoutRequestID from Safaricom
        session_data: Dictionary containing campaign_id, contributor_id, amount, phone_number
    
    Returns:
        True if saved successfully, False otherwise
    """
    try:
        client = get_redis_client()
        key = f"stk:{checkout_id}"
        value = json.dumps(session_data)
        # Set with 600 second (10 minute) expiration
        client.setex(key, 600, value)
        return True
    except Exception as e:
        print(f"Error saving STK session: {e}")
        return False

def get_stk_session(checkout_id: str) -> Optional[Dict[str, Any]]:
    """
    Retrieve STK Push session data from Redis.
    
    Args:
        checkout_id: The CheckoutRequestID from Safaricom
    
    Returns:
        Session data dictionary if found, None if expired or not found
    """
    try:
        client = get_redis_client()
        key = f"stk:{checkout_id}"
        value = client.get(key)
        if value:
            return json.loads(value)
        return None
    except Exception as e:
        print(f"Error retrieving STK session: {e}")
        return None

def delete_stk_session(checkout_id: str) -> bool:
    """
    Delete STK Push session data from Redis after processing.
    
    Args:
        checkout_id: The CheckoutRequestID from Safaricom
    
    Returns:
        True if deleted successfully, False otherwise
    """
    try:
        client = get_redis_client()
        key = f"stk:{checkout_id}"
        client.delete(key)
        return True
    except Exception as e:
        print(f"Error deleting STK session: {e}")
        return False
