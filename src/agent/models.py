from pydantic import BaseModel

class TaskResult(BaseModel):
    prompt: str
    summary: str = ""
    fullOutput: str