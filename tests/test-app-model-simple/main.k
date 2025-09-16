import models.io.k8s.api.apps.v1 as appsv1
import models.io.k8s.api.core.v1 as corev1
import models.io.k8s.api.networking.v1 as networkingv1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-app-model-simple"
        spec= {
            assertResources: [
                appsv1.Deployment {
                    metadata: {
                        annotations: {
                            "crossplane.io/composition-resource-name": "app1-deployment"
                        }
                        labels: {
                            "app.kubernetes.io/instance": "app1"
                            "app.kubernetes.io/managed-by": "crossplane"
                            "app.kubernetes.io/name": "app1"
                            "app.kubernetes.io/version": "1.16.0"
                        }
                        name: "app1"
                        namespace: "test-namespace"
                    }
                    spec: {
                        replicas: 2
                        selector: {
                            matchLabels: {
                                "app.kubernetes.io/instance": "app1"
                                "app.kubernetes.io/name": "app1"
                            }
                        }
                        template: {
                            metadata: {
                                annotations: {
                                    "prometheus.io/port": "80"
                                    "prometheus.io/scrape": "true"
                                }
                                labels: {
                                    "app.kubernetes.io/instance": "app1"
                                    "app.kubernetes.io/name": "app1"
                                    "environment": "production"
                                    "tier": "frontend"
                                }
                            }
                            spec: {
                                affinity: {
                                    nodeAffinity: {
                                        requiredDuringSchedulingIgnoredDuringExecution: {
                                            nodeSelectorTerms: [{
                                                matchExpressions: [{
                                                    key: "kubernetes.io/arch"
                                                    operator: "In"
                                                    values: ["amd64"]
                                                }]
                                            }]
                                        }
                                    }
                                }
                                containers: [{
                                    image: "nginx:1.21"
                                    imagePullPolicy: "IfNotPresent"
                                    livenessProbe: {
                                        httpGet: {
                                            path: "/healthz"
                                            port: "http"
                                        }
                                        initialDelaySeconds: 30
                                        periodSeconds: 10
                                    }
                                    name: "app1"
                                    ports: [{
                                        containerPort: 80
                                        name: "http"
                                        protocol: "TCP"
                                    }]
                                    readinessProbe: {
                                        httpGet: {
                                            path: "/ready"
                                            port: "http"
                                        }
                                        initialDelaySeconds: 5
                                        periodSeconds: 5
                                    }
                                    resources: {
                                        limits: {
                                            cpu: "500m"
                                            memory: "512Mi"
                                        }
                                        requests: {
                                            cpu: "100m"
                                            memory: "128Mi"
                                        }
                                    }
                                    securityContext: {
                                        capabilities: {
                                            drop: ["ALL"]
                                        }
                                        readOnlyRootFilesystem: True
                                        runAsNonRoot: True
                                        runAsUser: 1000
                                    }
                                    volumeMounts: [{
                                        mountPath: "/etc/config"
                                        name: "config-volume"
                                        readOnly: True
                                    } {
                                        mountPath: "/etc/secrets"
                                        name: "secret-volume"
                                        readOnly: True
                                    }]
                                }]
                                nodeSelector: {
                                    "kubernetes.io/arch": "amd64"
                                    "node-type": "compute"
                                }
                                securityContext: {
                                    fsGroup: 2000
                                }
                                serviceAccountName: "my-service-account"
                                tolerations: [{
                                    effect: "NoSchedule"
                                    key: "dedicated"
                                    operator: "Equal"
                                    value: "gpu"
                                }]
                                volumes: [{
                                    configMap: {
                                        name: "my-config"
                                    }
                                    name: "config-volume"
                                } {
                                    name: "secret-volume"
                                    secret: {
                                        optional: False
                                        secretName: "my-secret"
                                    }
                                }]
                            }
                        }
                    }
                }
                networkingv1.Ingress {
                    metadata: {
                        annotations: {
                            "cert-manager.io/cluster-issuer": "letsencrypt-prod"
                            "crossplane.io/composition-resource-name": "app1-ingress"
                            "kubernetes.io/ingress.class": "nginx"
                            "kubernetes.io/tls-acme": "true"
                        }
                        labels: {
                            "app.kubernetes.io/instance": "app1"
                            "app.kubernetes.io/managed-by": "crossplane"
                            "app.kubernetes.io/name": "app1"
                            "app.kubernetes.io/version": "1.16.0"
                        }
                        name: "app1"
                        namespace: "test-namespace"
                    }
                    spec: {
                        ingressClassName: "nginx"
                        rules: [{
                            host: "chart-example.local"
                            http: {
                                paths: [{
                                    backend: {
                                        service: {
                                            name: "app1"
                                            port: {
                                                number: 80
                                            }
                                        }
                                    }
                                    path: "/"
                                    pathType: "ImplementationSpecific"
                                }]
                            }
                        } {
                            host: "api.example.com"
                            http: {
                                paths: [{
                                    backend: {
                                        service: {
                                            name: "app1"
                                            port: {
                                                number: 80
                                            }
                                        }
                                    }
                                    path: "/api"
                                    pathType: "Prefix"
                                }]
                            }
                        }]
                        tls: [{
                            hosts: ["chart-example.local"]
                            secretName: "chart-example-tls"
                        } {
                            hosts: ["api.example.com"]
                            secretName: "api-example-tls"
                        }]
                    }
                }
                corev1.Service {
                    metadata: {
                        annotations: {
                            "crossplane.io/composition-resource-name": "app1-service"
                        }
                        labels: {
                            "app.kubernetes.io/instance": "app1"
                            "app.kubernetes.io/managed-by": "crossplane"
                            "app.kubernetes.io/name": "app1"
                            "app.kubernetes.io/version": "1.16.0"
                        }
                        name: "app1"
                        namespace: "test-namespace"
                    }
                    spec: {
                        ports: [{
                            name: "http"
                            port: 80
                            protocol: "TCP"
                            targetPort: "http"
                        }]
                        selector: {
                            "app.kubernetes.io/instance": "app1"
                            "app.kubernetes.io/name": "app1"
                        }
                        type: "ClusterIP"
                    }
                }
                corev1.ServiceAccount {
                    automountServiceAccountToken: True
                    metadata: {
                        annotations: {
                            "crossplane.io/composition-resource-name": "app1-serviceaccount"
                            "eks.amazonaws.com/role-arn": "arn:aws:iam::123456789012:role/my-role"
                        }
                        labels: {
                            "app.kubernetes.io/instance": "app1"
                            "app.kubernetes.io/managed-by": "crossplane"
                            "app.kubernetes.io/name": "app1"
                            "app.kubernetes.io/version": "1.16.0"
                        }
                        name: "my-service-account"
                        namespace: "test-namespace"
                    }
                }
            ]
            compositionPath: "apis/apps/composition.yaml"
            xrPath: "examples/app/example-full.yaml"
            xrdPath: "apis/apps/definition.yaml"
            timeoutSeconds: 60
            validate: True
        }
    }
]
items= _items
