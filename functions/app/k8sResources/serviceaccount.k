import models.io.k8s.api.core.v1 as kubev1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

schema ServiceAccountConfig:
    create?: bool = True
    automount?: bool = True
    annotations?: {str:}
    name?: str

schema ServiceAccountInput:
    metadata: {str:}
    name: str
    namespace?: str
    serviceAccount: ServiceAccountConfig

getServiceAccount = lambda input: ServiceAccountInput -> any {
    kubev1.ServiceAccount {
        metadata: input.metadata | {
            name: input.serviceAccount.name if input.serviceAccount.name else input.name
            if input.namespace:
                namespace: input.namespace
            if input.serviceAccount.annotations:
                annotations: input.serviceAccount.annotations
        }
        automountServiceAccountToken: input.serviceAccount.automount
    } if input.serviceAccount.create else {}
}

