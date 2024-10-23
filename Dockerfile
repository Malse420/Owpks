# Base image with CUDA 11.7 and cuDNN8 for GPU acceleration
FROM nvidia/cuda:11.7.1-cudnn8-runtime-ubuntu20.04

# Set environment variables for non-interactive installs and timezone
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Chicago
ENV CUDA_VISIBLE_DEVICES=all
ENV WEBUI_FLAGS="--precision full --no-half --skip-torch-cuda-test"
ENV PATH="/root/.local/bin:$PATH"

# Step 1: Install prerequisites for adding PPAs and system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common wget git curl sudo ffmpeg \
    libgl1 libglib2.0-0 libgoogle-perftools-dev iproute2

# Step 2: Add the Deadsnakes PPA for Python 3.10
RUN add-apt-repository ppa:deadsnakes/ppa && apt-get update

# Step 3: Install Python 3.10 and required libraries
RUN apt-get install -y --no-install-recommends \
    python3.10 python3.10-distutils python3.10-venv && \
    ln -sf /usr/bin/python3.10 /usr/bin/python && \
    ln -sf /usr/bin/python3.10 /usr/bin/python3

# Step 4: Install pip for Python 3.10
RUN wget https://bootstrap.pypa.io/get-pip.py && python3.10 get-pip.py && rm get-pip.py

# Install PyTorch with CUDA support for GPU acceleration
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu117

# Install insightface
RUN wget https://huggingface.co/deauxpas/colabrepo/resolve/main/insightface-0.7.3-cp310-cp310-linux_x86_64.whl && \
    pip install insightface-0.7.3-cp310-cp310-linux_x86_64.whl

# Add Tailscale repository
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list && \
    apt-get update && apt-get install -y tailscale

# Clone the AUTOMATIC1111 Stable Diffusion WebUI repository
WORKDIR /root
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git webui

RUN sed -i 's/--refetch//g' /root/webui/modules/launch_utils.py
# Install dependencies for Stable Diffusion WebUI
WORKDIR /root/webui
RUN pip install --no-cache-dir -r requirements.txt

# Install Roop Uncensored extension and its dependencies
RUN git clone https://github.com/s0md3v/sd-webui-roop.git extensions/sd-webui-roop && \
    pip install --no-cache-dir insightface

# Download Roop models
RUN mkdir -p models/roop/ && \
    wget -O models/roop/simswapper_512_beta.onnx https://huggingface.co/netrunner-exe/Insight-Swap-models-onnx/resolve/main/simswap_512_beta.onnx && \
    wget -O models/roop/inswapper_128.onnx https://huggingface.co/ezioruan/inswapper_128.onnx/resolve/main/inswapper_128.onnx && \
    wget -O models/flux_realism_lora.safetensors https://huggingface.co/XLabs-AI/flux-RealismLora/resolve/main/lora.safetensors && \
    rm -rf /tmp/* /var/tmp/*

# Ensure FastAPI and Pydantic compatibility
RUN pip install --no-cache-dir "fastapi==0.99.0" "pydantic==1.10.9"

# Expose necessary ports
EXPOSE 7860 22

# Copy entrypoint script and make it executable
COPY entrypoint.sh /root/entrypoint.sh
RUN chmod +x /root/entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/root/entrypoint.sh"]
