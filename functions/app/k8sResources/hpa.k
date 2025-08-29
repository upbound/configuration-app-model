import models.io.k8s.api.autoscaling.v2 as kubeautoscalingv2
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

schema AutoscalingConfig:
    enabled?: bool = False
    minReplicas?: int = 1
    maxReplicas?: int = 100
    targetCPUUtilizationPercentage?: int
    targetMemoryUtilizationPercentage?: int

schema HPAInput:
    metadata: {str:}
    name: str
    namespace?: str
    autoscaling: AutoscalingConfig

getHPA = lambda input: HPAInput -> any {
    kubeautoscalingv2.HorizontalPodAutoscaler {
        metadata: input.metadata | {
            name: input.name
            if input.namespace:
                namespace: input.namespace
        }
        spec: {
            scaleTargetRef: {
                apiVersion: "apps/v1"
                kind: "Deployment"
                name: input.name
            }
            minReplicas: input.autoscaling.minReplicas
            maxReplicas: input.autoscaling.maxReplicas
            metrics: [
                if input.autoscaling.targetCPUUtilizationPercentage: {
                    type: "Resource"
                    resource: {
                        name: "cpu"
                        target: {
                            type: "Utilization"
                            averageUtilization: input.autoscaling.targetCPUUtilizationPercentage
                        }
                    }
                }
                if input.autoscaling.targetMemoryUtilizationPercentage: {
                    type: "Resource"
                    resource: {
                        name: "memory"
                        target: {
                            type: "Utilization"
                            averageUtilization: input.autoscaling.targetMemoryUtilizationPercentage
                        }
                    }
                }
            ]
        }
    } if input.autoscaling.enabled else {}
}
