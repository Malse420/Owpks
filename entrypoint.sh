#!/bin/bash

# Start the Tailscale daemon in the background with userspace networking and disable host network changes
tailscaled --tun=userspace-networking --accept-dns=false --socks5-server=localhost:1055 &
TAILSCALED_PID=$!

# Wait for the Tailscale daemon to start
sleep 5

# Start Tailscale with ephemeral key and disable DNS changes
if [ -n "${TAILSCALE_AUTH_KEY}" ]; then
    echo "Starting Tailscale..."
    tailscale up --authkey=${TAILSCALE_AUTH_KEY} --ephemeral --accept-dns=false
    if [ $? -ne 0 ]; then
        echo "Tailscale failed to start. Exiting..."
        exit 1
    fi
else
    echo "TAILSCALE_AUTH_KEY is not set. Skipping Tailscale startup."
fi

# Function to check if Tailscale is running
check_tailscale() {
    if tailscale status > /dev/null 2>&1; then
        echo "Tailscale is running."
    else
        echo "Tailscale is not running. Restarting..."
        tailscale up --authkey=${TAILSCALE_AUTH_KEY} --ephemeral --accept-dns=false
        if [ $? -ne 0 ]; then
            echo "Tailscale failed to restart. Exiting..."
            exit 1
        fi
    fi
}

# Function to check if the WebUI is running using lsof on port 7860
check_webui() {
    if lsof -i :7860 > /dev/null 2>&1; then
        echo "Stable Diffusion WebUI is running."
    else
        echo "Stable Diffusion WebUI is not running. Restarting..."
        cd /root/webui
        python launch.py ${WEBUI_FLAGS} &
        WEBUI_PID=$!
        echo "Stable Diffusion WebUI restarted with PID ${WEBUI_PID}."
    fi
}

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

# Main loop to keep the container alive and check processes
while true; do
    # Run checks in parallel to improve efficiency
    check_tailscale &
    check_webui &
    wait  # Wait for both checks to complete

    # Sleep for 10 seconds before checking again to make the loop more responsive
    sleep 10
done
