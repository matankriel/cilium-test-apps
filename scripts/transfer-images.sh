#!/bin/bash

# Script to build images in public environment and prepare for transfer
# Usage: ./scripts/transfer-images.sh [registry]

set -e

REGISTRY=${1:-"artifactory.yourcompany.local/docker"}
TRANSFER_DIR="./transfer"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "=========================================="
echo "Image Build and Transfer Preparation"
echo "=========================================="
echo "Registry: $REGISTRY"
echo "Transfer Directory: $TRANSFER_DIR"
echo ""

# Create transfer directory
mkdir -p $TRANSFER_DIR

# Build images
echo "Step 1: Building application images..."
./build-images.sh $REGISTRY

# Tag images if not already tagged
echo ""
echo "Step 2: Tagging images..."
docker tag frontend-service:latest $REGISTRY/frontend-service:latest 2>/dev/null || true
docker tag backend-service:latest $REGISTRY/backend-service:latest 2>/dev/null || true
docker tag error-generator-service:latest $REGISTRY/error-generator-service:latest 2>/dev/null || true
docker tag logging-service:latest $REGISTRY/logging-service:latest 2>/dev/null || true

# Save application images
echo ""
echo "Step 3: Saving application images to tar file..."
docker save \
  $REGISTRY/frontend-service:latest \
  $REGISTRY/backend-service:latest \
  $REGISTRY/error-generator-service:latest \
  $REGISTRY/logging-service:latest \
  -o $TRANSFER_DIR/cilium-test-apps-images-${TIMESTAMP}.tar

# Compress
echo ""
echo "Step 4: Compressing images..."
gzip $TRANSFER_DIR/cilium-test-apps-images-${TIMESTAMP}.tar

# Generate checksums
echo ""
echo "Step 5: Generating checksums..."
cd $TRANSFER_DIR
sha256sum cilium-test-apps-images-${TIMESTAMP}.tar.gz > cilium-test-apps-images-${TIMESTAMP}.tar.gz.sha256
cd ..

# Create manifest
echo ""
echo "Step 6: Creating transfer manifest..."
cat > $TRANSFER_DIR/MANIFEST.txt <<EOF
Cilium Test Apps Image Transfer Package
Generated: $(date)
Registry: $REGISTRY

Images included:
- frontend-service:latest
- backend-service:latest
- error-generator-service:latest
- logging-service:latest

Files:
- cilium-test-apps-images-${TIMESTAMP}.tar.gz
- cilium-test-apps-images-${TIMESTAMP}.tar.gz.sha256

Transfer Instructions:
1. Copy all files in this directory to your private environment
2. Verify checksum: sha256sum -c cilium-test-apps-images-${TIMESTAMP}.tar.gz.sha256
3. Load images: docker load -i cilium-test-apps-images-${TIMESTAMP}.tar.gz
4. Push to registry: Use scripts/import-images.sh or manually push each image
EOF

echo ""
echo "=========================================="
echo "Transfer Package Ready"
echo "=========================================="
echo "Location: $TRANSFER_DIR/"
echo ""
echo "Files created:"
ls -lh $TRANSFER_DIR/
echo ""
echo "Next steps:"
echo "1. Review MANIFEST.txt in $TRANSFER_DIR/"
echo "2. Transfer all files to your private environment"
echo "3. Run: ./scripts/import-images.sh in private environment"
echo ""

