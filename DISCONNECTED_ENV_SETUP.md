# Disconnected Environment Setup Guide

This guide helps you configure and deploy the Cilium test applications in an air-gapped/disconnected environment with private Artifactory and GitLab.

> **💡 Build Strategy Decision:** Before starting, decide whether to [build images in public environment and transfer](IMAGE_BUILD_STRATEGY.md) or build directly in private environment. See [IMAGE_BUILD_STRATEGY.md](IMAGE_BUILD_STRATEGY.md) for detailed comparison and recommendations.

## Prerequisites

- Private Artifactory instance with Docker registry
- Private GitLab instance
- Kubernetes cluster with Cilium CNI
- Docker build environment with access to private registry
- Helm 3.0+ installed

## Step 1: Configure Private Registry Access

### Option A: Configure Docker Daemon Registry Mirror (Recommended)

Edit `/etc/docker/daemon.json` (Linux) or Docker Desktop settings:

```json
{
  "registry-mirrors": [
    "https://artifactory.yourcompany.local/docker"
  ],
  "insecure-registries": [
    "artifactory.yourcompany.local"
  ]
}
```

Restart Docker daemon:
```bash
sudo systemctl restart docker  # Linux
# Or restart Docker Desktop on Mac/Windows
```

### Option B: Use Full Registry Paths in Dockerfiles

Update all Dockerfiles to use full registry paths:
- `frontend/Dockerfile`: `FROM artifactory.yourcompany.local/docker/node:18-alpine`
- `backend/Dockerfile`: `FROM artifactory.yourcompany.local/docker/python:3.11-slim`
- `error-generator/Dockerfile`: Update both `golang` and `alpine` base images
- `logging-service/Dockerfile`: `FROM artifactory.yourcompany.local/docker/node:18-alpine`

## Step 2: Prepare Base Images in Private Registry

Ensure these base images are available in your Artifactory:

```bash
# Pull from public registry (if you have internet access temporarily)
docker pull node:18-alpine
docker pull python:3.11-slim
docker pull golang:1.21-alpine
docker pull alpine:latest
docker pull postgres:15-alpine
docker pull curlimages/curl:latest

# Tag for your private registry
docker tag node:18-alpine artifactory.yourcompany.local/docker/node:18-alpine
docker tag python:3.11-slim artifactory.yourcompany.local/docker/python:3.11-slim
docker tag golang:1.21-alpine artifactory.yourcompany.local/docker/golang:1.21-alpine
docker tag alpine:latest artifactory.yourcompany.local/docker/alpine:latest
docker tag postgres:15-alpine artifactory.yourcompany.local/docker/postgres:15-alpine
docker tag curlimages/curl:latest artifactory.yourcompany.local/docker/curlimages/curl:latest

# Push to private registry
docker push artifactory.yourcompany.local/docker/node:18-alpine
docker push artifactory.yourcompany.local/docker/python:3.11-slim
docker push artifactory.yourcompany.local/docker/golang:1.21-alpine
docker push artifactory.yourcompany.local/docker/alpine:latest
docker push artifactory.yourcompany.local/docker/postgres:15-alpine
docker push artifactory.yourcompany.local/docker/curlimages/curl:latest
```

## Step 3: Configure Build Script

Edit `build-images.sh`:

```bash
# Set your default registry
DEFAULT_REGISTRY="artifactory.yourcompany.local/docker"
```

Or use when building:
```bash
./build-images.sh artifactory.yourcompany.local/docker
```

## Step 4: Build and Push Application Images

```bash
# Login to your private registry
docker login artifactory.yourcompany.local

# Build images with registry prefix
./build-images.sh artifactory.yourcompany.local/docker

# Push all images
docker push artifactory.yourcompany.local/docker/frontend-service:latest
docker push artifactory.yourcompany.local/docker/backend-service:latest
docker push artifactory.yourcompany.local/docker/error-generator-service:latest
docker push artifactory.yourcompany.local/docker/logging-service:latest
```

## Step 5: Configure Helm Values

Edit `helm/cilium-test-apps/values.yaml`:

