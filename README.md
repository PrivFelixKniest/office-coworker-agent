# Office Coworker Agent

Automate your browser based office work with AI Agents. (Using Python, opencode and playwright)

## User Discretion

While this agentic system provides tools to guard against typical issues like leaking secrets, the safety and protection of your login and personal data can not be guaranteed. Be aware that the agent has full control to act and read within their browser environment and may cause damages if not - and possibly even when - properly controlled. Grant the Agent control over data, accounts and systems only at your own risk.

## Installation and Usage with Docker

The image is based on Node.js and runs as a non-root user (`pwuser`) for safety on untrusted websites.

### Build

```bash
docker build -t office-coworker-agent .
```

### Secrets & Login information

Copy `.env.secrets.example` to `.env.secrets` and fill in your credentials:

```bash
cp .env.secrets.example .env.secrets
```

The `.env.secrets` file is gitignored — secrets are injected at runtime via `--env-file` and never baked into the image.

Notice: The agent configuration tries to guide and force the agent towards never directly reading these secrets, but safety can not be guaranteed. Use only at your own risk.

### Run

Two runtime flags must be passed at `docker run` time — they cannot be baked into the image:

- `--ipc=host` — required by Chromium to avoid shared memory issues
- `-p 6080:6080` — exposes the noVNC web viewer for the headed browser

```bash
docker run --env-file .env.secrets -it --rm --ipc=host -p 6080:6080 office-coworker-agent
```

The agent will always open a chrome window while working on a task. To view, check and control the browser window from your host machine, open **http://localhost:6080/vnc.html**. This is optional — the agent works the same whether or not you watch.

### Extend the python code to automatically fetch your incoming tasks

`src/tasks/tasks.py` is intentionally a **stub** that returns an empty list:

```python
def getTasks() -> list[Task]:
    # TODO: Add your code here
    return []
```

Replace `getTasks()` with your own implementation to pull tasks from any data source — a database, REST API, message queue, or file. Each `Task` has a `prompt` (natural language instruction for the agent) and an `origin` (source identifier).

## How it works

### Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                   Docker Container                      │
│                                                         │
│  ┌───────────────┐ subprocess   ┌───────────────────┐   │
│  │  src/main.py  │ ──────────── │    opencode run   │   │
│  │  (Python      │ opencode run │    (Agent Loop)   │   │
│  │   Harness)    │  '<prompt>'  │                   │   │
│  │               │              │    ┌───────────┐  │   │
│  │  loop:        │              │    │ office-   │  │   │
│  │    getTasks() │              │    │ coworker  │  │   │
│  │    for task:  │              │    │ agent     │  │   │
│  │      run      │              │    │ (LLM)     │  │   │
│  │      opencode │              │    └─────┬─────┘  │   │
│  │    sleep(30s) │              │          │        │   │
│  └───────────────┘              │   ┌──────┴──────┐ │   │
│                                 │   │ playwright  │ │   │
│                                 │   │ -cli        │ │   │
│                                 │   │ (Browser    │ │   │
│                                 │   │  Automation)│ │   │
│                                 │   └──────┬──────┘ │   │
│                                 └──────────┼────────┘   │
│                                            │            │
│                                  ┌─────────┴──────────┐ │
│                                  │  Chrome (headed)   │ │
│                                  │  via Xvfb :99      │ │
│                                  └─────────┬──────────┘ │
│                                            │            │
│                                  ┌─────────┴─────────┐  │
│                                  │  x11vnc → novnc   │  │
│                                  │  → port 6080      │  │
│                                  └───────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 1. Container Startup

The Docker container starts by running the `entrypoint.sh` script which sets up three background services:

- **Xvfb** — A virtual framebuffer (`:99`, 1280×1024×24) that provides a virtual display so Chrome can run in headed mode without a physical screen.
- **x11vnc** — A VNC server attached to the virtual display that allows remote viewing.
- **websockify** — Bridges the VNC protocol to WebSocket, making the browser viewable at `http://localhost:6080/vnc.html`.

After services start, the default command launches the Python agent harness: `python3 /home/pwuser/src/main.py`.

### 2. Agent Harness (Python)

`src/main.py` is the main loop. It:

1. Prints a startup banner and VNC URL with a security notice.
2. Enters an infinite loop polling for tasks every 30 seconds via `getTasks()`.
3. For each task returned, calls `completeTaskWithAgent(prompt)`.

### 3. Task Dispatch

`src/agent/agent.py` shells out to:

```bash
opencode run '<prompt>'
```

This invokes the opencode AI agent framework with the given prompt. The result (stdout) is captured and returned as a `TaskResult` model.

### 4. AI Agent Execution

opencode loads the **office-coworker** agent configuration:

