#!/bin/bash

# Function to handle termination signals (SIGTERM)
_term() {
    echo "Caught SIGTERM signal. Logging out and cleaning up."
    trap - TERM
    kill -TERM $TAILSCALE_DAEMON_PID
    wait $TAILSCALE_DAEMON_PID
}

# Trap SIGTERM and SIGINT for graceful shutdown
trap _term TERM

# Start the Tailscale daemon with specified state and socket paths
/app/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
TAILSCALE_DAEMON_PID=$!

# Start Tailscale with provided authentication key and hostname
/app/tailscale up --ssh --authkey=${TAILSCALE_AUTHKEY} --hostname=${KOYEB_APP_NAME}-${KOYEB_SERVICE_NAME}

# Start Stable Diffusion WebUI
echo "Starting Stable Diffusion WebUI..."
cd /root/webui
python launch.py ${WEBUI_FLAGS} &
WEBUI_PID=$!
echo "Stable Diffusion WebUI started with PID ${WEBUI_PID}."

# Wait for the process to complete and handle cleanup
wait ${TAILSCALE_DAEMON_PID} ${WEBUI_PID}
