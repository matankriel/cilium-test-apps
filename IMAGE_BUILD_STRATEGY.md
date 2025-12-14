# Docker Image Build Strategy for Disconnected Environments

This guide helps you decide whether to build images in a public environment and transfer them, or build directly in your private environment.

## Quick Answer

**Recommended: Build in public environment and transfer** (if you have a secure transfer mechanism)

**Alternative: Build in private environment** (if you have build tools and base images available)

## Comparison

### Option 1: Build in Public Environment → Transfer to Private

**Pros:**
- ✅ Faster initial setup (internet access for dependencies)
- ✅ Easier to pull base images from public registries
- ✅ Can use CI/CD pipelines with internet access
- ✅ Better for development/testing workflows
- ✅ Can leverage public npm/pip/go package repositories during build
- ✅ Easier to troubleshoot build issues

**Cons:**
- ❌ Requires secure transfer mechanism (air-gap transfer)
- ❌ Need to ensure images are scanned before transfer
- ❌ Additional step in deployment process
- ❌ Must manage image versioning and transfer logs

**Best For:**
- Environments with secure air-gap transfer capabilities
- When you need to leverage public package repositories
- Development and testing workflows
- When base images are already in public registry

### Option 2: Build in Private Environment

**Pros:**
- ✅ No transfer step required
- ✅ Images never leave your network
- ✅ Better security (no external exposure)
- ✅ Simpler deployment process
- ✅ Full control over build environment

**Cons:**
- ❌ Requires all base images pre-loaded in private registry
- ❌ Requires all dependencies (npm packages, pip packages, go modules) pre-downloaded
- ❌ Slower initial setup
- ❌ More complex dependency management
- ❌ May need to mirror package repositories (npm, PyPI, etc.)

**Best For:**
- Highly secure environments with strict air-gap requirements
- When you have comprehensive private registry with all dependencies
- Production environments with strict compliance requirements
- When transfer mechanisms are not available

## Recommended Approach: Hybrid Strategy

**For Most Organizations: Build in Public → Transfer**

### Step-by-Step: Build in Public Environment

#### 1. Build Images in Public Environment

```bash
# In your public/connected environment
cd /path/to/cilium-test-apps

# Build all images
./build-images.sh

# Or build with registry prefix for your private registry
./build-images.sh artifactory.yourcompany.local/docker

# Tag images for your private registry
docker tag frontend-service:latest artifactory.yourcompany.local/docker/frontend-service:latest
docker tag backend-service:latest artifactory.yourcompany.local/docker/backend-service:latest
docker tag error-generator-service:latest artifactory.yourcompany.local/docker/error-generator-service:latest
docker tag logging-service:latest artifactory.yourcompany.local/docker/logging-service:latest
```

#### 2. Save Images to Tar Files

```bash
# Save all application images
docker save \
  artifactory.yourcompany.local/docker/frontend-service:latest \
  artifactory.yourcompany.local/docker/backend-service:latest \
  artifactory.yourcompany.local/docker/error-generator-service:latest \
  artifactory.yourcompany.local/docker/logging-service:latest \
  -o cilium-test-apps-images.tar

# Also save base images if not already in private registry
docker save \
  node:18-alpine \
  python:3.11-slim \
  golang:1.21-alpine \
  alpine:latest \
  postgres:15-alpine \
  curlimages/curl:latest \
  -o cilium-test-apps-base-images.tar

# Compress for transfer (optional but recommended)
gzip cilium-test-apps-images.tar
gzip cilium-test-apps-base-images.tar
```

#### 3. Transfer Images to Private Environment

**Option A: Using Secure Transfer (USB/Network)**

```bash
# Copy tar files to transfer medium
cp cilium-test-apps-images.tar.gz /path/to/transfer/medium/
cp cilium-test-apps-base-images.tar.gz /path/to/transfer/medium/

# In private environment, load images
docker load -i cilium-test-apps-images.tar.gz
docker load -i cilium-test-apps-base-images.tar.gz
```

**Option B: Using Artifactory Import (If Supported)**

