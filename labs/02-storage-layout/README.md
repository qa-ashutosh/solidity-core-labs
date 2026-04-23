# Lab 02 — Storage Layout & Slot Collision

> Storage is a 2^256 key-value store. Slot assignment is deterministic. Collision is catastrophic.

This repository is part of my **'Solidity Core Labs'** series — a deep dive into EVM behavior, smart contract design, and real-world pitfalls. Focused on building audit-level thinking, not just writing code.

---

## Concept

Every state variable in a Solidity contract occupies a **storage slot** — a 32-byte bucket identified by a number (slot 0, 1, 2...). The EVM's storage model is a mapping: `slot number → 32 bytes of data`.

Rules Solidity follows when assigning slots:

1. Variables are assigned slots in **declaration order**, starting at slot 0
2. If multiple small variables fit in 32 bytes together, Solidity **packs** them into one slot
3. `uint256`, `bytes32`, and any type ≥ 32 bytes always occupy a **full slot alone**
4. Dynamic types (`mapping`, `[]`) store a marker in their declared slot; actual data lives at `keccak256(slot || key)`
5. **Declaration order controls packing** — inserting a `uint256` between two `uint8`s wastes two slots

---

## What This Lab Proves

1. Slot assignment is deterministic — readable directly with `vm.load` in tests
2. Packing saves gas — two `uint8`s in one slot = one SLOAD instead of two
3. Poor declaration order wastes slots and increases gas permanently
4. `delegatecall` uses the **caller's storage** with the **callee's code** — slot layout must match exactly
5. Slot 0 collision via `delegatecall` corrupts the proxy's implementation pointer — game over

---

## Why This Matters in Production

- **Every proxy pattern** (Transparent, UUPS, Beacon) depends on storage layout alignment between proxy and implementation
- **Upgrade bugs** — adding a variable before existing ones in an implementation shifts every subsequent slot, corrupting all stored data
- **Gas cost** — a poorly ordered struct can double the SLOAD count for a hot function
- **EIP-1967** exists entirely because naive proxies stored `implementation` at slot 0, which collided with implementation contracts

---

## Real-World Loss Scenarios

| Incident | Mechanism | Loss |
|----------|-----------|------|
| Audius (2022) | Storage layout mismatch in governance proxy upgrade — attacker manipulated slot collision to pass malicious proposal | $6M |
| Harvest Finance (2020) | Proxy upgrade introduced slot shift — incorrect variable reads post-upgrade | ~$34M (broader attack, layout was a factor) |
| Generic UUPS pattern risk | Uninitialized implementation contract — attacker calls `initialize()` directly, takes ownership via slot 0 write | Systemic |

---

## Key Takeaways

- Storage layout is a **contract interface**. Breaking it in an upgrade is as dangerous as changing a function signature mid-use.
- `delegatecall` does NOT isolate storage — it borrows storage from the caller.
- Always verify proxy and implementation share identical slot layout from slot 0.
- EIP-1967 solved the collision problem by using `keccak256`-derived slots for proxy internals — far from slot 0.
- Adding new variables in upgrades must **only append** — never insert or reorder.

---

## Files

| File | Purpose |
|------|---------|
| `StorageLayout.sol` | Slot packing, declaration order, dynamic type slots |
| `StorageCollision.sol` | Proxy + vulnerable logic (slot 0 collision) + safe logic (gap pattern) |
| `../../test/02-storage-layout/StorageLayout.t.sol` | Foundry tests |

---

## How to Run This Lab

> Requires Foundry. See [root README](../../README.md#how-to-run-the-labs) for setup.

### 1. Run all tests for this lab

```bash
forge test --match-path "test/02-storage-layout/*" -v
```

Expected output:
```
[PASS] test_fullSlot_occupiesSlotZero()
[PASS] test_packedVariables_shareOneSlot()
[PASS] test_wastedLayout_usesExtraSlots()
[PASS] test_dynamicArray_lengthInDeclaredSlot()
[PASS] test_mappingValue_atKeccakDerivedSlot()
[PASS] test_collision_vulnerableLogicCorruptsImplementationPointer()
[PASS] test_safeLogic_doesNotCorruptProxySlots()
```

### 2. Run with full trace

```bash
forge test --match-path "test/02-storage-layout/*" -vvv
```

### 3. Run a single test

```bash
forge test --match-test "test_collision_vulnerableLogicCorruptsImplementationPointer" -vvv
```

### 4. Gas report

```bash
forge test --match-path "test/02-storage-layout/*" --gas-report
```

Compare `populate()` gas vs equivalent function with wasted layout — the slot packing difference is visible here.

---

## Audit Checklist

- [ ] Proxy and implementation have identical slot layout from slot 0
- [ ] No new variables inserted before existing ones in upgrades (append-only)
- [ ] Implementation contract cannot be initialized directly by an attacker
- [ ] Proxy internals (implementation pointer, admin) use EIP-1967 slots, not sequential slots
- [ ] All `delegatecall` targets are audited for slot 0–N collision
