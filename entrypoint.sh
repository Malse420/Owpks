#!/bin/bash

# Start Tailscale in the background with the provided auth key
if [ -n "${TAILSCALE_AUTH_KEY}" ]; then
    echo "Starting Tailscale..."
    sudo tailscale up --authkey=${TAILSCALE_AUTH_KEY} &
else
    echo "TAILSCALE_AUTH_KEY is not set. Skipping Tailscale startup."
fi

# Start the Stable Diffusion WebUI
echo "Starting Stable Diffusion WebUI..."
cd /home/webui-user/webui

# Run WebUI with provided flags
python launch.py ${WEBUI_FLAGS}
