# Architecture

## Control flow

```text
Developer / AI agent
        |
        v
     Gitea
        |
        | SSH read-only
        v
   Argo CD repo-server
        |
        v
   Argo CD controller
        |
        v
 Kubernetes API
        |
        v
 Desired cluster state
```

Argo CD is the reconciliation boundary. Git commits describe desired state; agents should not treat the live cluster as the primary configuration store.

## Repository structure

Recommended shape:

```text
talos-gitops/
├── bootstrap/
│   └── templates/
├── clusters/
│   └── talos-lab/
├── platform/
│   ├── argocd/
│   ├── cilium/
│   ├── cert-manager/
│   ├── external-secrets/
│   ├── observability/
│   ├── openbao/
│   ├── rabbitmq/
│   └── keda/
├── apps/
├── workflows/
├── config/
├── scripts/
└── Taskfile.yml
```

`clusters/talos-lab/` should compose the desired resources for this cluster.

## Dependency order

```text
Argo CD
  |
  +--> Cilium service exposure
  |      |
  |      +--> Gateway API
  |
  +--> cert-manager
  |
  +--> External Secrets Operator
  |      |
  |      +--> OpenBao
  |
  +--> observability
  |
  +--> RabbitMQ operator/cluster
  |      |
  |      +--> KEDA
  |             |
  |             +--> Go consumers
  |
  +--> Argo Workflows
```

Avoid introducing a component before its required substrate is healthy.

## Secret flow target

```text
OpenBao
   |
   | Kubernetes auth
   v
External Secrets Operator
   |
   v
Kubernetes Secret
   |
   v
Workload
```

Git stores references, paths, policies, and SecretStore/ExternalSecret definitions—not secret values.

## Image flow target

```text
Go source
   |
Argo Workflows
   |
build/test
   |
Gitea OCI registry
   |
cosign signature
   |
GitOps manifest digest update
   |
Argo CD
   |
Kubernetes
```
