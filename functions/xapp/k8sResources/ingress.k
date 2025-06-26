import kube.api.networking.v1 as kubenetworkingv1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1
import models.io.crossplane.kubernetes.v1alpha1 as kubev1alpha1

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

schema ServiceConfig:
    port: int

schema IngressInput:
    metadata: {str:}
    name: str
    namespace?: str
    ingress: IngressConfig
    service: ServiceConfig

getIngress = lambda input: IngressInput -> any {
    kubev1alpha1.Object {
        metadata: input.metadata
        spec: {
            forProvider: {
                manifest: kubenetworkingv1.Ingress {
                    metadata: {
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
                }
            }
        }
    } if input.ingress.enabled else {}
}
