#!/bin/bash

# Start the Tailscale daemon in the background with userspace networking
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &
TAILSCALED_PID=$!

# Wait for the Tailscale daemon to start
sleep 5

# Start Tailscale with ephemeral key and disable DNS changes
if [ -n "${TAILSCALE_AUTH_KEY}" ]; then
    echo "Starting Tailscale with ephemeral authentication..."
    tailscale up --authkey=${TAILSCALE_AUTH_KEY}?ephemeral=true --accept-dns=false
    if [ $? -ne 0 ]; then
        echo "Tailscale failed to start. Exiting..."
        exit 1
    fi
else
    echo "TAILSCALE_AUTH_KEY is not set. Skipping Tailscale startup."
fi

# Start Stable Diffusion WebUI
echo "Starting Stable Diffusion WebUI..."
cd /root/webui
python launch.py ${WEBUI_FLAGS} &
WEBUI_PID=$!
echo "Stable Diffusion WebUI started with PID ${WEBUI_PID}."

# Function to handle script termination gracefully
cleanup() {
    echo "Shutting down Tailscale and WebUI..."
    kill ${TAILSCALED_PID} ${WEBUI_PID}
    wait ${TAILSCALED_PID} ${WEBUI_PID}
    exit 0
}

# Trap SIGTERM and SIGINT to gracefully shut down
trap cleanup SIGTERM SIGINT
