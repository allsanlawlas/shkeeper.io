# vela-payments01 Helm overlay

This directory contains the small, reproducible deployment overlay for the payment server. It does not contain provider keys, wallet keys, database passwords, or rendered production Secrets.

## Frozen inputs

- Application source: `allsanlawlas/shkeeper.io@5218f3f7e1fef173af66905bac82c379d16086a4`
- Upstream chart: `vsys-host/helm-charts@2fb730bb4167d82a68f78eaf1207001cc0a901f5`
- Proxy image: `nginx@sha256:8a4f4b94275ff59d809477799cbbaf1a7ab65ed1871403d05e31fd66bdb8db82`

## Files

- `r27-drpc-secretref.patch`: replaces six EVM/Solana endpoint values with encrypted Kubernetes Secret references.
- `r30c-chart-hardening.patch`: adds the TRON adapter egress label and replaces the upstream MariaDB plaintext password with `shkeeper-mariadb-root:password` Secret references.
- `values-vela-payments01.yaml`: freezes the customer-payment asset matrix and internal provider routing without secret values.
- `trongrid-mainnet-proxy.yaml`: the hardened two-replica ClusterIP proxy and three NetworkPolicies.
- `final-chart-policy.txt`: the asset, gas, provider-key, backup, and recovery contract.
- `UPSTREAM_CHART_COMMIT`: the exact chart base required before applying patches.

Kubernetes automatically replaces failed proxy pods through the two-replica Deployment and liveness probe. There is no custom watchdog, CronJob, RBAC controller, or PodDisruptionBudget.

The local pruned Bitcoin node, real provider Secrets, encrypted backup, gas funding, deployment, and mainnet acceptance tests remain separate later gates.
