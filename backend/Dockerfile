# CONFIGURATION REQUIRED FOR DISCONNECTED ENV:
# Replace with your private Artifactory registry mirror for Python base image
# Example: FROM artifactory.yourcompany.local/docker/python:3.11-slim
# Or configure Docker daemon to use registry mirror (recommended)
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 8080

CMD ["python", "app.py"]

