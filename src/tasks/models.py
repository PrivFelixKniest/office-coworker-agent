from pydantic import BaseModel

class Task(BaseModel):
    prompt: str
    origin: str
