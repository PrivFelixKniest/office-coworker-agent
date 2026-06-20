from agent.models import TaskResult
import subprocess

def completeTaskWithAgent(prompt: str, ) -> TaskResult:
    output = subprocess.run(f"opencode run '{prompt}'", shell=True, capture_output=True, text=True)
    return TaskResult(prompt=prompt, fullOutput=output.stdout)

