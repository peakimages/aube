# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v2.11.0-v0.1.0] - 2026-11-24

### Changed

- aube from v2.10.1 to v2.11.0, see its [release notes](https://github.com/aubepkg/aube/releases/tag/v2.11.0)

## [v2.10.1-v0.1.0] - 2026-11-17

### Changed

- aube from v2.10.0 to v2.10.1, see its [release notes](https://github.com/aubepkg/aube/releases/tag/v2.10.1)

## [v2.10.0-v0.1.0] - 2026-11-12

### Added

- Minimal aube image on `scratch` with the static `aube` binary and `aubr` and `aubx` shortcuts
  - The flavors `node22`, `node24` and `node26` add Node.js 22, 24 and 26, without npm, yarn and corepack
  - The `nonroot` user `65532` is there for a build without root
  - The platforms are `amd64` and `arm64`

