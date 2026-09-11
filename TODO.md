# TODO.md

Prioritized roadmap for the GitOps-managed platform.

## Completed

- [x] Local Gitea available from the lab network
- [x] `talos-gitops` repository created
- [x] Argo CD installed
- [x] Read-only Gitea deploy key
- [x] Declarative Gitea SSH host trust
- [x] `platform` AppProject
- [x] Root `talos-lab` Application
- [x] Root Application `Synced / Healthy`
- [x] Restricted Pod Security labels on baseline namespaces

## P0 — close the GitOps bootstrap loop

- [ ] Decide whether Argo CD should manage its own Helm values
  - Keep bootstrap scripts as break-glass path
  - Avoid creating a self-management loop that can strand repo access
- [ ] Add Argo CD repository health/runbook checks
- [ ] Add a small smoke-test Application to prove commit -> sync -> workload reconciliation
- [ ] Add clear branch policy (`master` vs `main`) and normalize repo defaults
- [ ] Add CI validation for:
  - yamllint
  - shellcheck
  - Kustomize render
  - kubeconform
  - secret scan

## P1 — service exposure

### Cilium LoadBalancer IPAM
- [ ] Define a LoadBalancer pool, proposed: `192.168.231.200-220`
- [ ] Keep addresses outside node/VIP assignments
- [ ] Validate allocation with a test `Service type=LoadBalancer`

### Cilium L2 announcements
- [ ] Enable required Cilium Helm options in the foundation repo if install-level settings are needed
- [ ] Add `CiliumL2AnnouncementPolicy`
- [ ] Validate laptop can ARP/reach allocated LoadBalancer IP

### Gateway API
- [ ] Install/verify Gateway API CRDs
- [ ] Enable Cilium Gateway API support where required
- [ ] Create shared `Gateway`
- [ ] Create HTTPRoute smoke test
- [ ] Establish hostname convention under `*.lab.<your-domain>`

### Argo CD exposure
- [ ] Expose Argo CD at `argocd.<your-domain>`
- [ ] Keep backend service `ClusterIP`
- [ ] Remove port-forward as normal access path after TLS is healthy

## P1 — TLS and DNS

- [ ] Decide split-DNS mechanism for `*.lab.<your-domain>`
- [ ] Install cert-manager
- [ ] Configure DNS-01 issuer for `<your-domain>`
- [ ] Issue a test certificate
- [ ] Issue Argo CD certificate
- [ ] Document renewal validation

## P1 — secrets platform

### OpenBao
- [ ] Run OpenBao outside Kubernetes on the host or a clearly separated trusted boundary
- [ ] Configure persistent storage/raft
- [ ] Document unseal/recovery procedure
- [ ] Do not store recovery material in Git

### External Secrets Operator
- [ ] Install ESO through Argo CD
- [ ] Configure Kubernetes auth to OpenBao
- [ ] Create minimal `ClusterSecretStore` or namespaced `SecretStore`
- [ ] Validate one non-sensitive demo secret
- [ ] Move Gitea/Argo repository credential handling toward OpenBao
- [ ] Define secret naming and ownership conventions

## P1 — observability

- [ ] kube-prometheus-stack or equivalent
- [ ] Grafana
- [ ] Cilium/Hubble dashboards
- [ ] Loki + Alloy (or chosen log stack)
- [ ] Alerts for:
  - node unavailable
  - etcd/control-plane health
  - Cilium degraded
  - PVC pressure
  - RabbitMQ queue depth
  - RabbitMQ cluster health
- [ ] Expose Grafana through Gateway API + TLS

## P1 — RabbitMQ

- [ ] Install RabbitMQ Cluster Operator
- [ ] Create three-node RabbitMQ cluster
- [ ] Use quorum queues for HA-sensitive demo queues
- [ ] Define requests/limits
- [ ] Add PodDisruptionBudget / topology spread where appropriate
- [ ] Store credentials in OpenBao, materialize through ESO
- [ ] Expose management UI only through authenticated/TLS route
- [ ] Add ServiceMonitor/metrics

## P1 — autoscaling

### Resource HPA
- [ ] Install/verify metrics-server if needed
- [ ] Add HPA to Go consumer based on CPU/memory
- [ ] Define sane requests before enabling HPA

### Queue-driven autoscaling
- [ ] Install KEDA
- [ ] Configure RabbitMQ scaler
- [ ] Scale Go consumers from queue depth
- [ ] Define min/max replicas
- [ ] Test scale-up under backlog
- [ ] Test scale-down after drain
- [ ] Document behavior when RabbitMQ is unavailable

## P1 — Go demo workloads

- [ ] Producer service
- [ ] Consumer service
- [ ] Non-root containers
- [ ] Read-only root filesystem where possible
- [ ] Drop Linux capabilities
- [ ] health/readiness probes
- [ ] resource requests/limits
- [ ] NetworkPolicies
- [ ] secrets from ESO
- [ ] image signatures with cosign
- [ ] publish to local Gitea OCI registry
- [ ] deploy with Argo CD

## P2 — Argo Workflows / CI

- [ ] Install Argo Workflows
- [ ] Workflow RBAC with least privilege
- [ ] Build Go images
- [ ] Run tests/lint
- [ ] push images to Gitea registry
- [ ] sign with cosign
- [ ] update image tag/digest in GitOps repo
- [ ] avoid storing registry credentials directly in Workflow manifests

## P2 — policy/security

- [ ] Decide Kyverno vs Gatekeeper
- [ ] Enforce:
  - no privileged pods by default
  - non-root
  - required requests/limits
  - approved registries
  - immutable image digests for selected workloads
  - disallow `latest`
- [ ] Trivy operator or equivalent
- [ ] NetworkPolicy default-deny per application namespace
- [ ] Separate AppProjects for platform/apps/workflows when maturity justifies it
- [ ] Reduce broad wildcard permissions in current `platform` AppProject

## P2 — storage

- [ ] Choose local storage strategy for worker `/dev/vdb` disks
- [ ] Evaluate local-path-provisioner vs OpenEBS/LVM alternative
- [ ] Define failure expectations: local storage is not automatically HA
- [ ] Backups before stateful workload expansion

## Definition of done

This lab reaches its target state when:
- platform changes flow through Git and Argo CD,
- public-facing lab services use Gateway API + TLS,
- secrets originate from OpenBao,
- RabbitMQ is HA and observable,
- Go workers scale via HPA and KEDA queue depth,
- CI runs through Argo Workflows,
- images live in local Gitea OCI and are signed,
- core policies prevent insecure workload defaults.
