# External Secrets Operator

Deploys the External Secrets Operator with ArgoCD using either:
- **OLM** (Operator Lifecycle Manager) - for OpenShift clusters
- **Helm** - for standard Kubernetes clusters

## Structure

```
applications/external-secrets/
├── README.md
├── olm/                              # OpenShift OLM deployment
│   ├── kustomization.yaml            # Deploys operator + minimal instance
│   ├── operator/                     # Operator subscription (sync-wave: 1)
│   │   ├── external-secrets-operator.yaml
│   │   └── kustomization.yaml
│   └── instance/
│       ├── base/                     # Example ClusterSecretStore & ExternalSecret
│       │   ├── cluster-secret-store.yaml
│       │   ├── external-secret.yaml
│       │   └── kustomization.yaml
│       └── overlays/
│           └── minimal/              # Minimal instance (sync-wave: 2)
│               ├── external-secrets.yaml
│               └── kustomization.yaml
├── helm/                             # Standard Kubernetes Helm deployment
│   ├── kustomization.yaml            # Base helm Application
│   └── external-secrets-operator.yaml
├── overlays/
│   └── helm/
│       └── ha/                       # HA overlay (sync-wave: 1)
│           ├── application.yaml      # Patch to use HA values
│           └── kustomization.yaml
└── manifests/
    ├── olm/                          # OLM manifests (OpenShift)
    └── helm/                         # Helm values
        ├── values.yaml               # Base values
        └── overlays/
            └── ha/
                └── values.yaml       # HA values (2 replicas, anti-affinity, etc.)
```

## Deploy

### OpenShift (OLM)

```bash
# Deploy operator + minimal instance (recommended for OpenShift)
kubectl apply -k applications/external-secrets/olm

# Or deploy separately
kubectl apply -k applications/external-secrets/olm/operator          # Wave 1: Operator
kubectl apply -k applications/external-secrets/olm/instance/overlays/minimal  # Wave 2: Instance
```

### Standard Kubernetes (Helm)

```bash
# Deploy base helm chart (1 replica)
kubectl apply -k applications/external-secrets/helm

# Deploy HA configuration (2 replicas, anti-affinity, PDB)
kubectl apply -k applications/external-secrets/overlays/helm/ha
```

## Components

| Component | Namespace | Description |
|-----------|-----------|-------------|
| **OLM Operator** | `external-secrets-operator` | OLM Subscription from `community-operators` / `stable` |
| **Helm Operator** | `external-secrets-operator` | Helm chart from `https://charts.external-secrets.io` / `0.16.0` |
| **OLM Instance (minimal)** | `external-secrets-operator` | Example ClusterSecretStore + ExternalSecret (Kubernetes backend) |
| **Helm HA** | `external-secrets-operator` | 2 replicas, pod anti-affinity, PDB, leader election tuning |

## Helm Configuration

### Base Values (`manifests/external-secrets/helm/values.yaml`)

- 1 replica
- Basic resource defaults
- Leader election enabled
- Webhook enabled (no cert-manager)
- CRDs managed by chart

### HA Values (`manifests/external-secrets/helm/overlays/ha/values.yaml`)

- 2 replicas
- Resource limits/requests
- Pod anti-affinity (spread across nodes)
- PodDisruptionBudget (minAvailable: 1)
- Leader election tuned for faster failover
- Webhook with cert-manager enabled
- ServiceMonitor enabled

## Customizing for Your Backend

The OLM instance includes example resources using the **Kubernetes provider**. For Helm, you configure the secret backend via `ClusterSecretStore` / `SecretStore` CRs after the operator is installed.

### Common Backends

**Vault:**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.example.com"
      path: "secret"
      version: "v2"
      auth:
        tokenSecretRef:
          name: vault-token
          key: token
```

**AWS Secrets Manager:**
```yaml
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-operator
```

**Azure Key Vault:**
```yaml
spec:
  provider:
    azurekv:
      vaultUrl: "https://myvault.vault.azure.net"
      authType: WorkloadIdentity
```

**GCP Secret Manager:**
```yaml
spec:
  provider:
    gcpsm:
      projectID: "my-project"
      auth:
        workloadIdentity:
          serviceAccountRef:
            name: external-secrets-operator
```

## Sync Waves

| Deployment | Wave | Components |
|------------|------|------------|
| OLM | 1 | Operator subscription (namespace, OperatorGroup, Subscription) |
| OLM | 2 | Instance resources (ClusterSecretStore, ExternalSecret) |
| Helm | 1 | Helm release (operator + CRDs) |

## Notes

- **OLM**: Operator Deployment replicas managed by OLM (defaults to 1)
- **Helm**: Replica count controlled via `replicaCount` in values
- For HA on Helm: uses `replicaCount: 2` + pod anti-affinity + PDB
- The example ClusterSecretStore (OLM) uses Kubernetes provider for testing - replace with production backend
- Operator ServiceAccount `external-secrets-operator` is created by both OLM and Helm
- Chart version `0.16.0` - update `targetRevision` in `external-secrets-operator.yaml` for newer versions