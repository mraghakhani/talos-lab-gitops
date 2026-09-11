# Current State

## Git / Argo CD

- Source repository: local Gitea
- Repository SSH endpoint: `192.168.231.1:2222`
- Current repo path used during bootstrap:
  `ssh://git@192.168.231.1:2222/admin/talos-gitops.git`
- Repository auth: read-only Ed25519 deploy key
- Gitea SSH host keys: managed declaratively from `config/gitea-known-hosts`
- Argo CD application version: `3.5.2`
- Argo Helm chart: `10.8.4`
- Root Application: `talos-lab`
- Root Application state: `Synced / Healthy`
- Root path: `clusters/talos-lab`

## Argo CD access

Normal bootstrap access currently uses port-forward:

```bash
task argocd:port-forward
```

Target future endpoint:

```text
https://argocd.<your-domain>
```

Argo CD server remains `ClusterIP`.

## Proxy model

Host CLI/Helm uses:

```text
http://127.0.0.1:10808
```

Argo repo-server outbound HTTP(S) uses:

```text
http://192.168.231.1:10808
```

Proxy variables are intentionally scoped to repo-server rather than all Argo components to avoid breaking internal gRPC/TLS communication.

## Namespace baseline

The repository currently creates baseline namespaces including:
- `platform`
- `apps`
- `workflows`
- `observability`
- `rabbitmq`
- `external-secrets`
- `cert-manager`

Baseline Pod Security policy: `restricted`.

## Next milestone

Service exposure:
1. Cilium LoadBalancer IPAM
2. Cilium L2 announcements
3. Gateway API
4. cert-manager
5. expose Argo CD at `argocd.<your-domain>`
