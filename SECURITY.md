# Security

This page outlines what is in scope, our support policy and how to report vulnerabilities.

## Scope

Report a vulnerability to the project that maintains the affected code:

- **The image** is built in this repository: the Dockerfile and its build settings, the root filesystem and the workflows that test and publish it. Report it here, see [Reporting a Vulnerability](#reporting-a-vulnerability).
- **aube** is maintained at [aubepkg/aube](https://github.com/aubepkg/aube). Report it there, see its [security policy](https://github.com/aubepkg/aube/security/policy). Every aube release becomes a new image, usually within a day.
- **Node.js** in the `node22`, `node24` and `node26` flavors is the binary of the [official Node.js image](https://hub.docker.com/_/node), pinned by version and digest. Report it to the [Node.js project](https://github.com/nodejs/node/security/policy), a Node.js security release reaches the image with its next release.
- **Alpine packages** in those flavors come from the pinned base image and a pinned `libstdc++` and `libatomic`. Report it to Alpine or the upstream project, the fix reaches the image with its next release.

## Support Policy

Below you can find the support status for different versions of the image. The image version is the `v` part of an image tag, `peakimages/aube:2.10.0-v0.1.0` is image version `v0.1.0`.

| Version | Supported          | Support Status     |
| ------- | ------------------ | ------------------ |
| **1.x** | :white_check_mark: | Unreleased         |
| **0.x** | :white_check_mark: | Active Development |

Immutable tags such as `2.10.0-v0.1.0` and `2.10.0-node24-v0.1.0` are never rebuilt. A fix ships as a new image version, and the floating tags `2.10.0`, `2.10`, `2` and `latest`, and `2.10.0-node24` to `latest-node24` for a flavor, move to it. Builds that pin an immutable tag or a digest receive fixes by moving to the newer one.

## Reporting a Vulnerability

If you find a security vulnerability in a currently supported version, please follow these steps:

1. **DO NOT** disclose the vulnerability publicly.
2. Report it via [GitHub Security Advisories](https://github.com/peakimages/aube/security/advisories/new).
3. Include in your report:
   - **Explanation:** Detailed explanation of the vulnerability.
   - **Affected Versions:** Which image tags are affected.
   - **Reproduction:** Clear steps to reproduce the vulnerability.
   - **Impact:** Assessment of the potential impact of the vulnerability.
