# Base image with CUDA 11.7 and cuDNN8
FROM nvidia/cuda:11.7.1-cudnn8-runtime-ubuntu20.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget git python3 python3-pip libgl1 libglib2.0-0 curl libgoogle-perftools-dev sudo && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PyTorch with CUDA
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu117

# Create a non-root user to avoid running processes as root
RUN useradd -m webui-user

# Switch to the new user
USER webui-user
WORKDIR /home/webui-user

# Clone the AUTOMATIC1111 Stable Diffusion WebUI
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git /home/webui-user/webui

# Install Stable Diffusion WebUI dependencies
WORKDIR /home/webui-user/webui
RUN pip install -r requirements.txt

# Install Roop Uncensored extension
RUN git clone https://github.com/s0md3v/sd-webui-roop.git extensions/sd-webui-roop

# Install the required insightface library for Roop extension
RUN pip install insightface==0.7.3

# Create the models directory for Roop and download simswapper_512_beta.onnx
RUN mkdir -p /home/webui-user/webui/models/roop/ && \
    wget -O /home/webui-user/webui/models/roop/simswapper_512_beta.onnx https://huggingface.co/netrunner-exe/Insight-Swap-models-onnx/resolve/8d4ab0b123254fc1c5a37f3a7f3188a80ecf0459/simswap_512_beta.onnx?download=true

# Optional: Download inswapper_128.onnx in case of 'NoneType' errors
RUN wget -O /home/webui-user/webui/models/roop/inswapper_128.onnx https://huggingface.co/path-to-inswapper-model/inswapper_128.onnx

# Install Tailscale for SSH
RUN curl -fsSL https://tailscale.com/install.sh | sudo sh

# Expose necessary ports for WebUI and Tailscale SSH
EXPOSE 7860 22

# Entrypoint to run both WebUI and Tailscale
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Use webui-user to run the WebUI
USER webui-user

# Set environment variables for GPU and WebUI
ENV CUDA_VISIBLE_DEVICES=0
ENV WEBUI_FLAGS="--precision full --no-half"

ENTRYPOINT ["/entrypoint.sh"]
