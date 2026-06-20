FROM node:24-bookworm

# Install python
RUN apt-get update
RUN apt install -y python3 

# Install chrome
RUN apt install wget
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
RUN apt-get install -y ./google-chrome-stable_current_amd64.deb

# Install playwright-cli
RUN npm install -g @playwright/cli@0.1.14
RUN playwright-cli --help

# Install opencode
RUN npm i -g opencode-ai@1.17.8
RUN opencode --version

# Switch to non-root user for safer usage later
RUN useradd -ms /bin/bash pwuser
USER pwuser
WORKDIR /home/pwuser

# Copy opencode config
COPY --chown=pwuser:pwuser opencode-config/opencode.json /home/pwuser/.opencode/opencode.json
COPY --chown=pwuser:pwuser opencode-config/agents/ /home/pwuser/.opencode/agents/
COPY --chown=pwuser:pwuser opencode-config/skills/ /home/pwuser/.opencode/skills/

CMD ["opencode"]
