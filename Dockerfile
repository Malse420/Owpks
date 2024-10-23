# Use the base image for AUTOMATIC1111 from geeklord
FROM geeklord/automatic1111-sd-webui

# Set environment variables if needed
ENV PYTHONUNBUFFERED=1

RUN apt-get -y install libgl1-mesa-glx && apt-get clean

# Install necessary dependencies for Roop extensions
RUN pip install insightface==0.7.3

# Install the Roop uncensored extension into the extensions folder
RUN git clone https://github.com/P2Enjoy/sd-webui-roop-uncensored extensions/sd-webui-roop-uncensored

# Install the Roop-GE (NSFW) extension into the extensions folder
RUN git clone https://github.com/Gourieff/sd-webui-roop-nsfw extensions/sd-webui-roop-ge

# Install Civitai Helper extension into the extensions folder
RUN git clone https://github.com/butaixianran/Stable-Diffusion-Webui-Civitai-Helper extensions/civitai-helper

# Install Civitai Browser+ into the extensions folder for browsing models
RUN git clone https://github.com/BlafKing/sd-civitai-browser-plus extensions/civitai-browser-plus

# Expose the default port for the web UI
EXPOSE 7860

# Start the web UI
CMD ["python", "launch.py", "--listen"]
