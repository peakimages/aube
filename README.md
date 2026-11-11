# aube

[![Release](https://img.shields.io/github/actions/workflow/status/peakimages/aube/release.yaml?branch=main&label=release)](https://github.com/peakimages/aube/actions/workflows/release.yaml)
[![aube](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fpeakimages%2Faube%2Fmain%2Fsrc%2Fupstream.json&query=%24.aube.latest.version&label=aube)](https://github.com/peakimages/aube/releases)
[![License](https://img.shields.io/github/license/peakimages/aube)](LICENSE)
[![Docker pulls](https://img.shields.io/docker/pulls/peakimages/aube)](https://hub.docker.com/r/peakimages/aube)
[![Image size](https://img.shields.io/docker/image-size/peakimages/aube/latest?arch=amd64)](https://hub.docker.com/r/peakimages/aube)

## Introduction

A minimal image of [aube](https://aube.sh), the Node.js package manager, for Docker build stages. It brings the static `aube` binary into any stage with one line, or is the build stage itself, with Node.js 22, 24 or 26 and aube as the package manager.

> [!IMPORTANT]
> `peakimages/aube` is currently **v0** and subject to breaking changes prior to `v1.0.0`. Pin to a specific version like `peakimages/aube:2.10.0-node24-v0.1.0` to avoid breaking changes.

### What Makes This Image Different?

aube ships as one static binary and has no official image. Bringing it into a build means a download, a checksum per platform and a signature check in every Dockerfile, so this image does that once and hands every build the verified binary.

- ✅ Verified Source: The signature of an aube release is checked when it is pinned, size and SHA-256 of the archive before each build
- ✅ One Line: `COPY --from` puts the static binary into any build stage, on Alpine, Debian or any other base
- ✅ Unprivileged User: The Node.js variations run as root like the official `node` image and bring the user `65532` for a build without root
- ✅ One Package Manager: The Node.js variations ship Node.js and aube, without npm, yarn and corepack
- ✅ No Surprise Downloads: A project that pins another Node.js fails the build, a pin on another aube is ignored
- ✅ Portable `node_modules`: Packages are installed into the project, so a later stage can copy them
- ✅ Modern Architecture: OCI labels, reproducible builds, provenance and SBOM attestations
- ✅ Always Current: GitHub is checked twice a day and new aube releases become new images
- ✅ Multi-Architecture: Builds for `linux/amd64` and `linux/arm64`, the Linux platforms aube is released for
- ✅ Tested: Every release is tested on both platforms before it is published

## Getting Started

aube reads the lockfile a project already has, `aube-lock.yaml`, `pnpm-lock.yaml`, `package-lock.json`, `yarn.lock` or `bun.lock`, and keeps its format.

> [!NOTE]
> The layers of the image are compressed with zstd, pulling it needs Docker Engine 23.0 or later.

### Node.js Variation

A build stage with Node.js and aube:

```dockerfile
FROM peakimages/aube:2.10.0-node24-v0.1.0 AS build
COPY package.json aube-lock.yaml ./
RUN aube ci
COPY . .
RUN aube run --no-install build

FROM your-runtime-image
COPY --from=build /app/dist ./dist
```

The stage runs as root in `/app`, like a stage on the official `node` image.

### aube for Other Images

The default variation holds the static binary, any build stage with Node.js can copy it:

```dockerfile
FROM peakimages/aube:2.10.0-v0.1.0 AS aube

FROM node:24-alpine AS build
COPY --from=aube /usr/local/bin/ /usr/local/bin/
ENV CI=true AUBE_RUNTIME_ON_FAIL=error AUBE_MANAGE_PACKAGE_MANAGER_VERSIONS=false
WORKDIR /app
COPY package.json aube-lock.yaml ./
RUN aube ci
```

Copy the directory and not the three files, `aubr` and `aubx` are links to `aube`.

## Available Image Variations

All tags follow this pattern, the default variation leaves out `-{{variation}}`:

```sh
peakimages/aube:{{aube-version}}-{{variation}}-v{{image-version}}
```

| Variation | Best For                                          | Example                                |
| --------- | ------------------------------------------------- | -------------------------------------- |
| default   | Copying aube into a build stage that has Node.js  | `peakimages/aube:2.10.0-v0.1.0`        |
| `node22`  | A build stage on Node.js 22, LTS until 2027-04-30 | `peakimages/aube:2.10.0-node22-v0.1.0` |
| `node24`  | A build stage on Node.js 24, LTS until 2028-04-30 | `peakimages/aube:2.10.0-node24-v0.1.0` |
| `node26`  | A build stage on Node.js 26, LTS until 2029-04-30 | `peakimages/aube:2.10.0-node26-v0.1.0` |

### Tags

| Tag                                                | Meaning                                                                       |
| -------------------------------------------------- | ----------------------------------------------------------------------------- |
| `2.10.0-v0.1.0`, `2.10.0-node24-v0.1.0`            | Immutable: aube 2.10.0 built as image v0.1.0, never rebuilt                   |
| `2.10.0`, `2.10`, `2`                              | Newest release of that aube patch, minor or major version                     |
| `latest`                                           | Newest release                                                                |
| `preview`                                          | Newest prerelease, like `2.10.0-v0.2.0-beta.1`, until its release replaces it |
| `2.10.0-node24`, `latest-node24`, `preview-node24` | The same for a variation                                                      |

### Registries

| 📦 Registry                                                                         | 🐳 Image                                                                                                              |
| ----------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| [Docker Hub](https://hub.docker.com/r/peakimages/aube)                              | ![peakimages/aube](https://img.shields.io/github/v/release/peakimages/aube?label=peakimages%2Faube)                   |
| [GitHub Container Registry](https://github.com/peakimages/aube/pkgs/container/aube) | ![ghcr.io/peakimages/aube](https://img.shields.io/github/v/release/peakimages/aube?label=ghcr.io%2Fpeakimages%2Faube) |

## Configuration

The Node.js variations set these defaults, override them with `ENV` in your stage. `COPY --from` copies no environment, so set them next to the `COPY` of the default variation.

| Variable                               | Default | Meaning                                                                                                 |
| -------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------- |
| `CI`                                   | `true`  | Packages are installed into `node_modules` of the project instead of linked to a store outside it       |
| `AUBE_RUNTIME_ON_FAIL`                 | `error` | A project that pins a Node.js version the image does not have fails instead of downloading it           |
| `AUBE_MANAGE_PACKAGE_MANAGER_VERSIONS` | `false` | A `packageManager` pin on another aube is ignored instead of downloading it and running it in its place |

## Attestations

Every image carries an SBOM and a provenance attestation.

The SBOM lists the packages of the image:

```sh
docker buildx imagetools inspect peakimages/aube:latest-node24 --format '{{ json .SBOM }}'
```

The provenance records how the image was built:

```sh
docker buildx imagetools inspect peakimages/aube:latest-node24 --format '{{ json .Provenance }}'
```

A scanner lists the same packages, Trivy all but aube and Node.js:

```sh
syft peakimages/aube:latest-node24
grype peakimages/aube:latest-node24
trivy image peakimages/aube:latest-node24
```

## Releases

Every aube release becomes a new version of the image. A check for new aube releases runs twice a day.

The image version follows semantic versioning independently of aube. Changes to the image are listed in [CHANGELOG.md](CHANGELOG.md).

## Trademarks

This image is built and published by PeakImages. All third-party product names, logos and trademarks are the property of their respective owners and are used solely for identification. PeakImages claims no interest in those marks, and no affiliation, sponsorship or endorsement is implied.
