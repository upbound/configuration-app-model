import models.io.k8s.api.networking.v1 as kubenetworkingv1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

schema IngressPath:
    path: str
    pathType?: str = "ImplementationSpecific"

schema IngressHost:
    host: str
    paths: [IngressPath]

schema IngressTLS:
    secretName?: str
    hosts?: [str]

schema IngressConfig:
    enabled?: bool = False
    className?: str
    annotations?: {str:}
    hosts?: [IngressHost]
    tls?: [IngressTLS]

schema IngressServiceConfig:
    type?: str = "ClusterIP"
    port: int

schema IngressInput:
    metadata: {str:}
    name: str
    namespace?: str
    ingress: IngressConfig
    service: IngressServiceConfig

getIngress = lambda input: IngressInput -> any {
    kubenetworkingv1.Ingress {
        metadata: input.metadata | {
            name: input.name
            if input.namespace:
                namespace: input.namespace
            if input.ingress.annotations:
                annotations: input.ingress.annotations
        }
        spec: {
            if input.ingress.className:
                ingressClassName: input.ingress.className
            if input.ingress.tls:
                tls: [{
                    hosts: tlsConfig.hosts
                    secretName: tlsConfig.secretName
                } for tlsConfig in input.ingress.tls]
            if input.ingress.hosts:
                rules: [{
                    host: hostConfig.host
                    http: {
                        paths: [{
                            path: pathConfig.path
                            pathType: pathConfig.pathType
                            backend: {
                                service: {
                                    name: input.name
                                    port: {
                                        number: input.service.port
                                    }
                                }
                            }
                        } for pathConfig in hostConfig.paths]
                    }
                } for hostConfig in input.ingress.hosts]
        }
    } if input.ingress.enabled else {}
}
