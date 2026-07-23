# Custom SHKeeper container and Helm deployment

This deployment branch publishes the reviewed HMAC implementation as an
immutable Linux container image in GitHub Container Registry (GHCR). Keep
fork-specific workflow changes on this branch and use
`feature/separate-webhook-hmac-secret` for the upstream pull request.

## Build and image tag

Every push to `deploy/hmac-container` runs the tests on Python 3.11 and 3.13
and, only if they pass, publishes a Linux AMD64 image:

```text
ghcr.io/allsanlawlas/shkeeper:hmac-<12-character-commit-sha>
```

Find the tag and digest in the `publish-custom-container` workflow summary.
The tag identifies the source commit, but deployment must use the digest:

```text
ghcr.io/allsanlawlas/shkeeper@sha256:<IMAGE_DIGEST>
```

The digest is immutable even if someone rebuilds or replaces the tag.

New GHCR packages are private by default. Either change the `shkeeper`
package visibility to public in GitHub's package settings, or create a
Kubernetes pull secret using a classic personal access token with only
`read:packages` access:

```bash
WORKLOAD_NAMESPACE=shkeeper
read -rsp "GHCR read token: " GHCR_PAT
echo

kubectl create secret docker-registry ghcr-pull \
  --namespace "$WORKLOAD_NAMESPACE" \
  --docker-server ghcr.io \
  --docker-username allsanlawlas \
  --docker-password "$GHCR_PAT"

unset GHCR_PAT
```

For a private package, add this to the same `values.yaml` used for SHKeeper:

```yaml
dev:
  imagePullSecrets:
    - name: ghcr-pull
```

Skip the pull secret when the GHCR package is public.

## Record the current installation

Run these commands on the machine that administers the Kubernetes cluster:

```bash
helm list --all-namespaces
```

There are two namespaces to record:

- `RELEASE_NAMESPACE` is the namespace shown by `helm list`; the README
  installation normally uses `default`.
- `WORKLOAD_NAMESPACE` is the chart's `namespace` value; its default is
  `shkeeper`.

Set both values before running the remaining commands:

```bash
RELEASE_NAMESPACE=default
WORKLOAD_NAMESPACE=shkeeper

helm get values shkeeper \
  --namespace "$RELEASE_NAMESPACE" \
  --all \
  --output yaml

kubectl get pods --namespace "$WORKLOAD_NAMESPACE"
```

Keep your existing `values.yaml`; it is the source of truth for enabled
currencies, domains, storage and other settings.

Before any production upgrade, back up the persistent volume or at least the
SQLite database:

```bash
POD="$(kubectl get pods --namespace "$WORKLOAD_NAMESPACE" \
  --selector app.kubernetes.io/name=shkeeper \
  --output jsonpath='{.items[0].metadata.name}')"

kubectl exec --namespace "$WORKLOAD_NAMESPACE" "$POD" -- \
  sqlite3 /shkeeper.io/instance/shkeeper.sqlite \
  ".backup '/shkeeper.io/instance/shkeeper-before-hmac.sqlite'"

kubectl cp \
  "${WORKLOAD_NAMESPACE}/${POD}:/shkeeper.io/instance/shkeeper-before-hmac.sqlite" \
  ./shkeeper-before-hmac.sqlite
```

## Upgrade

Update the chart repository, then pin the same chart version that is shown by
`helm list`. This tests only the custom application image instead of combining
an image change with an unrelated chart upgrade.

```bash
helm repo update

helm upgrade shkeeper vsys-host/shkeeper \
  --namespace "$RELEASE_NAMESPACE" \
  --version <CURRENT_CHART_VERSION> \
  --file values.yaml \
  --set-string shkeeper.image=ghcr.io/allsanlawlas/shkeeper@sha256:<IMAGE_DIGEST> \
  --atomic \
  --wait \
  --timeout 10m
```

The chart uses a `Recreate` deployment strategy, so expect brief downtime.
Verify the application after the upgrade:

```bash
kubectl rollout status deployment/shkeeper-deployment \
  --namespace "$WORKLOAD_NAMESPACE" \
  --timeout 10m

kubectl get pods --namespace "$WORKLOAD_NAMESPACE"
kubectl logs deployment/shkeeper-deployment \
  --namespace "$WORKLOAD_NAMESPACE" \
  --tail 200
```

Test login, existing wallets and invoices, generation and activation of the
HMAC secret, confirmed and unconfirmed invoice callbacks, payout callbacks,
and persistence after restarting the SHKeeper pod.

## Rollback

```bash
helm history shkeeper --namespace "$RELEASE_NAMESPACE"

helm rollback shkeeper <PREVIOUS_REVISION> \
  --namespace "$RELEASE_NAMESPACE" \
  --wait \
  --timeout 10m
```

Helm rollback restores Kubernetes resources but does not reverse database
migrations. This HMAC change has no database migration, but retaining a backup
is still important for future upgrades. Before rolling back to an official
image that predates dedicated HMAC secrets, configure the webhook receiver to
accept API-key signatures again; the older image does not know the dedicated
secret.
