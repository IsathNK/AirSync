from fastapi import FastAPI
from fastapi import FastAPI, HTTPException
from models import Clip, ClipResponse
from typing import List
import time

app = FastAPI()
clips_store: List[dict] = []
next_id = 1

@app.post("/api/clips", response_model=ClipResponse)
async def receive_clip(clip: Clip):
    global next_id
    # Decide on timestamp: if client didn’t send one, use server time
    ts = clip.timestamp or time.time()
    # Generate a new record and store it in clips_store
    record = {
        "id": next_id,
        "text": clip.text,
        "timestamp": ts,
        "tags": None  # or “general” / call a tagging function here
    }
    clips_store.append(record)
    next_id += 1

    # Return exactly what we just stored
    return ClipResponse(**record)

@app.get("/api/clips", response_model=List[ClipResponse])
async def list_clips():
    # Return stored clips in reverse order (most recent first)
    return [ClipResponse(**r) for r in reversed(clips_store)]
