import socketio
from typing import Any

# Create Socket.io server instance
# async_mode='asgi' is important for FastAPI integration
sio = socketio.AsyncServer(async_mode='asgi', cors_allowed_origins='*')

# Create ASGI application
socket_app = socketio.ASGIApp(sio)

@sio.event
async def connect(sid, environ):
    print(f"[SOCKET] Client connected: {sid}")

@sio.event
async def disconnect(sid):
    print(f"[SOCKET] Client disconnected: {sid}")

@sio.event
async def join_campaign(sid, campaign_id: str):
    print(f"[SOCKET] Client {sid} joining campaign: {campaign_id}")
    await sio.enter_room(sid, campaign_id)

@sio.event
async def leave_campaign(sid, campaign_id: str):
    print(f"[SOCKET] Client {sid} leaving campaign: {campaign_id}")
    await sio.leave_room(sid, campaign_id)

async def emit_milestone_update(campaign_id: str, data: Any):
    """
    Helper to broadcast milestone updates to all users following a campaign.
    """
    # Debug: Check who is in the room
    participants = sio.manager.get_participants("/", campaign_id)
    print(f"[SOCKET] Room {campaign_id} has {len(list(participants))} participants")
    
    await sio.emit("milestone_update", data, room=campaign_id)
    print(f"[SOCKET] Broadcast update for {campaign_id}: {data}")
    
    # Debug: Also broadcast globally to ensure connectivity
    await sio.emit("milestone_update", data) 