```bash
# If Artifactory supports image import
# Upload tar files through Artifactory UI or API
curl -u username:password \
  -X PUT "https://artifactory.yourcompany.local/api/docker/docker-local/v2/frontend-service/manifests/latest" \
  -T frontend-service.tar
```

**Option C: Using Skopeo (Recommended for Registry-to-Registry)**

```bash
# Install skopeo in public environment
# Copy images directly between registries
skopeo copy docker://frontend-service:latest \
  docker://artifactory.yourcompany.local/docker/frontend-service:latest \
  --dest-tls-verify=false

# Or save to OCI format for transfer
skopeo copy docker://frontend-service:latest \
  oci:./images/frontend-service:latest
```

#### 4. Push to Private Registry

```bash
# In private environment, after loading images
docker login artifactory.yourcompany.local

docker push artifactory.yourcompany.local/docker/frontend-service:latest
docker push artifactory.yourcompany.local/docker/backend-service:latest
docker push artifactory.yourcompany.local/docker/error-generator-service:latest
docker push artifactory.yourcompany.local/docker/logging-service:latest
```

### Step-by-Step: Build in Private Environment

#### 1. Prepare Base Images in Private Registry

```bash
# In public environment, pull and save base images
docker pull node:18-alpine
docker pull python:3.11-slim
docker pull golang:1.21-alpine
docker pull alpine:latest
docker pull postgres:15-alpine
docker pull curlimages/curl:latest

# Save to tar
docker save node:18-alpine python:3.11-slim golang:1.21-alpine \
  alpine:latest postgres:15-alpine curlimages/curl:latest \
  -o base-images.tar

# Transfer and load in private environment
docker load -i base-images.tar

# Tag and push to private registry
docker tag node:18-alpine artifactory.yourcompany.local/docker/node:18-alpine
docker tag python:3.11-slim artifactory.yourcompany.local/docker/python:3.11-slim
docker tag golang:1.21-alpine artifactory.yourcompany.local/docker/golang:1.21-alpine
docker tag alpine:latest artifactory.yourcompany.local/docker/alpine:latest
docker tag postgres:15-alpine artifactory.yourcompany.local/docker/postgres:15-alpine
docker tag curlimages/curl:latest artifactory.yourcompany.local/docker/curlimages/curl:latest

docker push artifactory.yourcompany.local/docker/node:18-alpine
docker push artifactory.yourcompany.local/docker/python:3.11-slim
docker push artifactory.yourcompany.local/docker/golang:1.21-alpine
docker push artifactory.yourcompany.local/docker/alpine:latest
docker push artifactory.yourcompany.local/docker/postgres:15-alpine
docker push artifactory.yourcompany.local/docker/curlimages/curl:latest
```

#### 2. Prepare Dependencies (If Needed)

**For Node.js (frontend, logging-service):**
```bash
# In public environment, download npm packages
cd frontend
npm install --package-lock-only
# Copy node_modules or use npm pack to create tarballs
npm pack

# Transfer package files to private environment
# In private environment, install from local packages
npm install --offline
```

**For Python (backend):**
```bash
# In public environment, download pip packages
cd backend
pip download -r requirements.txt -d ./packages

# Transfer packages directory to private environment
# In private environment, install from local packages
pip install --no-index --find-links ./packages -r requirements.txt
```

**For Go (error-generator):**
```bash
# In public environment, download go modules
cd error-generator
go mod download
go mod vendor

# Transfer vendor directory to private environment
# Build with vendor directory
go build -mod=vendor -o error-generator main.go
```

#### 3. Update Dockerfiles for Offline Build

**Option A: Use Multi-stage with Pre-downloaded Dependencies**

```dockerfile
# frontend/Dockerfile
FROM artifactory.yourcompany.local/docker/node:18-alpine

WORKDIR /app

# Copy pre-downloaded package files
COPY package.json package-lock.json ./
COPY packages ./packages

# Install from local packages
RUN npm install --offline --no-audit

COPY app.js .

EXPOSE 3000

CMD ["node", "app.js"]
```

**Option B: Use Build Context with Dependencies**

