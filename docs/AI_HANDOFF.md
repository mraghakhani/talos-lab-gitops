# AI Handoff

## One-paragraph context

This repository is the Argo CD source of truth for a six-node Talos Kubernetes lab. Argo CD 3.5.2 is installed with Helm chart 10.8.4 and reads this repo from a local Gitea instance over SSH at `192.168.231.1:2222` using a read-only deploy key. Gitea SSH host trust is declarative and Helm-owned. The root `talos-lab` Application is currently `Synced / Healthy`. The next milestone is Cilium LoadBalancer IPAM + L2 announcements + Gateway API, followed by cert-manager, OpenBao/External Secrets, observability, RabbitMQ, KEDA, Argo Workflows, and Go producer/consumer applications.

## First commands

```bash
git status
task repo:check
task gitea:ssh:check
task argocd:status
task argocd:bootstrap:status
```

## Important historical traps

- YAML anchors cannot be reused across `---` document boundaries.
- Do not put HTTP proxy variables under Argo `global.env`; internal gRPC can break.
- Scope proxy variables to repo-server.
- Do not mutate `argocd-ssh-known-hosts-cm` with `argocd cert add-ssh`; Helm owns it.
- Gitea host keys belong in `config/gitea-known-hosts` and are passed via Helm `configs.ssh.extraHosts`.
- The deploy private key is intentionally not committed.
- Pod Security `restricted` is the default baseline.
- GitOps repo branch must match `GITOPS_BRANCH` used by bootstrap.
- Prefer Git revert to live-cluster rollback.

## Next implementation sequence

1. Add Cilium LB IPAM pool
2. Add L2 announcement policy
3. Add Gateway API CRDs/configuration
4. Create shared Gateway
5. Expose a trivial HTTP smoke test
6. Install cert-manager
7. Issue TLS cert for `argocd.<your-domain>`
8. Expose Argo CD
9. Install OpenBao integration / ESO
10. Continue platform stack

## Agent rule

If a requested change can be represented in Git, do not solve it with a manual cluster mutation.

If a bootstrap/manual mutation is unavoidable:
- make it explicit,
- keep it idempotent,
- document it,
- ensure Git remains the final source of truth.
