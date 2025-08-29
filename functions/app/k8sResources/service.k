import models.io.k8s.api.core.v1 as kubev1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

schema ServiceConfig:
    type?: str = "ClusterIP"
    port: int

schema ServiceInput:
    metadata: {str:}
    name: str
    namespace?: str
    service: ServiceConfig

getService = lambda input: ServiceInput -> kubev1.Service {
    kubev1.Service {
        metadata: input.metadata | {
            name: input.name
            if input.namespace:
                namespace: input.namespace
        }
        spec: {
            type: input.service.type
            ports: [{
                port: input.service.port
                targetPort: "http"
                protocol: "TCP"
                name: "http"
            }]
            selector: {
                "app.kubernetes.io/name": input.name
                "app.kubernetes.io/instance": input.name
            }
        }
    }
}
