# solidity-core-labs

> Audit-level thinking. Not just code.

This repository is part of my **'Solidity Core Labs'** series — a deep dive into EVM behavior, smart contract design, and real-world pitfalls. Focused on building audit-level thinking, not just writing code.

---

## Vision

Most Solidity repos teach syntax. This one teaches **consequence**.

Every lab in this series is designed around a single atomic concept — explored from first principles, stress-tested at the edges, and mapped to real-world exploits and losses. The goal is not to write correct code. The goal is to understand *why* code breaks — and what it costs when it does.

This is a living portfolio of EVM mastery, built one phase at a time.

---

## Lab Roadmap

| Phase | Lab | Status | Concept |
|-------|-----|--------|---------|
| 01 | `integer-overflow` | ✅ | Arithmetic safety, `unchecked` blocks, type truncation |
| 02 | `storage-layout` | ✅ | Slot packing, collision, proxy risks |
| 03 | `calldata-vs-memory` | 🔜 | Data location costs & ABI encoding |
| 04 | `reentrancy` | 🔜 | CEI pattern, guards, cross-function attacks |
| 05 | `access-control` | 🔜 | tx.origin, msg.sender, role misuse |
| 06 | `delegatecall-risks` | 🔜 | Context hijack, proxy storage collision |
| 07 | `oracle-manipulation` | 🔜 | Spot price abuse, TWAP design |
| 08 | `erc20-edge-cases` | 🔜 | Fee-on-transfer, rebase tokens, missing returns |
| 09 | `selfdestruct-forcefeed` | 🔜 | ETH force-send, balance assumptions |
| 10 | `commit-reveal` | 🔜 | Frontrunning, block.timestamp abuse |
| 11 | `minimal-proxy` | 🔜 | EIP-1167, clone factories, init risks |
| 12 | `yul-core` | 🔜 | Inline assembly, memory layout, custom errors |

---

## How to Run the Labs

### Prerequisites

**Install Foundry** (one-time setup):

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

Verify installation:

```bash
forge --version
```

### Clone & Install

```bash
git clone https://github.com/<your-username>/solidity-core-labs.git
cd solidity-core-labs
forge install foundry-rs/forge-std --no-commit
```

### Run All Labs

```bash
# Run every test in the repo
forge test

# Run with verbosity (see logs + revert reasons)
forge test -vvv

# Full gas report across all labs
forge test --gas-report
```

### Run a Specific Lab

```bash
# Pattern: forge test --match-path "test/<lab-folder>/*"
forge test --match-path "test/01-integer-overflow/*" -v
forge test --match-path "test/02-storage-layout/*" -v
```

### Run a Single Test

```bash
# Pattern: forge test --match-test "<test_function_name>"
forge test --match-test "test_collision_vulnerableLogicCorruptsImplementationPointer" -vvv
```

### Coverage

```bash
forge coverage
forge coverage --match-path "test/02-storage-layout/*"
```

---

## Tools

- **Foundry** — testing, fuzzing, invariant testing
- **forge-std** — test utilities, cheatcodes
- **slither** (optional, per lab) — static analysis

---

## Structure

```
/labs       → Contract source per lab
/test       → Foundry tests per lab
/notes      → Audit notes, gotchas, mental models
/scripts    → Deployment + interaction scripts
```

---

*Built incrementally. Each lab = one branch, one PR, one commit to mastery.*
