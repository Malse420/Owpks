#!/bin/bash

# Start Tailscale
tailscaled &
tailscale up --authkey=${TAILSCALE_AUTH_KEY}

# Start Stable Diffusion WebUI (1111)
bash webui.sh --listen --port 7860
