# Cilium CNI Test Applications

This repository contains a comprehensive set of microservices designed to test Cilium CNI's observability features and network policies. The applications are deployed across multiple Kubernetes namespaces and generate both successful and error traffic patterns.

## Architecture

The test environment consists of the following services:

### Services Overview

1. **Frontend Service** (Node.js)
   - Namespace: `frontend-ns`
   - Port: 3000
   - Makes requests to backend API
   - Generates error requests via error generator
   - Supports stress testing with concurrent requests

2. **Backend API Service** (Python/Flask)
   - Namespace: `backend-ns`
   - Port: 8080
   - Connects to PostgreSQL database
   - Sends logs to logging service
   - Generates intentional errors (10% chance)
   - Has slow endpoint and error endpoint

3. **Database Service** (PostgreSQL)
   - Namespace: `database-ns`
   - Port: 5432
   - Stores test data and request logs
   - Initialized with sample data

4. **Error Generator Service** (Go)
   - Namespace: `shared-ns`
   - Port: 4000
   - Intentionally generates errors for testing
   - Supports random errors (30% chance)
   - Has timeout simulation endpoint

5. **Logging Service** (Node.js)
   - Namespace: `shared-ns`
   - Port: 5000
   - Receives logs from other services
   - Occasionally fails (5% chance) to test error visibility

6. **Traffic Generator** (curl-based)
   - Namespace: `frontend-ns`
   - Continuously generates traffic patterns
   - Makes both successful and error requests

## Network Traffic Patterns

The applications generate the following traffic patterns:

### Successful Traffic
- Frontend → Backend API calls
- Backend → Database queries
- Backend → Logging service
- Frontend → Error generator (sometimes successful)

### Error Traffic
- Frontend → Backend (10% error rate)
- Backend → Database connection failures
- Backend → Logging service failures (5% rate)
- Error generator random errors (30% rate)
- Intentional timeout scenarios

### Cross-Namespace Communication
- `frontend-ns` → `backend-ns`
- `backend-ns` → `database-ns`
- `backend-ns` → `shared-ns`
- `frontend-ns` → `shared-ns`

## Prerequisites

- Kubernetes cluster with Cilium CNI installed
- Docker or container runtime
- kubectl configured to access your cluster
- Docker images built and available (or use a container registry)

### For Disconnected/Air-Gapped Environments

If you're working in a disconnected environment with private Artifactory and GitLab, see:
- **[Image Build Strategy Guide](IMAGE_BUILD_STRATEGY.md)** - Decide whether to build in public and transfer, or build in private
- **[Disconnected Environment Setup Guide](DISCONNECTED_ENV_SETUP.md)** - Detailed configuration instructions
- **[Configuration Checklist](CONFIGURATION_CHECKLIST.md)** - Complete checklist for all configuration points

**Quick Decision:**
- **Build in public → Transfer:** Recommended for most cases (faster, easier dependency management)
- **Build in private:** Use when you have strict air-gap requirements or comprehensive private registry

**Quick Configuration Checklist:**
1. Choose build strategy (see [IMAGE_BUILD_STRATEGY.md](IMAGE_BUILD_STRATEGY.md))
2. Configure Docker registry mirror or update Dockerfiles with private registry paths
3. Set `global.imageRegistry` in `helm/cilium-test-apps/values.yaml` to your Artifactory URL
4. Build and push images to your private registry (or transfer from public environment)
5. Configure image pull secrets if authentication is required

## Building Docker Images

Before deploying, you need to build the Docker images for the custom services:

```bash
# Build frontend service
cd frontend
docker build -t frontend-service:latest .

# Build backend service
cd ../backend
docker build -t backend-service:latest .

# Build error generator service
cd ../error-generator
docker build -t error-generator-service:latest .

# Build logging service
cd ../logging-service
docker build -t logging-service:latest .
```

If using a container registry:

```bash
# Tag and push images
docker tag frontend-service:latest <registry>/frontend-service:latest
docker tag backend-service:latest <registry>/backend-service:latest
docker tag error-generator-service:latest <registry>/error-generator-service:latest
docker tag logging-service:latest <registry>/logging-service:latest

docker push <registry>/frontend-service:latest
docker push <registry>/backend-service:latest
docker push <registry>/error-generator-service:latest
docker push <registry>/logging-service:latest
```

