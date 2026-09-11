# Operations Runbook

## Validate repo

```bash
task repo:check
```

## Check prerequisites

```bash
task check
task gitea:check
task gitea:ssh:check
```

## Argo CD

Install/upgrade bootstrap release:

```bash
task argocd:render
task argocd:install
```

Status:

```bash
task argocd:status
task argocd:bootstrap:status
```

UI:

```bash
task argocd:port-forward
```

Initial password:

```bash
task argocd:password
```

## Gitea trust

Refresh SSH host keys only when Gitea's SSH host keys intentionally changed:

```bash
task gitea:known-hosts:update
```

Verify fingerprints before committing `config/gitea-known-hosts`.

Do not run imperative `argocd cert add-ssh` as normal operation; it conflicts with Helm ownership.

## Normal platform change

```bash
git checkout -b feat/<component>
# edit manifests
task repo:check
git add .
git commit -m "feat: add <component>"
git push
```

Then observe:

```bash
task argocd:bootstrap:status
```

and/or:

```bash
argocd app list
argocd app get <app>
```

## If Argo app is OutOfSync

Do not immediately force-sync.

Check:
- Git revision
- manifest render error
- missing CRD
- repository connectivity
- admission policy
- immutable field change
- namespace/permissions
- health check behavior

## If repository connectivity fails

Validate host-side SSH first:

```bash
task gitea:ssh:check
```

Then inspect:

```bash
kubectl -n argocd logs deploy/argocd-repo-server --since=10m
kubectl -n argocd logs deploy/argocd-server --since=10m
```

Remember:
- repo-server gets outbound HTTP(S) proxy variables
- server/controller should not inherit a proxy that breaks internal gRPC/TLS

## Rollback

Preferred:
```bash
git revert <commit>
git push
```

Let Argo reconcile the revert.

Use live-cluster rollback only for emergencies, then reconcile Git immediately.
