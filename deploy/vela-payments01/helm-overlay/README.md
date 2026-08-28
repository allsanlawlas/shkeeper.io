# vela-payments01 TronGrid proxy overlay

This directory contains the secret-free, reproducible TronGrid mainnet proxy overlay for `vela-payments01`.

Frozen inputs:

- Application source: `allsanlawlas/shkeeper.io@d639e065aa53ad71dc0a5a586f0c4cb0fef5d1e7`
- Upstream chart: `vsys-host/helm-charts@2fb730bb4167d82a68f78eaf1207001cc0a901f5`
- Proxy image: `nginx@sha256:8a4f4b94275ff59d809477799cbbaf1a7ab65ed1871403d05e31fd66bdb8db82`

No provider key, wallet key, database password, rendered Secret, kubeconfig, or other credential belongs in this directory.

`trongrid-mainnet-proxy.yaml` is the hardened two-replica ClusterIP proxy and its NetworkPolicies. The Secret is created separately through an interactive, non-logged server transaction.

The watchdog contract is frozen here, but its CronJob/RBAC installation remains deferred until the proxy failure-behaviour test passes. It may restart only `deployment/trongrid-mainnet-proxy`; it must never restart Shkeeper.

RPC endpoint and supported-chain changes remain configuration changes through the deployment `values.yaml` followed by `helm upgrade`; they do not require rebuilding the Shkeeper image unless application source code changes.
