# GitOps Conventions

## Source of truth

If a resource should survive reconciliation, represent it in Git.

Avoid:
```bash
kubectl apply -f ...
helm install ...
kubectl edit ...
```

for normal day-2 operations.

Allowed exceptions:
- Argo CD initial bootstrap
- emergency recovery
- diagnostics
- temporary test resources

Any emergency mutation must be converted back into Git afterward.

## Kustomize vs Helm

Use:
- upstream Helm charts for complex operators/platform software
- Kustomize for composing first-party manifests and small overlays

Do not template YAML with shell unless it is strictly bootstrap-only.

## Argo Application design

Prefer one Argo Application per meaningful platform component once the repo grows.

Examples:
- `cilium-platform`
- `cert-manager`
- `external-secrets`
- `observability`
- `rabbitmq-operator`
- `rabbitmq-cluster`
- `keda`
- `argo-workflows`
- `demo-apps`

Keep root app composition simple.

## Sync policy

Default preference for managed components:
- automated sync
- self-heal
- prune

But before enabling prune:
- understand CRD ownership
- understand PVC/stateful deletion behavior
- confirm operator uninstall semantics

## Version pinning

Never use:
- `latest`
- unbounded chart versions
- floating Git branches for third-party source when a tag/commit is practical

Pin:
- Helm chart version
- application image tag or digest
- CRD version source

## Namespaces

Keep platform components in dedicated namespaces when practical.

Pod Security default:
- enforce `restricted`
- exceptions must be explicit and justified

## Resource naming

Prefer stable, descriptive names:
- `rabbitmq`
- `keda`
- `cert-manager`
- `external-secrets`
- `grafana`
- `argocd`

Avoid embedding ephemeral environment details in resource names unless necessary.

## Secrets

Never commit:
- base64-encoded secret values
- `.dockerconfigjson`
- private SSH keys
- API tokens
- cloud credentials
- OpenBao recovery/unseal material

Base64 is encoding, not encryption.

## Reviews

Each platform change should answer:
1. What dependency does it require?
2. What CRDs does it install?
3. What namespace/security context does it need?
4. What secrets does it need?
5. What egress does it need?
6. How is it exposed?
7. How is it monitored?
8. How is it upgraded?
9. How is it removed safely?