Then update the image references in the Kubernetes manifests to use your registry.

## Deployment

### Option 1: Deploy with Helm (Recommended)

The Helm chart provides a single `values.yaml` file to configure all services easily.

```bash
# Install using default values
helm install cilium-test-apps ./helm/cilium-test-apps

# Install with custom values file
helm install cilium-test-apps ./helm/cilium-test-apps -f my-values.yaml

# Install with custom values
helm install cilium-test-apps ./helm/cilium-test-apps \
  --set frontend.replicas=3 \
  --set backend.replicas=3 \
  --set database.credentials.password=mysecretpassword

# Upgrade existing deployment
helm upgrade cilium-test-apps ./helm/cilium-test-apps

# Uninstall
helm uninstall cilium-test-apps
```

**Customizing Values:**

Edit `helm/cilium-test-apps/values.yaml` to configure:
- Image repositories and tags
- Replica counts
- Resource limits and requests
- Service ports
- Environment variables
- Namespace names
- Probe settings

See the [Helm Chart README](helm/cilium-test-apps/README.md) for detailed configuration options.

### Option 2: Deploy with kubectl (Direct Manifests)

```bash
# Deploy everything at once
kubectl apply -f k8s/all.yaml
```

### Option 3: Deploy Step by Step

```bash
# 1. Create namespaces
kubectl apply -f k8s/namespaces.yaml

# 2. Deploy database
kubectl apply -f k8s/database.yaml

# 3. Wait for database to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n database-ns --timeout=120s

# 4. Deploy backend
kubectl apply -f k8s/backend.yaml

# 5. Deploy shared services
kubectl apply -f k8s/shared-services.yaml

# 6. Deploy frontend
kubectl apply -f k8s/frontend.yaml

# 7. Deploy traffic generator
kubectl apply -f k8s/traffic-generator.yaml
```

## Verifying Deployment

Check that all pods are running:

```bash
kubectl get pods -n frontend-ns
kubectl get pods -n backend-ns
kubectl get pods -n database-ns
kubectl get pods -n shared-ns
```

Check services:

```bash
kubectl get svc -A | grep -E "(frontend|backend|postgres|error|logging)"
```

## Testing the Services

### Manual Testing

1. **Test Frontend Service:**
```bash
kubectl port-forward -n frontend-ns svc/frontend-service 3000:3000
curl http://localhost:3000/
curl http://localhost:3000/trigger-error
curl http://localhost:3000/stress-test?count=10
```

2. **Test Backend Service:**
```bash
kubectl port-forward -n backend-ns svc/backend-service 8080:8080
curl http://localhost:8080/api/data
curl http://localhost:8080/api/error
curl http://localhost:8080/api/slow?delay=2
```

3. **Test Error Generator:**
```bash
kubectl port-forward -n shared-ns svc/error-generator-service 4000:4000
curl http://localhost:4000/generate-error
curl http://localhost:4000/random-error
```

4. **Test Logging Service:**
```bash
kubectl port-forward -n shared-ns svc/logging-service 5000:5000
curl http://localhost:5000/metrics
```

### Viewing Logs

```bash
# Frontend logs
kubectl logs -n frontend-ns -l app=frontend -f

# Backend logs
kubectl logs -n backend-ns -l app=backend -f

# Error generator logs
kubectl logs -n shared-ns -l app=error-generator -f

# Logging service logs
kubectl logs -n shared-ns -l app=logging-service -f

# Traffic generator logs
kubectl logs -n frontend-ns -l app=traffic-generator -f
```

## Cilium Observability

With Cilium installed, you can observe:

1. **Flow Logs:**
```bash
# View Cilium flow logs
kubectl exec -n kube-system -it cilium-<pod-name> -- cilium monitor

# Or use Hubble (if installed)
hubble observe --namespace frontend-ns
hubble observe --namespace backend-ns
```

