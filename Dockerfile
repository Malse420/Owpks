FROM python:3.10-slim

# Install system dependencies for Debian-based systems
RUN apt-get update && apt-get install -y \
    wget git python3 python3-venv libgl1 libglib2.0-0 curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Clone the AUTOMATIC1111 Stable Diffusion WebUI
WORKDIR /app
RUN wget -q https://raw.githubusercontent.com/AUTOMATIC1111/stable-diffusion-webui/master/webui.sh

# Run the webui.sh script to install all necessary components
RUN bash webui.sh --skip-torch-cuda-test

# Clone Roop Uncensored extension
RUN git clone https://github.com/s0md3v/sd-webui-roop.git extensions/sd-webui-roop

# Install the required insightface library for Roop extension
RUN pip install insightface==0.7.3

# Create the models directory for Roop extension and download simswapper_512_beta.onnx
RUN mkdir -p /app/models/roop/ && \
    wget -O /app/models/roop/simswapper_512_beta.onnx https://huggingface.co/netrunner-exe/Insight-Swap-models-onnx/resolve/8d4ab0b123254fc1c5a37f3a7f3188a80ecf0459/simswap_512_beta.onnx?download=true

# Optional: Download inswapper_128.onnx in case of 'NoneType' errors
RUN wget -O /app/models/roop/inswapper_128.onnx https://huggingface.co/path-to-inswapper-model/inswapper_128.onnx

# Install Tailscale for SSH
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Expose necessary ports for WebUI and Tailscale SSH
EXPOSE 7860 22

# Entrypoint to run both WebUI and Tailscale
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
