# Changelog

All lab additions follow [Semantic Versioning](https://semver.org/) per phase.

---

## [Unreleased]

---

## [0.2.0] — Phase 02 — Storage Layout & Slot Collision
### Added
- `labs/02-storage-layout/StorageLayout.sol` — slot packing, declaration order, dynamic type slots
- `labs/02-storage-layout/StorageCollision.sol` — ProxyStore + VulnerableLogic (collision) + SafeLogic (gap pattern)
- `labs/02-storage-layout/README.md` — audit checklist, Audius exploit context, EIP-1967 rationale
- `test/02-storage-layout/StorageLayout.t.sol` — 7 Foundry tests using vm.load for raw slot inspection

### Changed
- `README.md` — Phase 02 status updated to ✅
- `CHANGELOG.md` — Phase 02 entry appended

---

## [0.1.0] — Phase 01 — Integer Overflow & Underflow
### Added
- `labs/01-integer-overflow/IntegerMath.sol` — checked vs unchecked arithmetic, truncating casts
- `labs/01-integer-overflow/UnsafeCounter.sol` — pre-0.8 overflow simulation (pragma 0.7.6)
- `labs/01-integer-overflow/README.md` — audit notes, BEC exploit context, key takeaways
- `test/01-integer-overflow/IntegerMath.t.sol` — 6 Foundry tests

### Changed
- `README.md` — Phase 01 status updated to ✅

---

## [0.0.1] — Initial Commit
### Added
- Repository skeleton: `/labs`, `/test`, `/notes`, `/scripts`
- Root `README.md`, `CHANGELOG.md`, `foundry.toml`, `.gitignore`
