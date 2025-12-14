# Cilium Test Apps Helm Chart

This Helm chart deploys the Cilium CNI test applications across multiple Kubernetes namespaces.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Cilium CNI installed (for network policy testing)

## Installation

### Quick Start

```bash
# Install with default values
helm install cilium-test-apps ./helm/cilium-test-apps

# Install with custom values
helm install cilium-test-apps ./helm/cilium-test-apps -f my-values.yaml
```

### Using a Container Registry

If your images are in a container registry, update the `values.yaml`:

```yaml
global:
  imageRegistry: "your-registry.io"

frontend:
  image:
    repository: frontend-service
    tag: "v1.0.0"
```

Or use `--set` flags:

```bash
helm install cilium-test-apps ./helm/cilium-test-apps \
  --set global.imageRegistry=your-registry.io \
  --set frontend.image.tag=v1.0.0
```

## Configuration

The following table lists the configurable parameters and their default values:

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imageRegistry` | Global Docker image registry | `""` |
| `global.imagePullPolicy` | Global image pull policy | `IfNotPresent` |
| `global.labels` | Global labels applied to all resources | `{purpose: cilium-testing}` |

### Namespace Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespaces.frontend.name` | Frontend namespace name | `frontend-ns` |
| `namespaces.frontend.create` | Create frontend namespace | `true` |
| `namespaces.backend.name` | Backend namespace name | `backend-ns` |
| `namespaces.backend.create` | Create backend namespace | `true` |
| `namespaces.database.name` | Database namespace name | `database-ns` |
| `namespaces.database.create` | Create database namespace | `true` |
| `namespaces.shared.name` | Shared namespace name | `shared-ns` |
| `namespaces.shared.create` | Create shared namespace | `true` |

### Database Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `database.enabled` | Enable database deployment | `true` |
| `database.image.repository` | Database image repository | `postgres` |
| `database.image.tag` | Database image tag | `15-alpine` |
| `database.replicas` | Number of database replicas | `1` |
| `database.service.name` | Database service name | `postgres-service` |
| `database.service.port` | Database service port | `5432` |
| `database.credentials.user` | Database user | `postgres` |
| `database.credentials.password` | Database password | `postgres` |
| `database.credentials.database` | Database name | `testdb` |
| `database.resources` | Database resource requests/limits | See values.yaml |

### Backend Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `backend.enabled` | Enable backend deployment | `true` |
| `backend.image.repository` | Backend image repository | `backend-service` |
| `backend.image.tag` | Backend image tag | `latest` |
| `backend.replicas` | Number of backend replicas | `2` |
| `backend.service.name` | Backend service name | `backend-service` |
| `backend.service.port` | Backend service port | `8080` |
| `backend.env.dbHost` | Database host | `postgres-service.database-ns.svc.cluster.local` |
| `backend.env.dbPort` | Database port | `5432` |
| `backend.env.dbName` | Database name | `testdb` |
| `backend.env.dbUser` | Database user | `postgres` |
| `backend.env.dbPassword` | Database password | `postgres` |
| `backend.env.loggingServiceUrl` | Logging service URL | `http://logging-service.shared-ns.svc.cluster.local:5000` |
| `backend.resources` | Backend resource requests/limits | See values.yaml |

### Frontend Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `frontend.enabled` | Enable frontend deployment | `true` |
| `frontend.image.repository` | Frontend image repository | `frontend-service` |
| `frontend.image.tag` | Frontend image tag | `latest` |
| `frontend.replicas` | Number of frontend replicas | `2` |
| `frontend.service.name` | Frontend service name | `frontend-service` |
| `frontend.service.port` | Frontend service port | `3000` |
| `frontend.env.backendUrl` | Backend service URL | `http://backend-service.backend-ns.svc.cluster.local:8080` |
| `frontend.env.errorGeneratorUrl` | Error generator service URL | `http://error-generator-service.shared-ns.svc.cluster.local:4000` |
| `frontend.resources` | Frontend resource requests/limits | See values.yaml |

