#!/bin/bash

# Start Tailscale
tailscaled &
tailscale up --authkey=${TAILSCALE_AUTH_KEY}

# Start Stable Diffusion WebUI
python launch.py --listen --port 7860