2. **Service Maps:**
```bash
# View service dependencies
hubble observe --follow --namespace frontend-ns
```

3. **Error Visibility:**
- Failed connections between services
- HTTP error responses (4xx, 5xx)
- Timeout scenarios
- Database connection failures

## Network Policies

Example Cilium Network Policies are provided in `k8s/network-policies-example.yaml`. These demonstrate:

1. **Allow policies:** Frontend to backend communication
2. **Restrictive policies:** Only backend can access database
3. **Namespace isolation:** Services in shared namespace can communicate
4. **Deny policies:** Block traffic from specific pods

To apply network policies:

```bash
kubectl apply -f k8s/network-policies-example.yaml
```

### Testing Network Policies

1. **Test allowed traffic:**
```bash
# This should work (frontend → backend)
kubectl exec -n frontend-ns -it deployment/frontend -- curl http://backend-service.backend-ns.svc.cluster.local:8080/health
```

2. **Test denied traffic:**
```bash
# This should fail if policies are applied (traffic-generator → backend)
kubectl exec -n frontend-ns -it deployment/traffic-generator -- curl http://backend-service.backend-ns.svc.cluster.local:8080/health
```

## Monitoring Traffic Patterns

### Using kubectl

```bash
# Watch pods across all namespaces
watch kubectl get pods -A

# Monitor service endpoints
kubectl get endpoints -A
```

### Using Cilium/Hubble

```bash
# Install Hubble CLI (if not already installed)
# See: https://docs.cilium.io/en/stable/operations/hubble/setup/

# Observe all traffic
hubble observe

# Filter by namespace
hubble observe --namespace frontend-ns

# Filter by service
hubble observe --to-service backend-service

# Filter errors only
hubble observe --verdict DROPPED
hubble observe --http-status 5xx
```

## Service Endpoints

All services expose the following endpoints:

### Frontend Service
- `GET /` - Main endpoint (calls backend)
- `GET /health` - Health check
- `GET /trigger-error` - Trigger error scenario
- `GET /stress-test?count=N` - Generate concurrent requests
- `GET /metrics` - Service metrics

### Backend Service
- `GET /api/data` - Get data from database
- `GET /api/error` - Always returns error
- `GET /api/slow?delay=N` - Slow response endpoint
- `GET /health` - Health check
- `GET /metrics` - Service metrics

### Error Generator Service
- `GET /health` - Health check
- `GET /generate-error` - Generate error
- `GET /random-error` - Random error (30% chance)
- `GET /timeout` - Simulate timeout
- `GET /metrics` - Service metrics

### Logging Service
- `POST /log` - Receive log entry
- `GET /logs` - Get log statistics
- `GET /health` - Health check
- `GET /metrics` - Service metrics

## Troubleshooting

### Pods not starting
```bash
# Check pod status
kubectl describe pod <pod-name> -n <namespace>

# Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

### Services not communicating
```bash
# Check service endpoints
kubectl get endpoints -n <namespace>

# Test connectivity from pod
kubectl exec -n <namespace> -it <pod-name> -- curl <service-url>
```

### Database connection issues
```bash
# Check database pod
kubectl logs -n database-ns -l app=postgres

# Test database connection
kubectl exec -n backend-ns -it deployment/backend -- python -c "import psycopg2; psycopg2.connect(host='postgres-service.database-ns.svc.cluster.local', port=5432, database='testdb', user='postgres', password='postgres')"
```

## Cleanup

To remove all resources:

```bash
kubectl delete -f k8s/all.yaml
# Or delete namespaces (this will delete everything in them)
kubectl delete namespace frontend-ns backend-ns database-ns shared-ns
```

## Next Steps

1. **Enable Cilium Network Policies:** Apply the example policies and observe traffic restrictions
2. **Use Hubble UI:** Set up Hubble UI for visual traffic flow
3. **Add Prometheus Metrics:** Integrate Prometheus to collect metrics from services
4. **Test Policy Enforcement:** Apply deny policies and verify traffic is blocked
5. **Monitor Error Rates:** Use Cilium metrics to track error rates across services

## License

This is a test application suite for Cilium CNI testing purposes.

