[package]
name = "xapp"
version = "0.0.1"

[dependencies]
kube = { oci = "oci://xpkg.upbound.io/upbound/kcl-modules_kube", tag = "1.31.2", package = "kcl-modules_kube", version = "1.31.2" }
models = { path = "./model" }
