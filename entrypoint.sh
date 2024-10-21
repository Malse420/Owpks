#!/bin/bash

# Function to check if Tailscale is running
check_tailscale() {
    if tailscale status > /dev/null 2>&1; then
        echo "Tailscale is running."
    else
        echo "Tailscale is not running. Restarting..."
        sudo tailscale up --authkey=${TAILSCALE_AUTH_KEY}
    fi
}

# Function to check if the WebUI is running
check_webui() {
    if pgrep -f "launch.py" > /dev/null 2>&1; then
        echo "Stable Diffusion WebUI is running."
    else
        echo "Stable Diffusion WebUI is not running. Restarting..."
        cd /home/webui-user/webui
        python launch.py ${WEBUI_FLAGS} &
    fi
}

# Start Tailscale
if [ -n "${TAILSCALE_AUTH_KEY}" ]; then
    echo "Starting Tailscale..."
    sudo tailscale up --authkey=${TAILSCALE_AUTH_KEY} &
else
    echo "TAILSCALE_AUTH_KEY is not set. Skipping Tailscale startup."
fi

# Start Stable Diffusion WebUI
echo "Starting Stable Diffusion WebUI..."
cd /home/webui-user/webui
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