```yaml
global:
  # Set your private Artifactory registry
  imageRegistry: "artifactory.yourcompany.local/docker"
  imagePullPolicy: Always  # or IfNotPresent

database:
  image:
    repository: postgres  # Will become artifactory.yourcompany.local/docker/postgres
    tag: "15-alpine"

backend:
  image:
    repository: backend-service  # Will become artifactory.yourcompany.local/docker/backend-service
    tag: "latest"

frontend:
  image:
    repository: frontend-service
    tag: "latest"

errorGenerator:
  image:
    repository: error-generator-service
    tag: "latest"

loggingService:
  image:
    repository: logging-service
    tag: "latest"

trafficGenerator:
  image:
    repository: curlimages/curl
    tag: "latest"
```

## Step 6: Configure Kubernetes Image Pull Secrets (If Required)

If your registry requires authentication:

```bash
# Create image pull secret
kubectl create secret docker-registry artifactory-registry-secret \
  --docker-server=artifactory.yourcompany.local \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email> \
  --namespace=frontend-ns

# Repeat for other namespaces
kubectl create secret docker-registry artifactory-registry-secret \
  --docker-server=artifactory.yourcompany.local \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email> \
  --namespace=backend-ns

kubectl create secret docker-registry artifactory-registry-secret \
  --docker-server=artifactory.yourcompany.local \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email> \
  --namespace=database-ns

kubectl create secret docker-registry artifactory-registry-secret \
  --docker-server=artifactory.yourcompany.local \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email> \
  --namespace=shared-ns
```

Then update Helm templates to reference the secret (add to each deployment template):
```yaml
spec:
  imagePullSecrets:
  - name: artifactory-registry-secret
  containers:
  ...
```

## Step 7: Deploy with Helm

```bash
# Install with configured values
helm install cilium-test-apps ./helm/cilium-test-apps

# Or use a custom values file
helm install cilium-test-apps ./helm/cilium-test-apps -f my-disconnected-values.yaml
```

## Step 8: Verify Deployment

```bash
# Check pods are pulling from correct registry
kubectl describe pod <pod-name> -n <namespace>

# Check image pull status
kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}'
```

## Configuration Checklist

- [ ] Docker daemon configured with registry mirror OR Dockerfiles updated with full registry paths
- [ ] Base images (node, python, golang, alpine, postgres, curl) available in private registry
- [ ] Application images built and pushed to private registry
- [ ] `build-images.sh` configured with default registry
- [ ] `helm/cilium-test-apps/values.yaml` updated with `global.imageRegistry`
- [ ] Image pull secrets created (if registry requires authentication)
- [ ] Helm chart deployed successfully
- [ ] All pods running and pulling images from private registry

## Troubleshooting

### Images Not Pulling

1. Check registry URL is correct in values.yaml
2. Verify image pull secrets are created and referenced
3. Check pod events: `kubectl describe pod <pod-name> -n <namespace>`
4. Verify network connectivity to registry from cluster nodes

### Build Failures

1. Ensure Docker can access private registry: `docker pull artifactory.yourcompany.local/docker/node:18-alpine`
2. Check Docker daemon registry mirror configuration
3. Verify base images exist in private registry

### Authentication Issues

1. Create image pull secrets in all namespaces
2. Update Helm templates to reference secrets
3. Verify credentials are correct: `docker login artifactory.yourcompany.local`

## GitLab CI/CD Integration (Optional)

If using GitLab CI/CD, create `.gitlab-ci.yml`:

```yaml
variables:
  REGISTRY: artifactory.yourcompany.local/docker

build:
  stage: build
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $REGISTRY
    - ./build-images.sh $REGISTRY
    - docker push $REGISTRY/frontend-service:latest
    - docker push $REGISTRY/backend-service:latest
    - docker push $REGISTRY/error-generator-service:latest
    - docker push $REGISTRY/logging-service:latest
```

## Additional Notes

- All configuration points are marked with `CONFIGURATION REQUIRED FOR DISCONNECTED ENV:` comments
- The Helm chart automatically prefixes image names with `global.imageRegistry` if set
- Consider using image tags instead of `latest` for production deployments
- Set up image scanning in Artifactory for security compliance

