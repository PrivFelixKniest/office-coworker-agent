# Office Coworker Agent

## Installation with Docker

The image is based on the official Playwright image (`mcr.microsoft.com/playwright:v1.61.0-noble`) and runs as a non-root user (`pwuser`) for safety on untrusted websites.

### Build

```bash
docker build -t office-coworker-agent .
```

### Run

One runtime flag must be passed at `docker run` time — it cannot be baked into the image:

- `--ipc=host` — required by Chromium to avoid shared memory issues

```bash
docker run -it --rm --ipc=host office-coworker-agent
```
