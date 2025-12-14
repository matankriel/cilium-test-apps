#!/bin/bash

# Build script for all Docker images
# Usage: ./build-images.sh [registry]
#
# ============================================================================
# AIR-GAPPED / DISCONNECTED ENVIRONMENT CONFIGURATION
# ============================================================================
# For disconnected environments with private Artifactory:
# 1. Set REGISTRY to your private Artifactory registry URL
#    Example: ./build-images.sh artifactory.yourcompany.local/docker
# 2. Ensure Docker is configured to pull base images from your registry mirror
#    (Configure in /etc/docker/daemon.json or Docker Desktop settings)
# 3. Ensure you have access to push images to your private registry
# 4. After building, push images: docker push <registry>/<image>:<tag>
# ============================================================================

set -e

# CONFIGURATION REQUIRED FOR DISCONNECTED ENV:
# Set default registry to your private Artifactory if not provided as argument
# Example: DEFAULT_REGISTRY="artifactory.yourcompany.local/docker"
DEFAULT_REGISTRY=""

REGISTRY=${1:-${DEFAULT_REGISTRY}}
IMAGE_PREFIX=${REGISTRY:+${REGISTRY}/}

echo "Building Docker images..."
echo "Registry: ${REGISTRY:-'local'}"

# Build frontend
echo "Building frontend-service..."
cd frontend
docker build -t ${IMAGE_PREFIX}frontend-service:latest .
cd ..

# Build backend
echo "Building backend-service..."
cd backend
docker build -t ${IMAGE_PREFIX}backend-service:latest .
cd ..

# Build error-generator
echo "Building error-generator-service..."
cd error-generator
docker build -t ${IMAGE_PREFIX}error-generator-service:latest .
cd ..

# Build logging-service
echo "Building logging-service..."
cd logging-service
docker build -t ${IMAGE_PREFIX}logging-service:latest .
cd ..

echo "All images built successfully!"
echo ""
echo "Images:"
echo "  - ${IMAGE_PREFIX}frontend-service:latest"
echo "  - ${IMAGE_PREFIX}backend-service:latest"
echo "  - ${IMAGE_PREFIX}error-generator-service:latest"
echo "  - ${IMAGE_PREFIX}logging-service:latest"

if [ -n "$REGISTRY" ]; then
    echo ""
    echo "To push images to your private registry, run:"
    echo "  docker push ${IMAGE_PREFIX}frontend-service:latest"
    echo "  docker push ${IMAGE_PREFIX}backend-service:latest"
    echo "  docker push ${IMAGE_PREFIX}error-generator-service:latest"
    echo "  docker push ${IMAGE_PREFIX}logging-service:latest"
    echo ""
    echo "Note: Ensure you are authenticated to your private registry:"
    echo "  docker login ${REGISTRY}"
fi

