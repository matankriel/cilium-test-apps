#!/bin/bash

# Script to import and push images in private environment
# Usage: ./scripts/import-images.sh [registry] [image-tar-file]

set -e

REGISTRY=${1:-"artifactory.yourcompany.local/docker"}
IMAGE_TAR=${2:-"./transfer/cilium-test-apps-images-*.tar.gz"}

echo "=========================================="
echo "Image Import and Push"
echo "=========================================="
echo "Registry: $REGISTRY"
echo "Image File: $IMAGE_TAR"
echo ""

# Find the actual tar file
TAR_FILE=$(ls -t $IMAGE_TAR 2>/dev/null | head -1)

if [ -z "$TAR_FILE" ] || [ ! -f "$TAR_FILE" ]; then
    echo "Error: Image tar file not found: $IMAGE_TAR"
    echo "Please provide the path to the image tar file"
    exit 1
fi

echo "Using file: $TAR_FILE"
echo ""

# Verify checksum if available
CHECKSUM_FILE="${TAR_FILE}.sha256"
if [ -f "$CHECKSUM_FILE" ]; then
    echo "Step 1: Verifying checksum..."
    sha256sum -c "$CHECKSUM_FILE"
    if [ $? -eq 0 ]; then
        echo "✓ Checksum verified"
    else
        echo "✗ Checksum verification failed!"
        exit 1
    fi
    echo ""
fi

# Load images
echo "Step 2: Loading images from tar file..."
docker load -i "$TAR_FILE"
echo "✓ Images loaded"
echo ""

# Login to registry
echo "Step 3: Logging in to registry..."
echo "Please enter your registry credentials:"
docker login $REGISTRY
echo ""

# Push images
echo "Step 4: Pushing images to registry..."
docker push $REGISTRY/frontend-service:latest && echo "✓ frontend-service pushed" || echo "✗ frontend-service push failed"
docker push $REGISTRY/backend-service:latest && echo "✓ backend-service pushed" || echo "✗ backend-service push failed"
docker push $REGISTRY/error-generator-service:latest && echo "✓ error-generator-service pushed" || echo "✗ error-generator-service push failed"
docker push $REGISTRY/logging-service:latest && echo "✓ logging-service pushed" || echo "✗ logging-service push failed"
echo ""

# Verify images in registry
echo "Step 5: Verifying images..."
echo "Images in registry:"
docker images | grep $REGISTRY | grep -E "(frontend|backend|error-generator|logging)-service"
echo ""

echo "=========================================="
echo "Import Complete"
echo "=========================================="
echo "Images are now available in registry: $REGISTRY"
echo ""
echo "Next steps:"
echo "1. Update helm/cilium-test-apps/values.yaml with registry: $REGISTRY"
echo "2. Deploy with Helm: helm install cilium-test-apps ./helm/cilium-test-apps"
echo ""

