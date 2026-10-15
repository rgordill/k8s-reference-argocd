# rustfs

Matches the [k8s-reference-architecture-app](https://github.com/rgordill/k8s-reference-architecture-app) topology `s3:rustfs:minimal`. Operator install follows the [RustFS Operator Helm guide](https://docs.rustfs.com/en/installation/cloud-native/operator/installation).

| Overlay | Applications | Deploy method | Tenant |
| --- | --- | --- | --- |
| `overlays/helm/minimal` | `rustfs-operator` + `rustfs-helm-minimal` | Helm chart from [rustfs/operator](https://github.com/rustfs/operator) (`deploy/rustfs-operator`, tag `0.0.8`) | 1 server × 1 volume, `10Gi` PVC |

```bash
kubectl apply -k applications/rustfs/overlays/helm/minimal
```

Patch `spec.source.repoURL` / `spec.sources[*].repoURL` (and destination cluster) to match the clone you deploy from.

### Manifests

- `manifests/rustfs/helm/values.yaml` — Operator Helm values from the [official install docs](https://docs.rustfs.com/en/installation/cloud-native/operator/installation) (`replicas: 1`, metrics + tenant monitor, Console `ClusterIP`). Set `openshift.enabled: true` on OpenShift if SCC requires it.
- `manifests/rustfs/tenant/overlays/minimal` — `Tenant` CR (`rustfs.com/v1alpha1`) with one pool / one PVC, matching [multi-tenant docs](https://docs.rustfs.com/en/installation/cloud-native/operator/tenant).

### Tenant credentials

Create the credentials Secret **before** (or right after) applying the overlay; it is intentionally not stored in git:

```bash
kubectl create namespace rustfs --dry-run=client -o yaml | kubectl apply -f -
kubectl -n rustfs create secret generic rustfs-tenant-creds \
  --from-literal=accesskey='...' \
  --from-literal=secretkey='...'
```

### Access (after Ready)

```bash
kubectl -n rustfs get tenant,pods,pvc,svc
kubectl -n rustfs port-forward svc/rustfs-io 9000:9000
kubectl -n rustfs port-forward svc/rustfs-console 9001:9001
```

S3 API: `http://localhost:9000` — Tenant Console: `http://localhost:9001`.

RustFS and its logo are trademarks of their respective owners; this project is not affiliated with RustFS. Logo artwork used in the architecture app is licensed under CC BY 4.0 by RustFS.com.
