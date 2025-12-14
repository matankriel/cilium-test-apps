# Helm Chart for Cilium Test Apps

This directory contains a Helm chart for deploying the Cilium test applications.

## Chart Structure

```
helm/cilium-test-apps/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default configuration values
├── values.example.yaml     # Example configuration file
├── README.md               # Detailed chart documentation
└── templates/              # Kubernetes manifest templates
    ├── _helpers.tpl        # Template helper functions
    ├── namespaces.yaml     # Namespace definitions
    ├── database.yaml       # Database deployment and service
    ├── backend.yaml        # Backend deployment and service
    ├── frontend.yaml       # Frontend deployment and service
    ├── shared-services.yaml # Error generator and logging services
    └── traffic-generator.yaml # Traffic generator deployment
```

## Quick Start

```bash
# Install with default values
helm install cilium-test-apps ./helm/cilium-test-apps

# Install with custom values
helm install cilium-test-apps ./helm/cilium-test-apps -f my-values.yaml

# Upgrade
helm upgrade cilium-test-apps ./helm/cilium-test-apps

# Uninstall
helm uninstall cilium-test-apps
```

## Configuration

All configuration is done through the `values.yaml` file. Key sections:

- **Global**: Image registry, pull policy, labels
- **Namespaces**: Namespace names and creation flags
- **Database**: Image, credentials, resources
- **Backend**: Image, replicas, environment variables, resources
- **Frontend**: Image, replicas, environment variables, resources
- **Error Generator**: Image, replicas, resources
- **Logging Service**: Image, replicas, resources
- **Traffic Generator**: Image, replicas, resources

See `values.yaml` for all available options and `values.example.yaml` for example configurations.

## Benefits of Using Helm

1. **Single Configuration File**: All settings in one `values.yaml` file
2. **Easy Scaling**: Change replica counts with one value
3. **Environment Management**: Use different values files for dev/staging/prod
4. **Version Control**: Track configuration changes in Git
5. **Easy Updates**: Upgrade deployments with `helm upgrade`
6. **Template Flexibility**: Automatic service URL generation based on namespaces

## Migration from kubectl

If you were using `kubectl apply -f k8s/all.yaml`, you can migrate to Helm:

1. Uninstall existing resources (if needed):
   ```bash
   kubectl delete -f k8s/all.yaml
   ```

2. Install with Helm:
   ```bash
   helm install cilium-test-apps ./helm/cilium-test-apps
   ```

The Helm chart generates the same Kubernetes resources, but with more flexibility for configuration.

