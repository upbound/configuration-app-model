# Configuration Application Model

This repository contains an Upbound configuration for deploying cloud-native applications with Kubernetes-based infrastructure. It provides a comprehensive application deployment model with configurable parameters for workloads, scaling, networking, and security, inspired by the structure and parameters of a default Helm chart created with `helm create`.

**Note:** This configuration is designed for Crossplane v2 and uses namespaced composite resources.

## Overview

The core components of this Upbound configuration include:

- **CompositeResourceDefinition (XRD):** Defines the `App` API with comprehensive Kubernetes deployment parameters
- **Composition:** Implements the API by orchestrating Kubernetes resources through provider-kubernetes
- **Embedded Functions:** Uses function-auto-ready for automated resource status management

The `App` API provides a simplified interface for deploying applications with:

- **Configurable workloads** with replica count, image specifications, and resource management
- **Service and ingress configuration** for networking and external access
- **Security contexts** including pod security, service accounts, and RBAC
- **Scaling and availability** through horizontal pod autoscaling and node affinity
- **Health monitoring** via liveness and readiness probes
- **Volume management** for persistent and configurable storage

## Deployment

Deploy this configuration using one of these methods:

- Execute `up project run` to install directly from source
- Install from the Upbound Marketplace
- Check [examples/](/examples/) for example `App` resources to get started

## Testing

Test the configuration using the Upbound CLI:

```bash
# Render compositions to verify resource generation
up composition render apis/apps/composition.yaml examples/app/example.yaml

# Run composition tests
up test run tests/*

# Run end-to-end tests (if available)
up test run tests/* --e2e
```

## Next Steps

This configuration serves as a foundation for application deployment on Kubernetes. To enhance your setup:

1. **Customize workload parameters** in [apis/apps/definition.yaml](apis/apps/definition.yaml) to match your application requirements
2. **Create additional compositions** for different application patterns or environments
3. **Add new API definitions** for related resources like databases, message queues, or monitoring
4. **Extend security configurations** with network policies, pod security standards, or service mesh integration

To learn more about building application platforms with Upbound, read the documentation at [docs.upbound.io](https://docs.upbound.io/).