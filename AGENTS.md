# AGENTS.md

This file is the operating contract for AI agents working in `talos-gitops`.

## Mission

This repository is the declarative source of truth for day-2 Kubernetes platform and application state in the local Talos lab.

Argo CD reconciles this repository into the cluster.

The repository should eventually own:
- Cilium Gateway API / LoadBalancer IPAM / L2 announcements configuration
- cert-manager
- External Secrets Operator
- OpenBao integration
- observability
- RabbitMQ
- KEDA
- Argo Workflows
- demo/application workloads
- policies and platform namespaces

It does **not** own:
- libvirt networks/storage/VMs
- Talos machine configuration
- Talos bootstrap
- base Cilium installation/bootstrap

Those stay in `talos-lab`.

## Current state

- Local Gitea runs on the laptop
- Gitea SSH is reachable at `192.168.231.1:2222`
- GitOps repo URL currently follows:
  `ssh://git@192.168.231.1:2222/admin/talos-gitops.git`
- Argo CD application version: `3.5.2`
- Argo Helm chart: `10.8.4`
- Root Application: `talos-lab`
- Root Application state: `Synced / Healthy`
- Argo CD uses a read-only Gitea deploy key
- Gitea SSH host trust is managed declaratively through Helm
- Argo CD remains `ClusterIP` until Gateway API/TLS exposure is implemented

## Core GitOps rules

1. **Git is the source of truth.**
   - If a Kubernetes resource should persist, represent it in Git.
   - Avoid `kubectl apply` for day-2 resources outside documented bootstrap/recovery paths.

2. **Argo CD owns reconciliation.**
   - Prefer Argo Applications/ApplicationSets/Kustomize/Helm values over manual installs.
   - Do not manually install platform charts once their Argo resource exists.

3. **No plaintext secrets in Git.**
   - Do not commit tokens, passwords, kubeconfigs, private keys, recovery keys, or unencrypted secret values.
   - Target architecture: OpenBao + External Secrets Operator.

4. **Repository credentials are special bootstrap state.**
   - Gitea deploy private key remains outside Git for now.
   - Gitea known-host fingerprints are public trust material and may be committed.
   - Later move the private key/credential path to OpenBao-backed secret delivery.

5. **Namespace Pod Security defaults to `restricted`.**
   - Only create exceptions when a workload truly needs them.
   - Scope exceptions narrowly and document why.

6. **One component at a time.**
   - Add a platform component.
   - Sync it.
   - Validate it.
   - Then move to the next component.
   - Avoid bootstrapping the entire future stack in one giant commit.

7. **Pin versions.**
   - Helm chart and application versions must be explicit.
   - Version updates are intentional changes, not floating defaults.

8. **Prefer declarative SSH/TLS trust.**
   - Never rely on interactive `StrictHostKeyChecking=no` as normal operation.
   - Host keys/certificates should have an owned declarative source.

9. **Argo CD itself is bootstrapped imperatively but configured reproducibly.**
   - Helm bootstrap scripts are allowed for Argo CD.
   - Everything after root-app health should converge through GitOps.

10. **Keep application and platform concerns separate.**
    - `platform/` for cluster services/operators
    - `apps/` for business/demo workloads
    - `workflows/` for Argo Workflows resources

## Read before editing

1. `TODO.md`
2. `docs/CURRENT_STATE.md`
3. `docs/ARCHITECTURE.md`
4. `docs/GITOPS_CONVENTIONS.md`
5. `docs/SECURITY.md`
6. `docs/OPERATIONS.md`

## Validation

Repository validation:

```bash
task repo:check
```

Bootstrap sanity:

```bash
task check
task gitea:check
task gitea:ssh:check
task argocd:status
task argocd:bootstrap:status
```

For any new Argo-managed component:
- render locally if possible
- validate YAML/Kustomize/Helm
- commit
- push
- wait for Argo sync
- inspect health/events
- record any required exception in docs

## Safe change workflow

1. Create/edit manifests.
2. Run local validation.
3. Commit with a focused message.
4. Push to Gitea.
5. Observe Argo CD.
6. Confirm `Synced / Healthy`.
7. Run component-specific smoke tests.
8. Only then proceed to the next dependency.

## Dangerous actions

Agents must call out impact before:
- deleting an Argo Application with cascading finalizer
- changing prune behavior
- changing AppProject permissions broadly
- changing repository credentials
- rotating SSH host keys
- deleting CRDs
- changing storage classes/PVC semantics
- uninstalling operators that own CRs
- modifying secret-manager authentication
- enabling cluster-wide privileged Pod Security

## Agent behavior

Prefer implementation over discussion when the requested change is clear.

Do not:
- put credentials in manifests
- disable verification to make sync green
- widen AppProject permissions without need
- use `default` project for everything long-term
- mix host bootstrap scripts into this repo
- add floating `latest` tags/charts

Always report:
- files changed
- versions introduced
- Argo Application affected
- validation performed
- migration/rollback concerns
