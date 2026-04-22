# Lab 01 — Integer Overflow & Underflow

> EVM arithmetic is modular. Solidity 0.8 added guards. Devs keep removing them.

This repository is part of my **'Solidity Core Labs'** series — a deep dive into EVM behavior, smart contract design, and real-world pitfalls. Focused on building audit-level thinking, not just writing code.

---

## Concept

The EVM operates on 256-bit unsigned integers. Arithmetic is modular by nature:

- `uint256 max + 1 = 0` (overflow wraps to zero)
- `uint256 0 - 1 = 2^256 - 1` (underflow wraps to max)

Solidity 0.8.0 introduced **checked arithmetic by default** — any overflow/underflow reverts.
But this protection disappears the moment you write `unchecked { }`, use inline assembly, or cast between types carelessly.

---

## What This Lab Proves

1. Default Solidity 0.8+ reverts on overflow — but this is a compiler abstraction, not an EVM feature
2. `unchecked` blocks fully restore wrap behavior — intentionally or not
3. Type casting between `uint256`, `uint128`, `uint8` silently truncates
4. Pre-0.8 patterns require manual overflow guards everywhere

---

## Why This Matters in Production

- **Gas optimization PRs** often introduce `unchecked` blocks to save ~20 gas per op without re-auditing invariants
- **Loop counters** in `unchecked` blocks can wrap and cause infinite loops or skipped iterations
- **Token accounting** with truncating casts can silently lose value
- Every `unchecked` block in a codebase is a **manual audit target**

---

## Real-World Loss Scenarios

| Incident | Mechanism | Loss |
|----------|-----------|------|
| BeautyChain (BEC) 2018 | Overflow in `batchTransfer` — multiplication wrapped to 0, enabling arbitrary token minting | ~$900M market cap |
| SmartMesh (SMT) 2018 | Same overflow pattern, different token | ~$140M |
| Pre-0.8 contracts without SafeMath | Direct arithmetic without checks | Systemic |

Modern risk: **any `unchecked` block written for gas savings without re-proving arithmetic safety.**

---

## Files

| File | Purpose |
|------|---------|
| `IntegerMath.sol` | Checked vs unchecked arithmetic, truncating casts |
| `UnsafeCounter.sol` | Pre-0.8 overflow simulation (pragma 0.7.6) |
| `../../test/01-integer-overflow/IntegerMath.t.sol` | Foundry tests |

---

## How to Run This Lab

> Requires Foundry. If you haven't installed it yet, see the [root README](../../README.md#how-to-run-the-labs).

### 1. Run all tests for this lab

```bash
# From repo root
forge test --match-path "test/01-integer-overflow/*" -v
```

Expected output:
```
[PASS] test_checkedAdd_revertsOnOverflow()
[PASS] test_checkedSub_revertsOnUnderflow()
[PASS] test_truncatingCast_silentlyDiscardsBits()
[PASS] test_uncheckedAdd_wrapsToZeroOnOverflow()
[PASS] test_uncheckedMul_wrapsOnLargeInputs()
[PASS] test_uncheckedSub_wrapsToMaxOnUnderflow()
[PASS] test_safeUncheckedLoop_correctSumForBoundedArray()
```

### 2. Run with verbose trace (see revert reasons)

```bash
forge test --match-path "test/01-integer-overflow/*" -vvv
```

### 3. Run a single test

```bash
forge test --match-test "test_uncheckedMul_wrapsOnLargeInputs" -vvv
```

### 4. Gas report for this lab

```bash
forge test --match-path "test/01-integer-overflow/*" --gas-report
```

Look for the delta between `checkedAdd` and `uncheckedAdd` — this is the ~3 gas cost of the overflow check.

### 5. Check test coverage

```bash
forge coverage --match-path "test/01-integer-overflow/*"
```

### ⚠️ Note on UnsafeCounter.sol

`UnsafeCounter.sol` uses `pragma solidity ^0.7.6` intentionally. Foundry handles multi-version compilation automatically via `foundry.toml`. You do **not** need to change the compiler setting — it will compile both contracts correctly.

To verify the overflow behavior directly, you can inspect the contract in isolation:

```bash
forge build --contracts labs/01-integer-overflow/UnsafeCounter.sol
```

---

## Key Takeaways

- `unchecked` is not "optimized" — it is "unguarded." Treat it like inline assembly.
- Type truncation (`uint256 → uint8`) is silent data loss, not a revert.
- Auditors must trace every path through `unchecked` and verify the invariant holds algebraically.
- "This value can never be that large" is not a proof. It is an assumption.

---

## Audit Checklist

- [ ] Every `unchecked` block has a written invariant proof in comments
- [ ] Every explicit downcast has a bounds check before the cast
- [ ] Any `pragma ^0.7.x` contract: full arithmetic audit required
- [ ] Loop bodies accumulating totals: verify no per-iteration overflow possible
