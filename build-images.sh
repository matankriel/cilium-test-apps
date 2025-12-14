#!/bin/bash

# Build script for all Docker images
# Usage: ./build-images.sh [registry]

set -e

REGISTRY=${1:-""}
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
    echo "To push images, run:"
    echo "  docker push ${IMAGE_PREFIX}frontend-service:latest"
    echo "  docker push ${IMAGE_PREFIX}backend-service:latest"
    echo "  docker push ${IMAGE_PREFIX}error-generator-service:latest"
    echo "  docker push ${IMAGE_PREFIX}logging-service:latest"
fi

