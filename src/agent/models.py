from pydantic import BaseModel
from tasks.models import Task

class TaskResult(BaseModel):
    task: Task
    summary: str = ""
    fullOutput: str