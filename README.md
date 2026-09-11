# talos-gitops

GitOps control-plane repository for the local Talos Kubernetes lab.

## Architecture

```text
CachyOS host
├── Gitea
├── HTTP proxy :10808
└── kubectl / helm / argocd

Talos Kubernetes
└── Argo CD
    └── SSH (read-only deploy key)
        └── Gitea / talos-gitops
```

The Git repository becomes the source of truth after bootstrap.

## Pinned versions

- Argo CD application: `3.5.2`
- Argo CD Helm chart: `10.8.4`

## 1. Configure

```bash
cp .env.example .env
$EDITOR .env
```

Replace `YOUR_GITEA_USER` in `GITOPS_REPO_URL`.

Set kubeconfig:

```bash
export KUBECONFIG="$HOME/Documents/talos-lab/infrastructure/talos/generated/kubeconfig"
```

Validate:

```bash
task repo:check
task check
task gitea:check
```

## 2. Push this repo to Gitea

Create an empty `talos-gitops` repository in Gitea:

```bash
git init
git add .
git commit -m "feat: bootstrap talos gitops"
git branch -M main
git remote add origin <YOUR-GITEA-REPO-URL>
git push -u origin main
```

Never commit `.env` or `.secrets/`.

## 3. Install Argo CD

```bash
task argocd:install
task argocd:status
```

This is intentionally a single-replica/non-HA deployment for the laptop lab.

Argo CD pods use:

```text
HTTP_PROXY=http://192.168.231.1:10808
HTTPS_PROXY=http://192.168.231.1:10808
```

with cluster-local networks in `NO_PROXY`.

## 4. Create a read-only Gitea deploy key

```bash
task gitea:keygen
```

Add the printed public key in:

```text
Gitea → talos-gitops → Settings → Deploy Keys
```

Keep it read-only.

The private key remains under `.secrets/gitea-argocd` and is gitignored.
Later this credential will move to OpenBao + External Secrets.

## 5. Bootstrap GitOps

After adding the deploy key:

```bash
task argocd:bootstrap
task argocd:bootstrap:status
```

The bootstrap task registers the Gitea SSH host key, registers the repo,
creates the `platform` AppProject, and creates the `talos-lab` root Application.

Argo CD then reconciles `clusters/talos-lab/` from Git.

## 6. UI

```bash
task argocd:port-forward
```

Open `https://127.0.0.1:8080`.

Get the initial password with:

```bash
task argocd:password
```

Later Gateway API + TLS will expose:

```text
https://argocd.<your-domain>
```

## Layout

```text
talos-gitops/
├── bootstrap/
├── clusters/talos-lab/
├── platform/
│   ├── argocd/
│   ├── cert-manager/
│   ├── external-secrets/
│   ├── observability/
│   ├── openbao/
│   └── rabbitmq/
├── apps/
├── workflows/
├── config/
├── scripts/
└── Taskfile.yml
```

## Security defaults

- No plaintext credentials in Git.
- Gitea access uses a read-only deploy key.
- Application namespaces default to Pod Security `restricted`.
- Argo CD exec support is disabled.
- Argo CD stays `ClusterIP` until Gateway API + TLS are configured.
- OpenBao + External Secrets will become the runtime secret source later.

## Next milestones

1. Cilium LoadBalancer IPAM / L2 / Gateway API
2. cert-manager
3. OpenBao integration + External Secrets Operator
4. observability
5. RabbitMQ Cluster Operator
6. KEDA
7. Argo Workflows
8. Go producer / consumer demo applications
