# Office Coworker Agent

## Installation with Docker

The image is based on Node.js and runs as a non-root user (`pwuser`) for safety on untrusted websites.

### Build

```bash
docker build -t office-coworker-agent .
```

### Run

Two runtime flags must be passed at `docker run` time — they cannot be baked into the image:

- `--ipc=host` — required by Chromium to avoid shared memory issues
- `-p 6080:6080` — exposes the noVNC web viewer for the headed browser

```bash
docker run -it --rm --ipc=host -p 6080:6080 office-coworker-agent
```

The agent always runs Chrome in headed mode. To view the browser window from your host machine, open **http://localhost:6080/vnc.html** in your browser. This is optional — the agent works the same whether or not you watch.
