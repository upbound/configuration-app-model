import kube.api.apps.v1 as kubeappsv1
import kube.api.core.v1 as kubev1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1
import models.io.crossplane.kubernetes.v1alpha1 as kubev1alpha1

schema ImageConfig:
    repository: str
    tag?: str
    pullPolicy?: str = "IfNotPresent"

schema ServiceConfig:
    type: str
    port: int

schema AutoscalingConfig:
    enabled: bool
    minReplicas: int
    maxReplicas: int
    targetCPUUtilizationPercentage: int

schema DeploymentInput:
    metadata: {str:}
    name: str
    namespace?: str
    replicaCount?: int = 1
    image: ImageConfig
    imagePullSecrets?: [str]
    serviceAccountName: str
    podSecurityContext?: {str:}
    securityContext?: {str:}
    service: ServiceConfig
    livenessProbe?: {str:}
    readinessProbe?: {str:}
    resources?: {str:}
    volumeMounts?: [{str:}]
    volumes?: [{str:}]
    nodeSelector?: {str:}
    affinity?: {str:}
    tolerations?: [{str:}]
    podAnnotations?: {str:}
    podLabels?: {str:}
    autoscaling: AutoscalingConfig

getDeployment = lambda input: DeploymentInput -> kubev1alpha1.Object {
    kubev1alpha1.Object {
        metadata: input.metadata
        spec: {
            forProvider: {
                manifest: kubeappsv1.Deployment {
                    metadata: {
                        name: input.name
                        if input.namespace:
                            namespace: input.namespace
                    }
                    spec: {
                        if not input.autoscaling.enabled:
                            replicas: input.replicaCount
                        selector: {
                            matchLabels: {
                                "app.kubernetes.io/name": input.name
                                "app.kubernetes.io/instance": input.name
                            }
                        }
                        template: {
                            metadata: {
                                if input.podAnnotations:
                                    annotations: input.podAnnotations
                                labels: {
                                    "app.kubernetes.io/name": input.name
                                    "app.kubernetes.io/instance": input.name
                                } | (input.podLabels if input.podLabels else {})
                            }
                            spec: {
                                if input.imagePullSecrets:
                                    imagePullSecrets: [{"name": secret} for secret in input.imagePullSecrets]
                                serviceAccountName: input.serviceAccountName
                                if input.podSecurityContext:
                                    securityContext: input.podSecurityContext
                                containers: [{
                                    name: input.name
                                    if input.securityContext:
                                        securityContext: input.securityContext
                                    image: "${input.image.repository}:${input.image.tag if input.image.tag else 'latest'}"
                                    imagePullPolicy: input.image.pullPolicy
                                    ports: [{
                                        name: "http"
                                        containerPort: input.service.port
                                        protocol: "TCP"
                                    }]
                                    if input.livenessProbe:
                                        livenessProbe: input.livenessProbe
                                    if input.readinessProbe:
                                        readinessProbe: input.readinessProbe
                                    if input.resources:
                                        resources: input.resources
                                    if input.volumeMounts:
                                        volumeMounts: input.volumeMounts
                                }]
                                if input.volumes:
                                    volumes: input.volumes
                                if input.nodeSelector:
                                    nodeSelector: input.nodeSelector
                                if input.affinity:
                                    affinity: input.affinity
                                if input.tolerations:
                                    tolerations: input.tolerations
                            }
                        }
                    }
                }
            }
        }
    }
}
