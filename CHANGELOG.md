# Changelog

All lab additions follow [Semantic Versioning](https://semver.org/) per phase.

---

## [Unreleased]

---

## [0.1.0] — Phase 01 — Integer Overflow & Underflow (2026-04-22)
### Added
- `labs/01-integer-overflow/IntegerMath.sol` — checked vs unchecked arithmetic, truncating casts, BEC-pattern mul
- `labs/01-integer-overflow/UnsafeCounter.sol` — pre-0.8 overflow simulation (pragma 0.7.6)
- `labs/01-integer-overflow/README.md` — audit checklist, BEC exploit context, key takeaways
- `test/01-integer-overflow/IntegerMath.t.sol` — 6 Foundry tests: overflow, underflow, cast truncation, mul wrap, safe loop

### Changed
- `README.md` — Phase 01 status updated to ✅

---

## [0.0.1] — Initial Commit (2026-04-22)
### Added
- Repository skeleton: `/labs`, `/test`, `/notes`, `/scripts`
- Root `README.md` with vision, lab roadmap, and tooling overview
- `CHANGELOG.md` for incremental phase tracking
- `foundry.toml` base configuration (fuzz: 256 runs, invariant: 64 runs)

---

*Labs added incrementally via separate branches and pull requests from Phase 01 onward.*
