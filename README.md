# Kubernetes Reference Argo CD Library

Reusable OpenShift GitOps / Argo CD Applications and the Kubernetes objects they sync. This repository is a **library**, not an app-of-apps: consume an overlay from your own GitOps root.

Licensed under the [Apache License 2.0](LICENSE).

This project is not affiliated with CNCF, the Linux Foundation, or Red Hat.

## cert-manager

Matches the [k8s-reference-architecture-app](https://github.com/rgordill/k8s-reference-architecture-app) topologies `cert-manager:dev` and `cert-manager:ha`.

| Overlay | Applications | Operand replicas |
| --- | --- | --- |
| `applications/cert-manager/overlays/dev` | `cert-manager-operator` + `cert-manager-dev` | controller 1, CA injector 1, webhook 1 |
| `applications/cert-manager/overlays/ha` | `cert-manager-operator` + `cert-manager-ha` | controller 2, CA injector 2, webhook 3 |

The operator Application lives once in `applications/cert-manager/operator/` and is **referenced** from both overlays. Apply **one** overlay per cluster (dev and HA are alternative instance shapes).

```bash
kubectl apply -k applications/cert-manager/overlays/dev
# or
kubectl apply -k applications/cert-manager/overlays/ha
```

Patch `spec.source.repoURL` (and destination cluster) to match the clone you deploy from.

### Objects

- `cert-manager/operator` — OLM `Namespace`, `OperatorGroup` (AllNamespaces), and `Subscription` (`openshift-cert-manager-operator`, `stable-v1`, `redhat-operators`) in `cert-manager-operator`. The operator Application uses the Argo CD **default** project.
- `cert-manager/instance/overlays/{dev,ha}` — cluster-scoped `CertManager` named `cluster` (`operator.openshift.io/v1alpha1`) with `overrideReplicas` for the operands.

The operator creates operand Deployments in the `cert-manager` namespace after the `CertManager` CR is applied.