### Error Generator Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `errorGenerator.enabled` | Enable error generator deployment | `true` |
| `errorGenerator.image.repository` | Error generator image repository | `error-generator-service` |
| `errorGenerator.image.tag` | Error generator image tag | `latest` |
| `errorGenerator.replicas` | Number of error generator replicas | `1` |
| `errorGenerator.service.name` | Error generator service name | `error-generator-service` |
| `errorGenerator.service.port` | Error generator service port | `4000` |
| `errorGenerator.resources` | Error generator resource requests/limits | See values.yaml |

### Logging Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `loggingService.enabled` | Enable logging service deployment | `true` |
| `loggingService.image.repository` | Logging service image repository | `logging-service` |
| `loggingService.image.tag` | Logging service image tag | `latest` |
| `loggingService.replicas` | Number of logging service replicas | `1` |
| `loggingService.service.name` | Logging service name | `logging-service` |
| `loggingService.service.port` | Logging service port | `5000` |
| `loggingService.resources` | Logging service resource requests/limits | See values.yaml |

### Traffic Generator Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `trafficGenerator.enabled` | Enable traffic generator deployment | `true` |
| `trafficGenerator.image.repository` | Traffic generator image repository | `curlimages/curl` |
| `trafficGenerator.image.tag` | Traffic generator image tag | `latest` |
| `trafficGenerator.replicas` | Number of traffic generator replicas | `1` |
| `trafficGenerator.resources` | Traffic generator resource requests/limits | See values.yaml |

## Examples

### Example 1: Custom Image Registry

```yaml
global:
  imageRegistry: "registry.example.com"

frontend:
  image:
    repository: frontend-service
    tag: "v1.0.0"
```

```bash
helm install cilium-test-apps ./helm/cilium-test-apps -f custom-registry.yaml
```

### Example 2: Scale Services

```yaml
frontend:
  replicas: 5

backend:
  replicas: 5
```

```bash
helm install cilium-test-apps ./helm/cilium-test-apps -f scale.yaml
```

### Example 3: Custom Database Credentials

```yaml
database:
  credentials:
    user: myuser
    password: mysecurepassword
    database: mydb
```

```bash
helm install cilium-test-apps ./helm/cilium-test-apps -f custom-db.yaml
```

### Example 4: Disable Specific Services

```yaml
trafficGenerator:
  enabled: false

errorGenerator:
  enabled: false
```

### Example 5: Custom Resource Limits

```yaml
frontend:
  resources:
    requests:
      memory: "256Mi"
      cpu: "200m"
    limits:
      memory: "512Mi"
      cpu: "1000m"
```

## Upgrading

```bash
# Upgrade with new values
helm upgrade cilium-test-apps ./helm/cilium-test-apps -f new-values.yaml

# Upgrade with set flags
helm upgrade cilium-test-apps ./helm/cilium-test-apps \
  --set frontend.replicas=5 \
  --set backend.replicas=5
```

## Uninstalling

```bash
helm uninstall cilium-test-apps
```

This will remove all resources created by the Helm chart. If you want to keep namespaces, set `namespaces.*.create: false` before uninstalling.

## Troubleshooting

### Check Chart Values

```bash
# View computed values
helm get values cilium-test-apps

# View all values (including defaults)
helm get values cilium-test-apps --all
```

### Validate Chart

```bash
# Dry run to see what would be deployed
helm install cilium-test-apps ./helm/cilium-test-apps --dry-run --debug

# Template rendering
helm template cilium-test-apps ./helm/cilium-test-apps
```

### Check Deployment Status

```bash
# Check release status
helm status cilium-test-apps

# Check pod status
kubectl get pods -A -l app.kubernetes.io/instance=cilium-test-apps
```

## Notes

- The chart automatically constructs service URLs based on namespace and service names
- All services include health checks (liveness and readiness probes)
- Resource limits are set by default but can be customized
- The traffic generator uses service DNS names that are automatically generated from values

