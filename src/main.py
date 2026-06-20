from agent.agent import completeTaskWithAgent
from tasks.tasks import getTasks
import time

class TerminalColorCodes:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def main():
    print("Waiting for Tasks...")
    while True:
        print("Fetching Tasks...")
        tasks = getTasks()
        print(f"{len(tasks)} Tasks found")
        for task in tasks:
            print(f"Starting Task: {task.prompt}...")
            result = completeTaskWithAgent(prompt=task.prompt)
            print(f"""Task Result: 
            {result.fullOutput}
                   """)
        time.sleep(30)
    

if __name__ == "__main__":
    print(f"""
████ ████ ████ █ ████ ████   ████ ████ ████ █  █ ████
█  █ █    █    █ █    █      █  █ █    █    █  █  █
█  █ ███  ███  █ █    ████   ████ █    ████ ██ █  █
█  █ █    █    █ █    █      █  █ █  █ █    █ ██  █
████ █    █    █ ████ ████   █  █ ████ ████ █  █  █""")
    print(f"""
Office Agent has started successfully!
See what your agents are doing under: {TerminalColorCodes.UNDERLINE}{TerminalColorCodes.OKCYAN}http://localhost:6080/vnc.html{TerminalColorCodes.ENDC}

{TerminalColorCodes.WARNING}NOTICE: The office agent has full control over the browser environment
        and your possibly sensitive information.
        Make sure you understand the risks associated with gen-AI and
        only provide it with appropriate access and data.{TerminalColorCodes.ENDC}
          """)

    main()
