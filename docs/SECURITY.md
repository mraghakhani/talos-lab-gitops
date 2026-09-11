# Security Model

## Baseline

- Pod Security: `restricted` by default
- Argo CD repository access: read-only deploy key
- SSH host verification: declarative known-hosts
- Argo CD exec feature disabled
- no plaintext secret values in Git
- platform UIs stay private until intentionally exposed
- TLS required for stable HTTP exposure

## Secrets target architecture

OpenBao is the trust source.

External Secrets Operator fetches values into Kubernetes.

Preferred flow:

```text
OpenBao policy
  -> Kubernetes auth role
  -> ServiceAccount
  -> SecretStore / ClusterSecretStore
  -> ExternalSecret
  -> Kubernetes Secret
  -> Pod
```

## Argo CD credentials

Current bootstrap state:
- private Gitea deploy key is local and ignored by Git
- public deploy key is stored in Gitea
- Gitea host fingerprints are safe to commit after verification

Future:
- move repository credential material into OpenBao
- evaluate Argo CD supported secret integration pattern without introducing a bootstrap deadlock

## Pod Security exceptions

Never label a broad production namespace `privileged` for convenience.

If a tool/test needs privilege:
- use a dedicated namespace
- document the reason
- keep the exception temporary or scoped

## Network policy target

For application namespaces:
1. default deny ingress
2. default deny egress
3. allow DNS
4. explicitly allow required service dependencies
5. explicitly allow proxy/Internet egress where necessary

## Supply chain target

- Gitea OCI registry
- no `latest`
- build with Argo Workflows
- scan images
- sign with cosign
- prefer digest-pinned deployment
- later enforce signature/registry policy

## RBAC

- separate platform/app/workflow permissions
- avoid wildcard cluster-admin bindings for automation
- Argo Workflows service accounts should get only workflow-required permissions
- operator service accounts remain namespace-scoped where supported

## External exposure

Gateway API + TLS only.

Do not expose:
- OpenBao administrative endpoints
- RabbitMQ management UI
- Argo CD
- Grafana

without authentication and TLS.
