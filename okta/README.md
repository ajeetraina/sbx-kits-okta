# okta — Docker Sandboxes kit (v3)

A **mixin** that adds the [Okta CLI](https://github.com/okta/okta-cli) (`okta`)
to any sandbox workload. Compose it onto an agent and that agent can register
Okta orgs, create and manage OIDC/SAML apps, and scaffold sample integrations.

| | |
|---|---|
| Kind | `mixin` |
| Provides | `okta@<version>` |
| Tool version | `0.10.0` (override with `--build-arg OKTA_VERSION=…` / the `version` arg) |
| Platform | **`linux/amd64` only** — the Okta CLI ships no arm64 binary |
| License | Apache-2.0 (tool) |

## What it declares

- **`network-policy@1`** — runtime egress to `start.okta.dev`, `*.okta.com`,
  `*.oktapreview.com`, and GitHub (`okta start` sample clones). Nothing else.
- **`agent-context@1`** — [`okta-context.md`](./okta-context.md), telling the
  agent how to authenticate and what the network allows.

No credential capability is declared: an Okta org is a per-user subdomain, so a
fixed inject domain cannot be known at author time. Authenticate with
`OKTA_CLIENT_ORGURL` + `OKTA_CLIENT_TOKEN`, or interactively via `okta login`.

## Build

```sh
cd okta

# validate the descriptor (fast, no content build)
docker buildx build . -f okta.yaml --platform linux/amd64 --output type=cacheonly

# build + export an OCI layout for conformance
docker buildx build . -f okta.yaml -t okta:0.10.0 --platform linux/amd64 \
  --output type=oci,dest=/tmp/okta-layout,tar=false

# conformance (tag only, not okta:0.10.0)
kit-tck validate --layout /tmp/okta-layout 0.10.0
```

## Run

```sh
# compose onto a workload and run the tool (amd64 host or emulation)
sbx run ./<workload> --kit ./okta .
sbx kit inspect ./okta            # resolved declarations, no sandbox
```

Inside the sandbox: `okta --help`. See [`okta-context.md`](./okta-context.md)
for authentication and the network allow list.

## Publish

```sh
docker buildx build . -f okta.yaml --platform linux/amd64 --push \
  -t <registry>/okta:0.10.0 -t <registry>/okta:latest \
  --metadata-file /tmp/okta-push.json
```

Single-platform (amd64) on purpose — pushing an arm64 build would serve a
binary that does not exist for that arch.
