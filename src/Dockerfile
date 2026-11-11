# syntax=docker/dockerfile:1

# Set by scripts/check-upstream.sh
ARG AUBE_VERSION=2.10.0

# Dependencies
# https://hub.docker.com/_/alpine/tags?name=3.24.4
ARG BASE_IMAGE=alpine:3.24.4@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf
# https://pkgs.alpinelinux.org/package/v3.24/main/x86_64/libstdc++
ARG LIBSTDCXX_VERSION=15.2.0-r5
# https://pkgs.alpinelinux.org/package/v3.24/main/x86_64/libatomic
ARG LIBATOMIC_VERSION=15.2.0-r5
# https://github.com/anchore/syft/tree/v1.57.1/schema/json
ARG SYFT_SCHEMA_VERSION=16.1.13
# https://hub.docker.com/_/node/tags?name=22-alpine3.24
ARG NODE_22=22.23.5-alpine3.24@sha256:1314fb30ec37592d5845e5a160d522c0e680972aa534549940b8d73bde88481a
# https://hub.docker.com/_/node/tags?name=24-alpine3.24
ARG NODE_24=24.22.3-alpine3.24@sha256:116b800c3754b440ee0aa3ed2f20f5bf3d99a554bfd9adeea09ea8017f6e85f5
# https://hub.docker.com/_/node/tags?name=26-alpine3.24
ARG NODE_26=26.13.1-alpine3.24@sha256:6bd9ab43c0ec0190ca7b2d193906cb8b7edf6e7f4afa43ddeccd6452710bffb5

# Set by the build workflow
ARG IMAGE_VERSION
ARG SOURCE_DATE_EPOCH
ARG CREATED
ARG GIT_SHA

FROM ${BASE_IMAGE} AS build

ARG AUBE_VERSION
ARG IMAGE_VERSION
ARG SYFT_SCHEMA_VERSION
ARG TARGETPLATFORM

# curl and jq are only used during the build stage, so they are not pinned to a specific version
# hadolint ignore=DL3018
RUN apk add --no-cache curl jq

WORKDIR /src
COPY --chmod=0644 upstream.json verify.sh ./
RUN jq --arg version "$AUBE_VERSION" --arg platform "$TARGETPLATFORM" '.aube[] | select(.version == $version) | .platforms[$platform]' upstream.json > aube.json \
    && curl --proto '=https' --tlsv1.2 -sSfL --retry 3 -o aube.tar.gz "$(jq -r .url aube.json)" \
    && sh verify.sh

COPY --chmod=0644 rootfs.sh /src/
RUN sh /src/rootfs.sh

# A scratch image has no package database for the SBOM scanner to read, this syft JSON document takes its place
COPY --chmod=0644 sbom.sh /src/
RUN sh /src/sbom.sh "peakimages/aube:${AUBE_VERSION}-v${IMAGE_VERSION:?}" \
        "generic|aube|${AUBE_VERSION}|MIT|$(jq -r .url /src/aube.json)|aubepkg:aube"

FROM node:${NODE_22} AS node22-binary
FROM node:${NODE_24} AS node24-binary
FROM node:${NODE_26} AS node26-binary

FROM ${BASE_IMAGE} AS node

ARG AUBE_VERSION
ARG IMAGE_VERSION
ARG BASE_IMAGE
ARG LIBSTDCXX_VERSION
ARG NODE_22
ARG NODE_24
ARG NODE_26
ARG CREATED
ARG GIT_SHA

RUN apk add --no-cache --no-logfile libstdc++=${LIBSTDCXX_VERSION} \
    && echo "nonroot:x:65532:65532:nonroot:/home/nonroot:/sbin/nologin" >> /etc/passwd \
    && echo "nonroot:x:65532:" >> /etc/group \
    && install -d -o 65532 -g 65532 /home/nonroot

COPY --from=build /rootfs/usr/local/bin/ /usr/local/bin/
COPY --from=build /rootfs/var/lib/db/sbom/ /var/lib/db/sbom/

LABEL org.opencontainers.image.title="aube" \
    org.opencontainers.image.description="Minimal aube Docker image for build stages, with or without Node.js." \
    org.opencontainers.image.created="${CREATED}" \
    org.opencontainers.image.revision="${GIT_SHA}" \
    org.opencontainers.image.licenses="MIT AND Apache-2.0 AND BSD-2-Clause AND Zlib AND MPL-2.0 AND GPL-2.0-only AND GPL-2.0-or-later AND LGPL-2.1-or-later AND AGPL-3.0-or-later" \
    org.opencontainers.image.authors="peakimages" \
    org.opencontainers.image.vendor="peakimages" \
    org.opencontainers.image.url="https://hub.docker.com/r/peakimages/aube" \
    org.opencontainers.image.source="https://github.com/peakimages/aube" \
    org.opencontainers.image.documentation="https://github.com/peakimages/aube#readme" \
    org.opencontainers.image.base.name="${BASE_IMAGE}" \
    dev.peakimages.aube.version="${AUBE_VERSION}" \
    dev.peakimages.image.version="${IMAGE_VERSION}"

# https://aube.sh/settings/
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    CI=true \
    AUBE_RUNTIME_ON_FAIL=error \
    AUBE_MANAGE_PACKAGE_MANAGER_VERSIONS=false

WORKDIR /app

CMD ["aube", "--help"]

FROM node AS node22
COPY --from=node22-binary /usr/local/bin/node /usr/local/bin/node
LABEL org.opencontainers.image.version="${AUBE_VERSION}-node22-v${IMAGE_VERSION}" \
    dev.peakimages.node.version="${NODE_22%%-*}"

FROM node AS node24
COPY --from=node24-binary /usr/local/bin/node /usr/local/bin/node
LABEL org.opencontainers.image.version="${AUBE_VERSION}-node24-v${IMAGE_VERSION}" \
    dev.peakimages.node.version="${NODE_24%%-*}"

FROM node AS node26
ARG LIBATOMIC_VERSION
COPY --from=node26-binary /usr/local/bin/node /usr/local/bin/node
# Node.js 26 links against libatomic on amd64
RUN apk add --no-cache --no-logfile libatomic=${LIBATOMIC_VERSION}
LABEL org.opencontainers.image.version="${AUBE_VERSION}-node26-v${IMAGE_VERSION}" \
    dev.peakimages.node.version="${NODE_26%%-*}"

FROM scratch AS default

ARG AUBE_VERSION
ARG IMAGE_VERSION
ARG CREATED
ARG GIT_SHA

COPY --from=build /rootfs/ /

LABEL org.opencontainers.image.title="aube" \
    org.opencontainers.image.description="Minimal aube Docker image for build stages, with or without Node.js." \
    org.opencontainers.image.version="${AUBE_VERSION}-v${IMAGE_VERSION}" \
    org.opencontainers.image.created="${CREATED}" \
    org.opencontainers.image.revision="${GIT_SHA}" \
    org.opencontainers.image.licenses="MIT AND AGPL-3.0-or-later" \
    org.opencontainers.image.authors="peakimages" \
    org.opencontainers.image.vendor="peakimages" \
    org.opencontainers.image.url="https://hub.docker.com/r/peakimages/aube" \
    org.opencontainers.image.source="https://github.com/peakimages/aube" \
    org.opencontainers.image.documentation="https://github.com/peakimages/aube#readme" \
    org.opencontainers.image.base.name="scratch" \
    dev.peakimages.aube.version="${AUBE_VERSION}" \
    dev.peakimages.image.version="${IMAGE_VERSION}"

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

USER 65532:65532

ENTRYPOINT ["/usr/local/bin/aube"]
