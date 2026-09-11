# Architecture Decisions

## ADR-001 — Local Gitea is the GitOps origin

Argo CD reads desired state from the local Gitea instance so the lab does not depend on an external Git provider for normal operation.

## ADR-002 — Read-only SSH deploy key

Argo CD has read-only repository access.

Reason:
- least privilege
- Argo CD does not need to push to Git
- easier credential isolation than a personal user token

## ADR-003 — SSH host trust is Helm-managed

`config/gitea-known-hosts` feeds Argo Helm `configs.ssh.extraHosts`.

Reason:
- prevents Helm field-manager conflicts
- makes trust reviewable in Git
- avoids imperative `argocd cert add-ssh`

## ADR-004 — Proxy only where needed

Outbound proxy variables are scoped to repo-server.

Reason:
- repo-server fetches remote Git/Helm/OCI content
- global proxy variables can interfere with Argo's internal gRPC/TLS traffic

## ADR-005 — Argo CD is non-HA in the laptop lab

Single replicas are intentional to conserve resources.

The Kubernetes cluster itself still has three control planes.

## ADR-006 — App namespaces default to restricted Pod Security

Security exceptions must be justified and scoped.

## ADR-007 — OpenBao + External Secrets is the secret-management target

No long-lived application secret values should live in Git.

## ADR-008 — RabbitMQ autoscaling uses KEDA

Resource HPA remains useful for CPU/memory behavior, but queue-depth-driven consumer scaling belongs to KEDA.
