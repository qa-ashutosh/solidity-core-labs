# Changelog

All lab additions follow [Semantic Versioning](https://semver.org/) per phase.

---

## [Unreleased]

---

## [0.3.0] — Phase 03 — Calldata vs Memory vs Storage
### Added
- `labs/03-calldata-vs-memory/DataLocations.sol` — calldata vs memory params, storage pointer vs memory copy, ghost write pattern
- `labs/03-calldata-vs-memory/MemoryExpansion.sol` — non-linear memory cost, allocation in loops, no-alloc pattern
- `labs/03-calldata-vs-memory/README.md` — audit checklist, ghost write scenario, memory griefing context
- `test/03-calldata-vs-memory/DataLocations.t.sol` — 10 Foundry tests covering correctness + silent no-op proof

### Changed
- `README.md` — Phase 03 status updated to ✅
- `CHANGELOG.md` — Phase 03 entry appended

---

## [0.2.0] — Phase 02 — Storage Layout & Slot Collision
### Added
- `labs/02-storage-layout/StorageLayout.sol` — slot packing, declaration order, dynamic type slots
- `labs/02-storage-layout/StorageCollision.sol` — ProxyStore + VulnerableLogic + SafeLogic
- `labs/02-storage-layout/README.md`
- `test/02-storage-layout/StorageLayout.t.sol` — 7 Foundry tests using vm.load

### Changed
- `README.md` — Phase 02 status ✅

---

## [0.1.0] — Phase 01 — Integer Overflow & Underflow
### Added
- `labs/01-integer-overflow/IntegerMath.sol`
- `labs/01-integer-overflow/UnsafeCounter.sol`
- `labs/01-integer-overflow/README.md`
- `test/01-integer-overflow/IntegerMath.t.sol` — 6 Foundry tests

### Changed
- `README.md` — Phase 01 status ✅

---

## [0.0.1] — Initial Commit
### Added
- Repository skeleton: `/labs`, `/test`, `/notes`, `/scripts`
- Root `README.md`, `CHANGELOG.md`, `foundry.toml`, `.gitignore`
