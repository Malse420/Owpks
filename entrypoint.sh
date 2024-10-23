#!/bin/bash

# Start the Tailscale daemon in the background
tailscaled &

# Wait for the Tailscale daemon to start
sleep 5

# Start Tailscale with the provided authentication key
if [ -n "${TAILSCALE_AUTH_KEY}" ]; then
    echo "Starting Tailscale..."
    tailscale up --authkey=${TAILSCALE_AUTH_KEY}
else
    echo "TAILSCALE_AUTH_KEY is not set. Skipping Tailscale startup."
fi

# Function to check if Tailscale is running
check_tailscale() {
    if tailscale status > /dev/null 2>&1; then
        echo "Tailscale is running."
    else
        echo "Tailscale is not running. Restarting..."
        tailscale up --authkey=${TAILSCALE_AUTH_KEY}
    fi
}

# Function to check if the WebUI is running using lsof
check_webui() {
    if lsof -i :7860 > /dev/null 2>&1; then  # Replace 7860 with the correct port if needed
        echo "Stable Diffusion WebUI is running."
    else
        echo "Stable Diffusion WebUI is not running. Restarting..."
        cd /root/webui
        python launch.py ${WEBUI_FLAGS} &
    fi
}

# Start Stable Diffusion WebUI
echo "Starting Stable Diffusion WebUI..."
cd /root/webui
python launch.py ${WEBUI_FLAGS} &

# Main loop to keep the container alive and check processes
while true; do
    # Check if Tailscale is running
    check_tailscale
    
    # Check if WebUI is running
    check_webui

    # Sleep for 30 seconds before checking again
    sleep 30
done
