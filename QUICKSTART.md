# Quick Start Guide

## Quick Deployment

```bash
# 1. Build images
./build-images.sh

# 2. Deploy everything
kubectl apply -f k8s/all.yaml

# Or use the deployment script
./deploy.sh --build-images --wait
```

## Service URLs

| Service | Namespace | Port | Service Name |
|---------|-----------|------|--------------|
| Frontend | frontend-ns | 3000 | frontend-service |
| Backend | backend-ns | 8080 | backend-service |
| Database | database-ns | 5432 | postgres-service |
| Error Generator | shared-ns | 4000 | error-generator-service |
| Logging | shared-ns | 5000 | logging-service |

## Quick Commands

### Check Status
```bash
kubectl get pods -A | grep -E "(frontend|backend|postgres|error|logging)"
```

### View Logs
```bash
# Frontend
kubectl logs -n frontend-ns -l app=frontend -f

# Backend
kubectl logs -n backend-ns -l app=backend -f

# All services
kubectl logs -n frontend-ns -l app=frontend -f &
kubectl logs -n backend-ns -l app=backend -f &
kubectl logs -n shared-ns -l app=error-generator -f &
kubectl logs -n shared-ns -l app=logging-service -f &
```

### Test Services
```bash
# Port forward frontend
kubectl port-forward -n frontend-ns svc/frontend-service 3000:3000

# In another terminal
curl http://localhost:3000/
curl http://localhost:3000/trigger-error
curl http://localhost:3000/stress-test?count=10
```

### Cilium Observability
```bash
# View flow logs (if Cilium is installed)
kubectl exec -n kube-system -it cilium-<pod> -- cilium monitor

# Or with Hubble
hubble observe --namespace frontend-ns
hubble observe --follow
```

### Apply Network Policies
```bash
kubectl apply -f k8s/network-policies-example.yaml
```

## Traffic Patterns

The traffic generator automatically creates:
- ✅ Successful requests: Frontend → Backend → Database
- ❌ Error requests: ~10% error rate from backend
- ⏱️ Timeout scenarios: Error generator timeout endpoint
- 🔄 Cross-namespace: Multiple namespace communications

## Cleanup
```bash
kubectl delete -f k8s/all.yaml
```

