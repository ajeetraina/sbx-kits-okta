# syntax=docker/dockerfile:1

# The Okta CLI publishes ONE Linux artifact: a GraalVM-native binary for
# x86_64 only (okta-cli-linux-<version>-x86_64.zip). There is no linux/arm64
# release, so this kit is linux/amd64-only — build with --platform linux/amd64.
# The binary is fully self-contained (no JRE, no shared-library closure, no
# symlinks), which is exactly what travels cleanly in an overlay.
#
# The build stage runs on $BUILDPLATFORM (the native builder arch) so curl and
# unzip need no emulation — they only move bytes, never the amd64 okta binary.
# We make the pin a real claim by verifying the download's SHA-256 rather than
# executing `okta --version`: the binary is a foreign arch the builder may be
# unable to run (e.g. an arm64 host with no amd64 binfmt, as `sbx` uses), and a
# byte-exact digest is a stronger claim than a version grep anyway. OKTA_SHA256
# therefore moves together with OKTA_VERSION — bump both or the build fails.

FROM --platform=$BUILDPLATFORM debian:bookworm-slim AS build
ARG OKTA_VERSION
ARG OKTA_SHA256=d089d0a409f0829cba75205bc761f3806f50730303fe2bc5a045ff3a1e4c0ecd
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl unzip \
 && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    mkdir -p /out/usr/local/bin; \
    url="https://github.com/okta/okta-cli/releases/download/okta-cli-tools-${OKTA_VERSION}/okta-cli-linux-${OKTA_VERSION}-x86_64.zip"; \
    curl -fsSL "$url" -o /tmp/okta.zip; \
    # The pin is a claim about content: make the build enforce it, byte-exact.
    echo "${OKTA_SHA256}  /tmp/okta.zip" | sha256sum -c -; \
    unzip -q /tmp/okta.zip -d /out/usr/local/bin; \
    chmod 0755 /out/usr/local/bin/okta; \
    test -s /out/usr/local/bin/okta; \
    # A publisher's archive can carry a foreign uid; normalize to root:root.
    chown -R 0:0 /out

# The overlay: files only, lands on any (amd64) base. Stays out of /home
# entirely, so there is nothing for the home-ownership rule to trip over.
FROM scratch
COPY --from=build /out /
