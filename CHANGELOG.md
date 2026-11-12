# Changelog

All notable changes to this project will be documented in this file. aube version bumps are not listed, every release tag names the aube version it ships.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v0.1.0] - 2026-11-12

### Added

- Minimal aube image on `scratch` with the static `aube` binary and `aubr` and `aubx` shortcuts
  - The flavors `node22`, `node24` and `node26` add Node.js 22, 24 and 26, without npm, yarn and corepack
  - The `nonroot` user `65532` is there for a build without root
  - The platforms are `amd64` and `arm64`

