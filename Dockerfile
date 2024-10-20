FROM python:3.10-slim

# Install system dependencies
RUN apt-get update && apt-get install -y git wget curl libgl1 libglib2.0-0 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Clone Stable Diffusion WebUI
RUN git clone https://github.com/P2Enjoy/stable-diffusion-webui.git /app
WORKDIR /app

# Clone Roop Uncensored extension
RUN git clone https://github.com/P2Enjoy/sd-webui-roop-uncensored.git extensions/sd-webui-roop-uncensored

# Install WebUI dependencies
RUN pip install -r requirements.txt

# Install Tailscale for SSH
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Expose necessary ports for WebUI and Tailscale SSH
EXPOSE 7860 22

# Entrypoint to run both WebUI and Tailscale
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
