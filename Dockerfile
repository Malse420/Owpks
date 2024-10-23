# Use the base image for AUTOMATIC1111 from geeklord
FROM geeklord/automatic1111-sd-webui

# Set environment variables if needed
ENV PYTHONUNBUFFERED=1

RUN apt-get -y install libgl1-mesa-glx && apt-get clean

# Install necessary dependencies for Roop extensions
RUN pip install insightface==0.7.3

# Expose the default port for the web UI
EXPOSE 7860

# Start the web UI
CMD ["python", "launch.py", "--listen"]
