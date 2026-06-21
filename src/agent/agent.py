from agent.models import TaskResult
from tasks.models import Task
import subprocess

def completeTaskWithAgent(task: Task ) -> TaskResult:
    output = subprocess.run(f"opencode run '<TASK PROMPT>{task.prompt}</TASK PROMPT><RELATED KNOWLEDGE>{task.relatedKnowledge}</RELATED KNOWLEDGE>'", shell=True, capture_output=True, text=True)
    return TaskResult(task=task, fullOutput=output.stdout)

