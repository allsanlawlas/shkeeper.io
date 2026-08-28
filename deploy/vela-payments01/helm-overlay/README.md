# vela-payments01 deployment overlay

This directory is the secret-free deployment contract for `vela-payments01`.

## Supported payment assets

Customer-facing assets are exactly BTC, ETH USDC, ETH USDT, Polygon USDC,
Polygon USDT, Solana USDC, Solana USDT, and Tron USDT. Native ETH, POL, SOL,
and TRX remain disabled as customer wallets and are retained only as gas in
the corresponding adapter-controlled wallets.

## Normal configuration model

1. Change `values-vela-payments01.yaml` for chart-supported configuration.
2. Reapply the chart patches in this exact order: `r27`, `r30c`, `r32`, `r39`,
   then `r2-chart-alignment`, against the chart at `UPSTREAM_CHART_COMMIT`.
3. Run Helm lint and render checks.
4. Review `helm diff` against the live release.
5. Use `helm upgrade --install` only after the separate deployment gate.

An application image rebuild is required only for application-source changes.
dRPC endpoint rotation and other credentials require a Kubernetes Secret
update, encrypted backup, and a controlled restart of the affected adapter;
they never belong in values, Git, a command argument, or evidence.

## Boundaries

- `shkeeper-external` is disabled; initial ingress is prohibited.
- Disabled full-node, disabled-chain, Lightning, and Monero PVC templates are
  conditionally suppressed; the accepted request is exactly 237 GiB.
- Chart-generated Secret objects are disabled.
- `shkeeper-networkpolicies.yaml` supplies the namespace-wide base policies.
- `trongrid-mainnet-proxy.yaml` remains authoritative for the deferred
  `tron-adapter-egress` policy and the already-installed proxy boundary.
- `bitcoin-core-mainnet.yaml` is maintained separately from the Helm release.
- The accepted TronGrid watchdog is maintained separately and may restart only
  `trongrid-mainnet-proxy` under its frozen failure/cooldown contract.
