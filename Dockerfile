# Base image with CUDA 11.7 and cuDNN8 for GPU acceleration
FROM nvidia/cuda:11.7.1-cudnn8-runtime-ubuntu20.04

# Set environment variables to avoid interactive tzdata configuration
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Chicago

# Install system dependencies, Python 3.10, and necessary libraries
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        wget git python3.10 python3.10-distutils python3.10-venv \
        libgl1 libglib2.0-0 curl libgoogle-perftools-dev sudo ffmpeg && \
    ln -sf /usr/bin/python3.10 /usr/bin/python3 && \
    ln -sf /usr/bin/python3.10 /usr/bin/python && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install pip for Python 3.10 and remove the installer after use
RUN wget https://bootstrap.pypa.io/get-pip.py && python3 get-pip.py && rm get-pip.py

# Install PyTorch with CUDA support for GPU acceleration
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu117

# Install the insightface package
RUN wget https://huggingface.co/deauxpas/colabrepo/resolve/main/insightface-0.7.3-cp310-cp310-linux_x86_64.whl && \
    pip install insightface-0.7.3-cp310-cp310-linux_x86_64.whl

# Create a non-root user to avoid running processes as root
RUN useradd -m webui-user

# Add .local/bin to the PATH for all users including root
RUN mkdir -p /root/.local/bin && mkdir -p /home/webui-user/.local/bin && \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> /etc/profile && \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> /etc/bash.bashrc && \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> /root/.bashrc && \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/webui-user/.bashrc

# Switch to the new user
USER webui-user
WORKDIR /home/webui-user

# Clone the AUTOMATIC1111 Stable Diffusion WebUI repository
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git /home/webui-user/webui

# Switch back to root to set up the entrypoint
USER root
COPY entrypoint.sh /home/webui-user/entrypoint.sh
RUN chown webui-user:webui-user /home/webui-user/entrypoint.sh
RUN chmod +x /home/webui-user/entrypoint.sh

# Allow all users and groups to use sudo without a password
RUN echo "ALL ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Switch back to the webui-user
USER webui-user
WORKDIR /home/webui-user/webui

# Install Stable Diffusion WebUI dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install Roop Uncensored extension
RUN git clone https://github.com/s0md3v/sd-webui-roop.git extensions/sd-webui-roop

# Install additional insightface library for Roop extension
RUN pip install --no-cache-dir insightface

# Create the models directory for Roop and download necessary models
RUN mkdir -p /home/webui-user/webui/models/roop/ && \
    wget -O /home/webui-user/webui/models/roop/simswapper_512_beta.onnx https://huggingface.co/netrunner-exe/Insight-Swap-models-onnx/resolve/main/simswap_512_beta.onnx && \
    wget -O /home/webui-user/webui/models/roop/inswapper_128.onnx https://huggingface.co/ezioruan/inswapper_128.onnx/resolve/main/inswapper_128.onnx && \
    wget -O /home/webui-user/webui/models/flux_realism_lora.safetensors https://huggingface.co/XLabs-AI/flux-RealismLora/resolve/main/lora.safetensors && \
    rm -rf /tmp/* /var/tmp/*

# Expose necessary ports for WebUI and Tailscale SSH
EXPOSE 7860 22

# Set environment variables for GPU and WebUI
ENV CUDA_VISIBLE_DEVICES=all
ENV WEBUI_FLAGS="--precision full --no-half --skip-torch-cuda-test"

# Set the entrypoint
ENTRYPOINT ["/home/webui-user/entrypoint.sh"]
