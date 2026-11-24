# Okta CLI

The `okta` CLI is installed at `/usr/local/bin/okta`. It configures
applications to use Okta: it can register a new Okta org, create and manage
OIDC/SAML apps, and scaffold runnable sample integrations.

Run `okta --help` for the full command list. The top-level commands are
`register`, `login`, `apps`, and `start`. Add `--batch` to any command to run
non-interactively (it never prompts and fails instead of asking).

## Authenticating

There is no shared credential injected for you — an Okta org lives at a
per-user subdomain (e.g. `dev-123456.okta.com`) that cannot be known ahead of
time. Authenticate one of two ways:

- **Non-interactive (preferred for agents).** Set these two variables when you
  start the sandbox, then use the CLI directly:
  - `OKTA_CLIENT_ORGURL` — your org, e.g. `https://dev-123456.okta.com`
  - `OKTA_CLIENT_TOKEN` — an Okta API token (SSWS) from
    *Admin → Security → API → Tokens*
- **Interactive.** Run `okta login` and paste your org URL and API token when
  prompted; or `okta register --batch ...` to create a brand-new org. Either
  writes `~/.okta/okta.yaml`. Note this config is **not persisted** across
  sandbox recreation — prefer the env-var path for repeatable runs.

## Network

Egress is allowed only to the hosts this tool actually uses:
`start.okta.dev` (the CLI registration + sample-catalog API), `*.okta.com` and
`*.oktapreview.com` (your org), and GitHub (`okta start` clones the sample).

If your org uses a **custom domain** (not `*.okta.com`/`*.oktapreview.com`),
calls to it will be refused by the sandbox network policy — surface that to the
user rather than retrying; the kit's allow list has to be extended for that
host.

Note that `okta start` *generates* a sample app and then builds/runs it with
its own toolchain (Maven, npm, …); that build reaches registries this kit does
not open. Scaffolding works out of the box; building the generated sample may
need additional egress.

## Platform

The Okta CLI ships an x86_64-only native binary, so this kit requires a
`linux/amd64` sandbox. On an arm64 host it runs only under emulation.
