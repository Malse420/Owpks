# Base image with CUDA 11.7 and cuDNN8 for GPU acceleration
FROM nvidia/cuda:11.7.1-cudnn8-runtime-ubuntu20.04

# Set environment variables to avoid interactive tzdata configuration
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Chicago

# Install system dependencies, Python 3.10, and necessary libraries
# Combine apt-get commands to reduce layers and clear cache to save space
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        wget git python3.10 python3.10-distutils python3.10-venv \
        libgl1 libglib2.0-0 curl libgoogle-perftools-dev sudo ffmpeg && \
    ln -sf /usr/bin/python3.10 /usr/bin/python3 && \
    ln -sf /usr/bin/python3.10 /usr/bin/python && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install pip for Python 3.10 and remove the installer after use
RUN wget https://bootstrap.pypa.io/get-pip.py && python3 get-pip.py && rm get-pip.py

# Install PyTorch with CUDA, using --no-cache-dir to avoid pip caching
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu117
RUN wget https://huggingface.co/deauxpas/colabrepo/resolve/main/insightface-0.7.3-cp310-cp310-linux_x86_64.whl
RUN pip install insightface-0.7.3-cp310-cp310-linux_x86_64.whl

# Create a non-root user to avoid running processes as root
RUN useradd -m webui-user

# Switch to the new user
USER webui-user
WORKDIR /home/webui-user

# Clone the AUTOMATIC1111 Stable Diffusion WebUI
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git /home/webui-user/webui

# Install Stable Diffusion WebUI dependencies, use --no-cache-dir to save space
WORKDIR /home/webui-user/webui
RUN pip install --no-cache-dir -r requirements.txt

# Install Roop Uncensored extension
RUN git clone https://github.com/s0md3v/sd-webui-roop.git extensions/sd-webui-roop

# Install the required insightface library for Roop extension
RUN pip install --no-cache-dir insightface

# Create the models directory for Roop and download necessary models
# Save space by removing wget artifacts and unused files
RUN mkdir -p /home/webui-user/webui/models/roop/ && \
    wget -O /home/webui-user/webui/models/roop/simswapper_512_beta.onnx https://huggingface.co/netrunner-exe/Insight-Swap-models-onnx/resolve/main/simswap_512_beta.onnx && \
    wget -O /home/webui-user/webui/models/roop/inswapper_128.onnx https://huggingface.co/ezioruan/inswapper_128.onnx/resolve/main/inswapper_128.onnx && \
    wget -O /home/webui-user/webui/models/flux_realism_lora.safetensors https://huggingface.co/XLabs-AI/flux-RealismLora/resolve/main/lora.safetensors && \
    rm -rf /tmp/* /var/tmp/*

# Install Tailscale for SSH
RUN echo "$TAILSCALE_AUTH_KEY" | sudo -S sh -c 'curl -fsSL https://tailscale.com/install.sh | sudo sh'
# Expose necessary ports for WebUI and Tailscale SSH
EXPOSE 7860 22

# Entrypoint to run both WebUI and Tailscale
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Use webui-user to run the WebUI
USER webui-user

# Set environment variables for GPU and WebUI
ENV CUDA_VISIBLE_DEVICES=all
ENV WEBUI_FLAGS="--precision full --no-half"

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]
