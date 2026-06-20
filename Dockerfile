FROM node:24-bookworm

# Install python
RUN apt-get update
RUN apt install -y python3 python3-pip 

# Install chrome
RUN apt install wget
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
RUN apt-get install -y ./google-chrome-stable_current_amd64.deb

# Install xvfb for headed browser support in headless environment
RUN apt-get install -y xvfb x11vnc novnc

# Install playwright-cli
RUN npm install -g @playwright/cli@0.1.14
RUN playwright-cli --help

# Install opencode
RUN npm i -g opencode-ai@1.17.8
RUN opencode --version

# Install python dependencies
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --break-system-packages -r /tmp/requirements.txt

# Switch to non-root user for safer usage later
RUN useradd -ms /bin/bash pwuser
USER pwuser
WORKDIR /home/pwuser

# Copy opencode config
ENV DISPLAY=:99

COPY --chown=pwuser:pwuser opencode-config/opencode.json /home/pwuser/.opencode/opencode.json
COPY --chown=pwuser:pwuser opencode-config/agents/ /home/pwuser/.opencode/agents/
COPY --chown=pwuser:pwuser opencode-config/skills/ /home/pwuser/.opencode/skills/
COPY --chown=pwuser:pwuser src/ /home/pwuser/src/

# Setup headed browser and display forwarding through novnc
COPY --chmod=755 <<'EOF' /usr/local/bin/entrypoint.sh
#!/bin/bash
Xvfb :99 -screen 0 1280x1024x24 >/dev/null 2>&1 &
x11vnc -display :99 -forever -nopw -shared -rfbport 5900 >/dev/null 2>&1 &
websockify --web /usr/share/novnc 6080 localhost:5900 >/dev/null 2>&1 &
exec "$@"
EOF

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["python3", "/home/pwuser/src/main.py"]

EXPOSE 6080