- **Instructions** from `~/.opencode/agents/office-coworker.md` — guides the LLM to use `playwright-cli` for browser automation, handle credentials via environment variables, never echo passwords, and keep the browser in headed mode for human observability.
- **Skills** — the `playwright-cli` skill provides a comprehensive reference for browser automation commands (click, type, navigate, snapshot, etc.).
- **Permissions** — bash commands are allowed by default, but file-reading commands (`cat`, `grep`, `find`, `echo`, `head`, `tail`, `sed`, `awk`, `ls`) are **denied** to prevent the agent from reading secrets.
- **File modification** — `write` and `edit` tools are disabled, so the agent can only interact with the browser, not the filesystem.

### 5. Browser Automation

The agent uses `playwright-cli` to control Chrome in headed mode. All browser actions are visible in real-time through the noVNC interface. Every navigation command is followed by a snapshot so the agent can observe the page state.

### 6. Task Fetching (Extension Point)

`src/tasks/tasks.py` is intentionally a **stub** that returns an empty list:

```python
def getTasks() -> list[Task]:
    # TODO: Add your code here
    return []
```

Replace `getTasks()` with your own implementation to pull tasks from any data source — a database, REST API, message queue, or file. Each `Task` has a `prompt` (natural language instruction for the agent) and an `origin` (source identifier).

### Security Model

| Layer            | Measure                                                                                                          |
| ---------------- | ---------------------------------------------------------------------------------------------------------------- |
| **Container**    | Runs as non-root user `pwuser`                                                                                   |
| **Secrets**      | Injected at runtime via `--env-file .env.secrets`, never baked into the image                                    |
| **Agent**        | Cannot run `cat`, `echo`, `grep`, `find`, `head`, `tail`, `ls`, `sed`, `awk` (prevented by opencode permissions) |
| **Agent**        | Cannot write or edit files (`write`/`edit` tools disabled)                                                       |
| **Instructions** | Agent is instructed never to echo or read passwords from website snapshot after filling login forms              |
| **Network**      | No ports exposed beyond the VNC viewer (6080); browser is contained within the container                         |

### Credential Pattern

Secrets follow a naming convention in `.env.secrets`:

```
SITE_COM_EMAIL=user@example.com
SITE_COM_PASSWORD=your-password
```

Replace `SITE` with the domain name (e.g., `GOOGLE_COM_EMAIL`, `GOOGLE_COM_PASSWORD` for google.com).

### Ports and Volumes

| Flag                      | Purpose                                                  |
| ------------------------- | -------------------------------------------------------- |
| `--ipc=host`              | Required by Chromium for shared memory between processes |
| `-p 6080:6080`            | Exposes the noVNC web interface for browser viewing      |
| `--env-file .env.secrets` | Injects credentials as environment variables at runtime  |

### Alternative Usage

You can also exec into the container and run opencode directly:

```bash
docker exec -it <container> opencode run "your prompt here"
```

This gives you ad-hoc access to the same agent environment without the polling harness.

## Motivation

Office tasks are often repetetive and simple, yet important and time consuming. Moving information from one place to the other, where APIs dont exist or humans in between complicate the process.

But...

If a program, or in this case an AI agent is able to act like a human, by navigating the web like a human, he could overcome these hurdles and provide options for automation, where previously only human labour was possible or reasonable.
AI agents like this are by design not taylored to fit one problem.
Instead they can adapt to any situation, any layout shift, like a human.

The tradeoff becomes **inference cost vs. labour cost** or possibly **inference cost vs. implementation cost** for a more specific and likely more efficient program.
But with human time saved, and "good enough" models becoming affordable, maybe having an agent control a web browser can really save you valuable time at work that you can use to earn money else where.

### The problem of AI Safety

Giving AI models and agents control over anything always comes at a risk.
This project addresses and proposes ideas for some of these risks like handling login credentials and user sessions without leaking sensitive information.
Though even that can not be guaranteed with the given solution.

However, the risk of financial or other damage due to the agents missbehaviour still exists. Improper input sanitization may leave gaps wide open for attackers to inject malicous prompts for example.

Therefore, common AI safety tips are still advised:

- **Human in the loop:** Let a human review and sanity check the AIs input before starting its work
- **Principle of Least Privilidge:** Only give the Agent as much control and access as you can reasonably manage to take responsibilty for

or even if possible:

- **Use trusted inference:** Make sure the tokens are computed in a trusted and safe environment that will not missuse any incoming private or sensitive information.

## Plug and Play

Using the Docker container can be conveniant, but setting up a similar setup on your host machine is also not difficult.
Follow the steps in the Dockerfile on your host machine if you want to execute a similar system without docker.
