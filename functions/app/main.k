#import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1
import k8sResources.deployment as deployment
import k8sResources.service as service
import k8sResources.serviceaccount as serviceaccount
import k8sResources.ingress as ingress
import k8sResources.hpa as hpa


oxr = option("params").oxr
_ocds = option("params").ocds
_dxr = option("params").dxr
dcds = option("params").dcds

# Function to check if a resource is ready based on its kind
_isResourceReady = lambda name: str -> bool {
    observed_resource = option("params").ocds[name]?.Resource
    _is_ready = False

    # Check Deployment readiness - Available condition is True
    _is_ready = True if observed_resource?.kind == "Deployment" and any_true([c.type == "Available" and c.status == "True" for c in observed_resource?.status?.conditions or []]) else _is_ready

    # Check Service readiness - has clusterIP
    _is_ready = True if observed_resource?.kind == "Service" and observed_resource?.spec?.clusterIP else _is_ready

    # Check ServiceAccount readiness - exists (has metadata.uid)
    _is_ready = True if observed_resource?.kind == "ServiceAccount" and observed_resource?.metadata?.uid else _is_ready

    # Check Ingress readiness - has loadBalancer status with hostname or IP
    _is_ready = True if observed_resource?.kind == "Ingress" and (observed_resource?.status?.loadBalancer?.ingress?[0]?.hostname or observed_resource?.status?.loadBalancer?.ingress?[0]?.ip) else _is_ready

    _is_ready
}

_metadata = lambda name: str -> any {
    { annotations = {
        "krm.kcl.dev/composition-resource-name" = name } | ({ 
            "krm.kcl.dev/ready" = "True"
        } if _isResourceReady(name) else {})
    }
}

# Extract configuration from XR spec (defaults are handled by XRD)
_workloads = oxr.spec.parameters.workloads if oxr.spec?.parameters?.workloads else {}

# Function to create resources for a single workload
_createWorkloadResources = lambda workloadName: str, workloadConfig: any -> [any] {
    _namespace = workloadConfig.namespace if workloadConfig.namespace else None

    # Generate common metadata for this workload
    _commonMetadata = {
        labels = {
            "app.kubernetes.io/name" = workloadName
            "app.kubernetes.io/instance" = workloadName
            "app.kubernetes.io/version" = "1.16.0"
            "app.kubernetes.io/managed-by" = "crossplane"
        }
    }

    # Create resource inputs for this workload
    _serviceAccountInput = {
        metadata = _metadata("${workloadName}-serviceaccount") | _commonMetadata
        name = workloadName
        namespace = _namespace
        serviceAccount = workloadConfig.serviceAccount
    }

    _deploymentInput = {
        metadata = _metadata("${workloadName}-deployment") | _commonMetadata
        name = workloadName
        namespace = _namespace
        replicaCount = workloadConfig.replicaCount
        image = workloadConfig.image
        imagePullSecrets = workloadConfig.imagePullSecrets
        serviceAccountName = (_serviceAccountInput.serviceAccount.name or _serviceAccountInput.name) if _serviceAccountInput.serviceAccount.create else (_serviceAccountInput.serviceAccount.name or "default")
        podSecurityContext = workloadConfig.podSecurityContext
        securityContext = workloadConfig.securityContext
        service = workloadConfig.service
        livenessProbe = workloadConfig.livenessProbe
        readinessProbe = workloadConfig.readinessProbe
        resources = workloadConfig.resources
        volumeMounts = workloadConfig.volumeMounts
        volumes = workloadConfig.volumes
        nodeSelector = workloadConfig.nodeSelector
        affinity = workloadConfig.affinity
        tolerations = workloadConfig.tolerations
        podAnnotations = workloadConfig.podAnnotations
        podLabels = workloadConfig.podLabels
        autoscaling = workloadConfig.autoscaling
    }

    _serviceInput = {
        metadata = _metadata("${workloadName}-service") | _commonMetadata
        name = workloadName
        namespace = _namespace
        service = workloadConfig.service
    }

    _ingressInput = {
        metadata = _metadata("${workloadName}-ingress") | _commonMetadata
        name = workloadName
        namespace = _namespace
        ingress = workloadConfig.ingress
        service = workloadConfig.service
    }

    _hpaInput = {
        metadata = _metadata("${workloadName}-hpa") | _commonMetadata
        name = workloadName
        namespace = _namespace
        autoscaling = workloadConfig.autoscaling
    }

    # Generate resources for this workload
    [
        resource for resource in [
            serviceaccount.getServiceAccount(_serviceAccountInput),
            service.getService(_serviceInput),
            deployment.getDeployment(_deploymentInput),
            ingress.getIngress(_ingressInput),
            hpa.getHPA(_hpaInput)
        ] if resource != {}
    ]
}

# Generate resources for all workloads
_items = [
    resource for workloadName, workloadConfig in _workloads
    for resource in _createWorkloadResources(workloadName, workloadConfig)
]

items = _items
