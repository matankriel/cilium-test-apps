#!/bin/bash

# Deployment script for Cilium test applications
# Usage: ./deploy.sh [options]
# Options:
#   --build-images    Build Docker images before deploying
#   --registry REG    Use registry for images (CONFIGURATION REQUIRED FOR DISCONNECTED ENV)
#   --wait           Wait for all pods to be ready
#
# ============================================================================
# AIR-GAPPED / DISCONNECTED ENVIRONMENT CONFIGURATION
# ============================================================================
# For disconnected environments:
# 1. Use --registry flag with your private Artifactory URL
#    Example: ./deploy.sh --build-images --registry artifactory.yourcompany.local/docker
# 2. Ensure Helm values.yaml is configured with global.imageRegistry
# 3. Consider using Helm for deployment instead: helm install cilium-test-apps ./helm/cilium-test-apps
# ============================================================================

set -e

BUILD_IMAGES=false
REGISTRY=""
WAIT_FOR_READY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --build-images)
            BUILD_IMAGES=true
            shift
            ;;
        --registry)
            REGISTRY="$2"
            shift 2
            ;;
        --wait)
            WAIT_FOR_READY=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--build-images] [--registry REG] [--wait]"
            exit 1
            ;;
    esac
done

echo "=== Cilium Test Applications Deployment ==="
echo ""

# Build images if requested
if [ "$BUILD_IMAGES" = true ]; then
    echo "Building Docker images..."
    if [ -n "$REGISTRY" ]; then
        ./build-images.sh "$REGISTRY"
    else
        ./build-images.sh
    fi
    echo ""
fi

# Deploy to Kubernetes
echo "Deploying to Kubernetes..."
kubectl apply -f k8s/all.yaml

echo ""
echo "Waiting for namespaces to be created..."
sleep 2

# Wait for pods if requested
if [ "$WAIT_FOR_READY" = true ]; then
    echo ""
    echo "Waiting for pods to be ready..."
    
    echo "Waiting for database..."
    kubectl wait --for=condition=ready pod -l app=postgres -n database-ns --timeout=120s || true
    
    echo "Waiting for backend..."
    kubectl wait --for=condition=ready pod -l app=backend -n backend-ns --timeout=120s || true
    
    echo "Waiting for frontend..."
    kubectl wait --for=condition=ready pod -l app=frontend -n frontend-ns --timeout=120s || true
    
    echo "Waiting for shared services..."
    kubectl wait --for=condition=ready pod -l app=error-generator -n shared-ns --timeout=120s || true
    kubectl wait --for=condition=ready pod -l app=logging-service -n shared-ns --timeout=120s || true
fi

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "Check pod status:"
echo "  kubectl get pods -n frontend-ns"
echo "  kubectl get pods -n backend-ns"
echo "  kubectl get pods -n database-ns"
echo "  kubectl get pods -n shared-ns"
echo ""
echo "View logs:"
echo "  kubectl logs -n frontend-ns -l app=frontend -f"
echo "  kubectl logs -n backend-ns -l app=backend -f"
echo ""
echo "Apply network policies (optional):"
echo "  kubectl apply -f k8s/network-policies-example.yaml"

