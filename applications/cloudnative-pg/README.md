# cloudnative-pg

Matches the [k8s-reference-architecture-app](https://github.com/rgordill/k8s-reference-architecture-app) topologies. Choose **one** overlay per cluster (OLM vs Helm, and single vs multi, are alternatives).

| Overlay | Applications | Deploy method | PostgreSQL |
| --- | --- | --- | --- |
| `overlays/olm/single` | `cloudnative-pg-operator` + `cloudnative-pg-olm-single` | OpenShift OLM operator | 1 instance, data+WAL on one volume |
| `overlays/olm/multi` | `cloudnative-pg-operator` + `cloudnative-pg-olm-multi` | OpenShift OLM operator | 3 instances (zone anti-affinity), separate data/WAL, Barman backup |
| `overlays/helm/single` | `cloudnative-pg-operator` + `cloudnative-pg-helm-single` | CloudNativePG Helm chart | 1 instance, data+WAL on one volume |
| `overlays/helm/multi` | `cloudnative-pg-operator` + `cloudnative-pg-helm-multi` | CloudNativePG Helm chart | 3 instances (zone anti-affinity), separate data/WAL, Barman backup |

Architecture refs: `cloudnative-pg:postgres:single`, `cloudnative-pg:postgres:multi` (operator **1.30**).

The OLM operator Application lives once in `applications/cloudnative-pg/olm/operator/` and is **referenced** from both OLM overlays. The Helm operator Application lives once in `applications/cloudnative-pg/helm/` and is referenced from both Helm overlays.

```bash
kubectl apply -k applications/cloudnative-pg/overlays/olm/single
# or
kubectl apply -k applications/cloudnative-pg/overlays/olm/multi
# or
kubectl apply -k applications/cloudnative-pg/overlays/helm/single
# or
kubectl apply -k applications/cloudnative-pg/overlays/helm/multi
```

Patch `spec.source.repoURL` / `spec.sources[*].repoURL` (and destination cluster) to match the clone you deploy from.

### Manifests

- `manifests/cloudnative-pg/olm/operator` — OLM `Namespace`, `OperatorGroup` (AllNamespaces), and `Subscription` (`cloudnative-pg`, `stable-v1`, `community-operators`). The operator Application uses the Argo CD **default** project.
- `manifests/cloudnative-pg/helm/values.yaml` — Helm values for the CloudNativePG operator chart (`0.29.1` → app `1.30.x`, `crds.create=true`). Helm Applications use multi-source `$values` refs into this repo.
- `manifests/cloudnative-pg/cluster/overlays/single` — `Cluster` with `instances: 1` and a single PVC for data+WAL.
- `manifests/cloudnative-pg/cluster/overlays/multi` — `Cluster` with `instances: 3`, `walStorage`, required zone pod anti-affinity, Barman backup config, and a daily `ScheduledBackup`.

### Multi overlay: backup credentials

Before backups succeed, create an object-store secret in namespace `cloudnative-pg` and set `spec.backup.barmanObjectStore.destinationPath` (and optionally `endpointURL`) in the Cluster manifest:

```bash
kubectl -n cloudnative-pg create secret generic cnpg-barman-credentials \
  --from-literal=ACCESS_KEY_ID='...' \
  --from-literal=ACCESS_SECRET_KEY='...'
```
