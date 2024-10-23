# Base image with CUDA 11.7 and cuDNN8 for GPU acceleration
FROM nvidia/cuda:11.7.1-cudnn8-runtime-ubuntu20.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Chicago

# Install system dependencies and Python 3.10
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget git python3.10 python3.10-venv python3.10-distutils \
    libgl1 libglib2.0-0 sudo ffmpeg curl \
    && ln -sf /usr/bin/python3.10 /usr/bin/python \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install pip
RUN wget https://bootstrap.pypa.io/get-pip.py && python get-pip.py && rm get-pip.py

# Clone Stable Diffusion WebUI
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git /home/webui-user/webui

# Install Python dependencies from requirements.txt
RUN pip install --no-cache-dir -r /home/webui-user/webui/requirements.txt

# Install PyTorch with CUDA support
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu117

# Expose ports and set entrypoint
EXPOSE 7860 22
COPY entrypoint.sh /home/webui-user/entrypoint.sh
RUN chmod +x /home/webui-user/entrypoint.sh
ENTRYPOINT ["/home/webui-user/entrypoint.sh"]
