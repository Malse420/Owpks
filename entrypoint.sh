#!/bin/bash

# Switch back to root for running Tailscale, which requires elevated privileges
sudo tailscaled &
sudo tailscale up --authkey=${TAILSCALE_AUTH_KEY}

# Start Stable Diffusion WebUI (1111)
bash webui.sh --listen --port 7860
