# Configuration Checklist for Disconnected Environment

Use this checklist to ensure all configuration points are addressed for your air-gapped environment.

## Pre-Deployment Checklist

### 1. Docker Registry Configuration
- [ ] **Dockerfiles Updated** - All Dockerfiles have comments indicating registry configuration
  - [ ] `frontend/Dockerfile` - Node.js base image configured
  - [ ] `backend/Dockerfile` - Python base image configured
  - [ ] `error-generator/Dockerfile` - Golang and Alpine base images configured
  - [ ] `logging-service/Dockerfile` - Node.js base image configured
- [ ] **Docker Daemon Configured** - Registry mirror set in `/etc/docker/daemon.json` OR Dockerfiles use full registry paths
- [ ] **Base Images Available** - All base images pushed to private registry:
  - [ ] `node:18-alpine`
  - [ ] `python:3.11-slim`
  - [ ] `golang:1.21-alpine`
  - [ ] `alpine:latest`
  - [ ] `postgres:15-alpine`
  - [ ] `curlimages/curl:latest`

### 2. Build Script Configuration
- [ ] **build-images.sh** - `DEFAULT_REGISTRY` variable set to your Artifactory URL
- [ ] **Application Images Built** - All application images built with registry prefix
- [ ] **Images Pushed** - All application images pushed to private registry:
  - [ ] `frontend-service:latest`
  - [ ] `backend-service:latest`
  - [ ] `error-generator-service:latest`
  - [ ] `logging-service:latest`

### 3. Helm Chart Configuration
- [ ] **values.yaml** - `global.imageRegistry` set to your Artifactory URL
- [ ] **values.yaml** - `global.imagePullPolicy` configured appropriately
- [ ] **values.yaml** - All service image repositories configured
- [ ] **Chart.yaml** - Home URL updated to your GitLab repository (optional)

### 4. Kubernetes Configuration
- [ ] **Image Pull Secrets Created** - If registry requires authentication:
  - [ ] Secret created in `frontend-ns` namespace
  - [ ] Secret created in `backend-ns` namespace
  - [ ] Secret created in `database-ns` namespace
  - [ ] Secret created in `shared-ns` namespace
- [ ] **Network Access** - Cluster nodes can reach private registry
- [ ] **Registry Authentication** - Credentials verified and working

### 5. Deployment Verification
- [ ] **Helm Chart Validated** - `helm lint ./helm/cilium-test-apps` passes
- [ ] **Templates Rendered** - `helm template` shows correct image paths
- [ ] **Deployment Successful** - All pods start and pull images from private registry
- [ ] **Services Running** - All services healthy and communicating

## Configuration File Locations

| Configuration | File Location | Key Setting |
|--------------|---------------|-------------|
| Global Registry | `helm/cilium-test-apps/values.yaml` | `global.imageRegistry` |
| Frontend Image | `helm/cilium-test-apps/values.yaml` | `frontend.image.repository` |
| Backend Image | `helm/cilium-test-apps/values.yaml` | `backend.image.repository` |
| Database Image | `helm/cilium-test-apps/values.yaml` | `database.image.repository` |
| Error Generator Image | `helm/cilium-test-apps/values.yaml` | `errorGenerator.image.repository` |
| Logging Service Image | `helm/cilium-test-apps/values.yaml` | `loggingService.image.repository` |
| Traffic Generator Image | `helm/cilium-test-apps/values.yaml` | `trafficGenerator.image.repository` |
| Build Script Registry | `build-images.sh` | `DEFAULT_REGISTRY` |
| Frontend Base Image | `frontend/Dockerfile` | `FROM` statement |
| Backend Base Image | `backend/Dockerfile` | `FROM` statement |
| Error Generator Base Images | `error-generator/Dockerfile` | `FROM` statements |
| Logging Service Base Image | `logging-service/Dockerfile` | `FROM` statement |

## Quick Configuration Commands

```bash
# 1. Set registry in values.yaml
sed -i 's|imageRegistry: ""|imageRegistry: "artifactory.yourcompany.local/docker"|' helm/cilium-test-apps/values.yaml

# 2. Set default registry in build script
sed -i 's|DEFAULT_REGISTRY=""|DEFAULT_REGISTRY="artifactory.yourcompany.local/docker"|' build-images.sh

# 3. Build and push images
./build-images.sh artifactory.yourcompany.local/docker
docker push artifactory.yourcompany.local/docker/frontend-service:latest
docker push artifactory.yourcompany.local/docker/backend-service:latest
docker push artifactory.yourcompany.local/docker/error-generator-service:latest
docker push artifactory.yourcompany.local/docker/logging-service:latest

# 4. Deploy with Helm
helm install cilium-test-apps ./helm/cilium-test-apps
```

## Troubleshooting

If deployment fails, check:
1. Image pull errors in pod events: `kubectl describe pod <pod-name> -n <namespace>`
2. Registry connectivity: `kubectl run test --image=artifactory.yourcompany.local/docker/busybox --rm -it --restart=Never -- sh`
3. Image pull secrets: `kubectl get secrets -n <namespace>`
4. Helm values: `helm get values cilium-test-apps`

## Documentation References

- [Disconnected Environment Setup Guide](DISCONNECTED_ENV_SETUP.md) - Detailed setup instructions
- [Docker Registry Configuration](.docker-registry-config.md) - All configuration points
- [Helm Chart README](helm/cilium-test-apps/README.md) - Helm-specific documentation

