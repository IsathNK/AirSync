from pydantic import BaseModel
from typing import Optional

class Clip(BaseModel):
    text: str
    timestamp: Optional[float] = None   # UNIX epoch seconds

class ClipResponse(BaseModel):
    id: int
    text: str
    timestamp: float
    tags: Optional[str] = None
