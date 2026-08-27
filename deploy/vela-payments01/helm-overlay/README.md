# vela-payments01 Helm overlay

This directory contains the small, reproducible deployment overlay for the payment server. It does not contain provider keys, wallet keys, database passwords, or rendered production Secrets.

## Frozen inputs

- Repository base: `allsanlawlas/shkeeper.io@ebcf193c42549a4bfdd38da1d91544cab1ce7b27`
- SHKeeper application-image source: `allsanlawlas/shkeeper.io@5218f3f7e1fef173af66905bac82c379d16086a4`
- Upstream chart: `vsys-host/helm-charts@2fb730bb4167d82a68f78eaf1207001cc0a901f5`
- Proxy image: `nginx@sha256:8a4f4b94275ff59d809477799cbbaf1a7ab65ed1871403d05e31fd66bdb8db82`
- Bitcoin Core image: `docker.io/vsyshost/bitcoind@sha256:2266ffb1b21d285105d8e2892d18137c4b81c03cf85b5e35728e929e8edb4c83`

## Files

- `r27-drpc-secretref.patch`: replaces six EVM/Solana endpoint values with encrypted Kubernetes Secret references.
- `r30c-chart-hardening.patch`: adds the TRON adapter egress label and replaces the upstream MariaDB plaintext password with `shkeeper-mariadb-root:password` Secret references.
- `r39-external-secrets-and-bitcoin-route.patch`: suppresses chart-generated Secrets and routes the Bitcoin adapter to `shkeeper-bitcoin-fullnode:endpoint`.
- `values-vela-payments01.yaml`: freezes the customer-payment asset matrix, internal provider routing, and balanced dRPC block-polling intervals without secret values.
- `trongrid-mainnet-proxy.yaml`: the hardened two-replica ClusterIP proxy and three NetworkPolicies.
- `bitcoin-core-mainnet.yaml`: the internal pruned Bitcoin Core Deployment, ClusterIP Service, 200 GiB PVC and NetworkPolicy.
- `required-secrets.txt`: the exact twelve externally created Secret names and keys.
- `final-chart-policy.txt`: the asset, gas, provider-key, backup, and recovery contract.
- `UPSTREAM_CHART_COMMIT`: the exact chart base required before applying patches.

Kubernetes automatically replaces failed proxy pods through the two-replica Deployment and liveness probe. There is no custom watchdog, CronJob, RBAC controller, or PodDisruptionBudget.

Normal payment detection polls Ethereum every 10 seconds and Polygon and Solana every 5 seconds. These settings are separate from the adapters' hourly balance-reconciliation safety task.

The real provider Secrets, encrypted backup, gas funding, deployment, and mainnet acceptance tests remain separate later gates.

## Changing supported currencies later

Currencies already supported and securely bound by the pinned adapters remain controlled in `values-vela-payments01.yaml`. Change only the required `enabled` flags, reproduce Helm lint and the complete render, and then perform a reviewed Helm upgrade. A dormant chain such as BNB requires its one-time RPC Secret and NetworkPolicy binding before its first activation; it does not require reinstalling the server or repeating this deployment design.
