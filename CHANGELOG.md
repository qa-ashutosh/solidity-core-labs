# Changelog

All lab additions follow [Semantic Versioning](https://semver.org/) per phase.

---

## [Unreleased]

---

## [0.4.0] — Phase 04 — Reentrancy
### Added
- `labs/04-reentrancy/VulnerableVault.sol` — ETH vault with classic reentrancy bug (Interaction before Effect)
- `labs/04-reentrancy/SecureVault.sol` — ETH vault with CEI pattern + nonReentrant guard
- `labs/04-reentrancy/Attacker.sol` — live exploit contract + FailedAttacker against secure vault
- `labs/04-reentrancy/README.md` — CEI pattern, DAO exploit context, audit checklist
- `test/04-reentrancy/Reentrancy.t.sol` — 7 tests including live drain exploit + failed attack proof

### Changed
- `README.md` — Phase 04 status updated to ✅, attack trace commands added
- `CHANGELOG.md` — Phase 04 entry appended

---

## [0.3.0] — Phase 03 — Calldata vs Memory vs Storage
### Added
- `labs/03-calldata-vs-memory/DataLocations.sol`
- `labs/03-calldata-vs-memory/MemoryExpansion.sol`
- `labs/03-calldata-vs-memory/README.md`
- `test/03-calldata-vs-memory/DataLocations.t.sol` — 10 tests

---

## [0.2.0] — Phase 02 — Storage Layout & Slot Collision
### Added
- `labs/02-storage-layout/StorageLayout.sol`
- `labs/02-storage-layout/StorageCollision.sol`
- `labs/02-storage-layout/README.md`
- `test/02-storage-layout/StorageLayout.t.sol` — 7 tests

---

## [0.1.0] — Phase 01 — Integer Overflow & Underflow
### Added
- `labs/01-integer-overflow/IntegerMath.sol`
- `labs/01-integer-overflow/UnsafeCounter.sol`
- `labs/01-integer-overflow/README.md`
- `test/01-integer-overflow/IntegerMath.t.sol` — 6 tests

---

## [0.0.1] — Initial Commit
### Added
- Repository skeleton: `/labs`, `/test`, `/notes`, `/scripts`
- Root `README.md`, `CHANGELOG.md`, `foundry.toml`, `.gitignore`
