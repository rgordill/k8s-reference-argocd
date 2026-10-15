## cert-manager

Matches the [k8s-reference-architecture-app](https://github.com/rgordill/k8s-reference-architecture-app) topologies. Choose **one** overlay per cluster (OLM vs Helm, and dev vs HA, are alternatives).

| Overlay | Applications | Deploy method | Operand replicas (controller / CA injector / webhook) |
| --- | --- | --- | --- |
| `overlays/olm/dev` | `cert-manager-operator` + `cert-manager-olm-dev` | OpenShift OLM operator | 1 / 1 / 1 |
| `overlays/olm/ha` | `cert-manager-operator` + `cert-manager-olm-ha` | OpenShift OLM operator | 2 / 2 / 3 |
| `overlays/helm/dev` | `cert-manager-helm-dev` | Jetstack Helm chart | 1 / 1 / 1 |
| `overlays/helm/ha` | `cert-manager-helm-ha` | Jetstack Helm chart | 2 / 2 / 3 |

The OLM operator Application lives once in `applications/cert-manager/olm/operator/` and is **referenced** from both OLM overlays.

```bash
kubectl apply -k applications/cert-manager/overlays/olm/dev
# or
kubectl apply -k applications/cert-manager/overlays/olm/ha
# or
kubectl apply -k applications/cert-manager/overlays/helm/dev
# or
kubectl apply -k applications/cert-manager/overlays/helm/ha
```

Patch `spec.source.repoURL` / `spec.sources[*].repoURL` (and destination cluster) to match the clone you deploy from.

### Manifests

- `manifests/cert-manager/olm/operator` — OLM `Namespace`, `OperatorGroup` (AllNamespaces), and `Subscription` (`openshift-cert-manager-operator`, `stable-v1`, `redhat-operators`). The operator Application uses the Argo CD **default** project.
- `manifests/cert-manager/olm/instance/overlays/{dev,ha}` — cluster-scoped `CertManager` named `cluster` with `overrideReplicas`.
- `manifests/cert-manager/helm/overlays/{dev,ha}/values.yaml` — Helm values for the Jetstack `cert-manager` chart (`v1.20.0`, `crds.enabled=true`). Helm Applications use multi-source `$values` refs into this repo.
