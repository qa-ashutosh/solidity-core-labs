# Lab 03 — Calldata vs Memory vs Storage

> Data location is not a hint to the compiler. It is a contract with the EVM.

This repository is part of my **'Solidity Core Labs'** series — a deep dive into EVM behavior, smart contract design, and real-world pitfalls. Focused on building audit-level thinking, not just writing code.

---

## Concept

Every piece of data in Solidity exists in one of three locations:

| Location | Persists? | Mutable? | Cost |
|----------|-----------|----------|------|
| `storage` | ✅ Forever | ✅ Yes | ~2,100 gas read / ~22,100 gas write (cold) |
| `memory` | ❌ Call only | ✅ Yes | Low, but grows quadratically with size |
| `calldata` | ❌ Call only | ❌ Read-only | Cheapest — no copy made |

The keyword you put in a function signature determines which location is used. It is not optional style — it changes gas cost, mutability, and whether your writes actually persist.

---

## What This Lab Proves

1. `calldata` and `memory` produce identical results for reads — the difference is **only gas**
2. `memory` params cost more than `calldata` for external functions because a full copy is made on entry
3. A `storage` pointer mutates state directly — one SSTORE, change persists
4. A `memory` copy of a struct is a **silent no-op** — writes vanish at the end of the call
5. Memory expansion cost is **non-linear** — allocating a 100-element array costs more than 10× a 10-element array
6. Allocating memory inside a loop compounds expansion cost and should never appear in production

---

## Why This Matters in Production

- **The ghost write bug** — `UserProfile memory profile = profiles[i]; profile.balance = x;` looks like a state update. It is not. Zero revert, zero event, protocol state silently wrong.
- **Gas griefing** — any function that allocates `new uint256[](n)` where `n` is user-supplied can be fed large inputs to drive gas cost to block limit, DoS-ing the function.
- **View function cost** — returning large arrays from on-chain `view` calls (e.g. aggregator contracts) incurs memory expansion paid by the caller. Design matters.
- **calldata on internal vs external** — `calldata` is only valid for `external` functions. `internal` and `public` functions that call each other use `memory`. Misusing `calldata` in `public` functions causes implicit copies.

---

## Real-World Loss Scenarios

| Scenario | Mechanism | Impact |
|----------|-----------|--------|
| Ghost write in balance update | `memory` struct copy instead of `storage` pointer — balance "update" silently discarded | Incorrect accounting, potential insolvency |
| Memory griefing in aggregator | User supplies large array to a function allocating `new T[](n)` | Gas cost hits block limit, function becomes unusable |
| Unbounded return array | Protocol returns all positions via `Position[] memory` — grows with protocol usage | Eventually reverts on-chain callers due to OOG |

---

## Key Takeaways

- Default to `calldata` for all external function array/struct/string params. Use `memory` only when you need to mutate.
- `UserProfile memory p = profiles[i]` is a copy. `UserProfile storage p = profiles[i]` is a pointer. One letter changes everything.
- Memory expansion is quadratic. Never allocate inside a loop. Never let user input control allocation size.
- A function that writes to a `memory` struct and returns successfully has done nothing to state. Auditors look for this specifically.

---

## Files

| File | Purpose |
|------|---------|
| `DataLocations.sol` | calldata vs memory params, storage pointer vs memory copy |
| `MemoryExpansion.sol` | Non-linear memory cost, allocation in loops, no-alloc alternative |
| `../../test/03-calldata-vs-memory/DataLocations.t.sol` | Foundry tests |

---

## How to Run This Lab

> Requires Foundry. See [root README](../../README.md#how-to-run-the-labs) for setup.

### 1. Run all tests

```bash
forge test --match-path "test/03-calldata-vs-memory/*" -v
```

Expected output:
```
[PASS] test_sumCalldata_matchesSumMemory_sameResult()
[PASS] test_zeroFirstElement_mutatesMemoryArray()
[PASS] test_storagePointer_persistsMutation()
[PASS] test_memoryCopy_silentlyDiscardsUpdate()
[PASS] test_storageVsMemory_divergeOnSameInput()
[PASS] test_concatStrings_returnsCorrectResult()
[PASS] test_stringLength_correctForAsciiAndEmpty()
[PASS] test_memoryAllocation_correctSumRegardlessOfSize()
[PASS] test_sumWithoutAllocation_matchesAllocatedVersion()
[PASS] test_memoryInLoop_correctButExpensive()
```

### 2. Run the gas report — this is the main event for this lab

```bash
forge test --match-path "test/03-calldata-vs-memory/*" --gas-report
```

**What to look for:**

| Function pair | Expected result |
|---------------|----------------|
| `sumCalldata` vs `sumMemory` | `sumCalldata` cheaper — no copy overhead |
| `sumLargeArray(100)` vs `sumWithoutAllocation(100)` | Same output, `sumWithoutAllocation` significantly cheaper |
| `memoryAllocationInLoop(50)` vs `sumWithoutAllocation(50)` | Same output, loop version dramatically more expensive |

### 3. Run a single test with full trace

```bash
forge test --match-test "test_memoryCopy_silentlyDiscardsUpdate" -vvv
```

### 4. Coverage

```bash
forge coverage --match-path "test/03-calldata-vs-memory/*"
```

---

## Audit Checklist

- [ ] All external function array/string/struct params use `calldata` unless mutation is required
- [ ] Every `memory` struct assignment from storage is checked — is this a pointer or a copy?
- [ ] No `new T[](n)` where `n` is user-controlled or unbounded
- [ ] No memory allocation inside loops
- [ ] Functions returning large arrays are not called on-chain (view-only, off-chain consumers)
