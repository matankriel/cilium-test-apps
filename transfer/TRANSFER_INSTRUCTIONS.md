# Image Transfer Instructions

## Files in Transfer Package

- `cilium-test-apps-images-*.tar.gz` - Compressed Docker images (all 4 services)
- `cilium-test-apps-images-*.tar.gz.sha256` - Checksum file for verification
- `MANIFEST.txt` - Package manifest
- `TRANSFER_INSTRUCTIONS.md` - This file

## Step-by-Step Transfer Process

### 1. Transfer Files to Private Environment

Copy all files from the `transfer/` directory to your private environment using your secure transfer method (USB, network share, etc.)

### 2. Verify Checksum (In Private Environment)

```bash
cd /path/to/transferred/files
sha256sum -c cilium-test-apps-images-*.tar.gz.sha256
```

Expected output: `cilium-test-apps-images-*.tar.gz: OK`

### 3. Load Images

```bash
docker load -i cilium-test-apps-images-*.tar.gz
```

This will load all 4 images:
- frontend-service:latest
- backend-service:latest
- error-generator-service:latest
- logging-service:latest

### 4. Tag Images for Your Private Registry

Replace `<your-registry>` with your actual Artifactory registry URL:

```bash
REGISTRY="artifactory.yourcompany.local/docker"

docker tag frontend-service:latest ${REGISTRY}/frontend-service:latest
docker tag backend-service:latest ${REGISTRY}/backend-service:latest
docker tag error-generator-service:latest ${REGISTRY}/error-generator-service:latest
docker tag logging-service:latest ${REGISTRY}/logging-service:latest
```

### 5. Login to Your Private Registry

```bash
docker login artifactory.yourcompany.local
# Enter your credentials when prompted
```

### 6. Push Images to Registry

```bash
docker push ${REGISTRY}/frontend-service:latest
docker push ${REGISTRY}/backend-service:latest
docker push ${REGISTRY}/error-generator-service:latest
docker push ${REGISTRY}/logging-service:latest
```

### 7. Verify Images in Registry

```bash
docker images | grep ${REGISTRY}
```

### 8. Update Helm Values

Edit `helm/cilium-test-apps/values.yaml`:

```yaml
global:
  imageRegistry: "artifactory.yourcompany.local/docker"
```

### 9. Deploy with Helm

```bash
helm install cilium-test-apps ./helm/cilium-test-apps
```

## Quick Script (Alternative)

You can also use the provided import script:

```bash
./scripts/import-images.sh artifactory.yourcompany.local/docker
```

## Troubleshooting

### Checksum Verification Fails
- Re-transfer the files
- Ensure files weren't corrupted during transfer

### Docker Load Fails
- Check available disk space: `df -h`
- Verify Docker is running: `docker info`

### Push Fails
- Verify registry URL is correct
- Check authentication: `docker login <registry>`
- Ensure network connectivity to registry

### Images Not Found After Load
- List loaded images: `docker images`
- Verify tags: `docker images | grep -E "(frontend|backend|error|logging)"`