```dockerfile
# Copy entire build context including dependencies
COPY . .
RUN npm install
```

#### 4. Build in Private Environment

```bash
# In private environment
cd /path/to/cilium-test-apps

# Build with private registry
./build-images.sh artifactory.yourcompany.local/docker

# Push to registry
docker push artifactory.yourcompany.local/docker/frontend-service:latest
docker push artifactory.yourcompany.local/docker/backend-service:latest
docker push artifactory.yourcompany.local/docker/error-generator-service:latest
docker push artifactory.yourcompany.local/docker/logging-service:latest
```

## Security Considerations

### Image Scanning

**Always scan images before transfer or deployment:**

```bash
# Using Trivy (in public environment)
trivy image frontend-service:latest

# Using Clair
clair-scanner --ip <scanner-ip> frontend-service:latest

# Export scan results
trivy image --format json --output scan-results.json frontend-service:latest
```

### Image Signing

**Sign images for integrity verification:**

```bash
# Using Docker Content Trust
export DOCKER_CONTENT_TRUST=1
docker push artifactory.yourcompany.local/docker/frontend-service:latest

# Or using Cosign
cosign sign artifactory.yourcompany.local/docker/frontend-service:latest
```

## Automation Scripts

### Transfer Script (Public → Private)

```bash
#!/bin/bash
# transfer-images.sh

REGISTRY="artifactory.yourcompany.local/docker"
TRANSFER_DIR="./transfer"

mkdir -p $TRANSFER_DIR

# Build images
./build-images.sh $REGISTRY

# Save images
docker save \
  $REGISTRY/frontend-service:latest \
  $REGISTRY/backend-service:latest \
  $REGISTRY/error-generator-service:latest \
  $REGISTRY/logging-service:latest \
  -o $TRANSFER_DIR/cilium-test-apps-images.tar

# Scan images (optional)
trivy image --format json --output $TRANSFER_DIR/scan-results.json \
  $REGISTRY/frontend-service:latest

# Compress
gzip $TRANSFER_DIR/cilium-test-apps-images.tar

echo "Images saved to $TRANSFER_DIR/"
echo "Transfer files to private environment and run:"
echo "  docker load -i cilium-test-apps-images.tar.gz"
echo "  docker push $REGISTRY/<image-name>:latest"
```

### Import Script (Private Environment)

```bash
#!/bin/bash
# import-images.sh

REGISTRY="artifactory.yourcompany.local/docker"
IMAGE_TAR="cilium-test-apps-images.tar.gz"

# Load images
docker load -i $IMAGE_TAR

# Login to registry
docker login $REGISTRY

# Push all images
docker push $REGISTRY/frontend-service:latest
docker push $REGISTRY/backend-service:latest
docker push $REGISTRY/error-generator-service:latest
docker push $REGISTRY/logging-service:latest

echo "Images imported and pushed to $REGISTRY"
```

## Decision Matrix

| Scenario | Recommended Approach |
|----------|---------------------|
| Have secure transfer mechanism | Build in public → Transfer |
| Strict air-gap, no transfer | Build in private |
| Need frequent updates | Build in public → Transfer |
| Compliance requires no external builds | Build in private |
| Limited build resources in private env | Build in public → Transfer |
| Have comprehensive private registry | Build in private |
| Development/testing phase | Build in public → Transfer |
| Production with strict security | Build in private (or scan thoroughly) |

## Best Practice Recommendation

**For most organizations: Use a hybrid approach**

1. **Development/Testing:** Build in public environment, transfer to private
2. **Production:** Build in private environment (or use CI/CD in private network)
3. **Base Images:** Always pre-load in private registry
4. **Security:** Always scan images regardless of build location
5. **Automation:** Use scripts to automate transfer and import process

## Next Steps

1. Choose your approach based on your environment constraints
2. Set up transfer mechanism (if using Option 1)
3. Prepare base images in private registry
4. Create automation scripts for your chosen approach
5. Document your process for your team

See [DISCONNECTED_ENV_SETUP.md](DISCONNECTED_ENV_SETUP.md) for complete setup instructions.

