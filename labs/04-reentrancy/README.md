# Lab 04 — Reentrancy

> The DAO lost $60M in 2016. The same bug pattern ships in production code today.

This repository is part of my **'Solidity Core Labs'** series — a deep dive into EVM behavior, smart contract design, and real-world pitfalls. Focused on building audit-level thinking, not just writing code.

---

## Concept

When a Solidity contract sends ETH via `call()`, execution leaves the contract and enters the recipient's `receive()` or `fallback()` function. If that recipient is a malicious contract, it can **call back** into the original contract before the original function has finished executing.

If the original contract updates its state **after** the external call, the attacker re-enters with stale state — the balance hasn't been zeroed yet, so the check passes again. This repeats until the vault is empty.

```
VulnerableVault.withdraw()
    → msg.sender.call{value}("")       ← EVM hands control to attacker
        → Attacker.receive()
            → VulnerableVault.withdraw()   ← reentry: balance still non-zero
                → msg.sender.call{value}("")
                    → Attacker.receive()
                        → VulnerableVault.withdraw()   ← repeats...
```

---

## What This Lab Proves

1. A contract sending ETH **before** updating state is exploitable — every time
2. The attacker's `receive()` hook is the reentry vector — any external call can trigger it
3. **CEI (Checks-Effects-Interactions)** blocks the attack by zeroing state before sending
4. A **reentrancy guard (mutex)** blocks it at the call level — reentry reverts immediately
5. Both defenses are independently sufficient; together they provide defense-in-depth
6. The attack is live and provable — this lab runs the actual exploit in tests

---

## The CEI Pattern

```solidity
function withdraw(uint256 amount) external {
    // 1. CHECKS — validate inputs
    require(balances[msg.sender] >= amount, "insufficient");

    // 2. EFFECTS — update state FIRST
    balances[msg.sender] -= amount;

    // 3. INTERACTIONS — external call LAST
    (bool ok,) = msg.sender.call{value: amount}("");
    require(ok, "failed");
}
```

On reentry: `balances[msg.sender]` is already 0. The `require` fails. Attack blocked.

---

## Why This Matters in Production

- **Any function that sends ETH or calls an external contract** is a reentrancy candidate
- **Cross-function reentrancy** — two functions share state; attacker reenters the *other* function
- **Read-only reentrancy** — attacker reenters a `view` function to read stale state (used in oracle manipulation)
- **Cross-contract reentrancy** — Protocol A calls Protocol B; Protocol B reenters Protocol A
- Gas optimizations that reorder operations can inadvertently break CEI

---

## Real-World Loss Scenarios

| Incident | Mechanism | Loss |
|----------|-----------|------|
| The DAO (2016) | Classic single-function reentrancy via `withdrawBalance()` | $60M (~3.6M ETH) |
| Cream Finance (2021) | Cross-contract reentrancy via ERC777 token callback | $18.8M |
| Fei Protocol (2022) | Reentrancy in `exitPool()` — ETH sent before balances updated | $80M |
| Orion Protocol (2023) | Single-function reentrancy in `depositAsset()` | $3M |

---

## Key Takeaways

- **CEI is non-negotiable.** State updates must precede external calls. Always.
- `transfer()` and `send()` have a 2,300 gas stipend that prevents reentry — but they're deprecated. `call()` has no such limit.
- A reentrancy guard adds defense-in-depth but does not replace CEI. Use both.
- Cross-function and cross-contract reentrancy require guards — CEI alone is insufficient when two functions share mutable state and both make external calls.
- If you see `msg.sender.call{value}("")` before a state update in any codebase — that's a critical finding.

---

## Files

| File | Purpose |
|------|---------|
| `VulnerableVault.sol` | ETH vault with Interaction-before-Effect bug |
| `SecureVault.sol` | ETH vault with CEI + nonReentrant guard |
| `Attacker.sol` | Exploit contract + failed attack against secure vault |
| `../../test/04-reentrancy/Reentrancy.t.sol` | Live exploit + defense tests |

---

## How to Run This Lab

> Requires Foundry. See [root README](../../README.md#how-to-run-the-labs) for setup.

### 1. Run all tests

```bash
forge test --match-path "test/04-reentrancy/*" -v
```

Expected output:
```
[PASS] test_vulnerableVault_normalDepositWithdraw()
[PASS] test_vulnerableVault_revertsOnInsufficientBalance()
[PASS] test_attack_drainsVulnerableVault()
[PASS] test_attack_victimLosesFunds()
[PASS] test_secureVault_normalDepositWithdraw()
[PASS] test_attack_failsAgainstSecureVault()
[PASS] test_secureVault_balanceZeroedBeforeTransfer()
```

### 2. See the full attack trace

```bash
forge test --match-test "test_attack_drainsVulnerableVault" -vvvv
```

The `-vvvv` trace shows every reentrant call depth — you can see the attacker re-entering the vault repeatedly before the balance is zeroed.

### 3. See the failed attack trace

```bash
forge test --match-test "test_attack_failsAgainstSecureVault" -vvvv
```

Watch the reentry hit the guard and revert.

### 4. Gas report

```bash
forge test --match-path "test/04-reentrancy/*" --gas-report
```

Note the overhead of `nonReentrant` on `SecureVault.withdraw` vs `VulnerableVault.withdraw` — two SSTOREs for the lock (~5,000 gas). That's the cost of defense.

---

## Audit Checklist

- [ ] Every function sending ETH follows CEI — state updated before `call()`
- [ ] Every external call (not just ETH) is evaluated for reentry risk
- [ ] Functions sharing mutable state with external calls have reentrancy guards
- [ ] No `balances[user] -= amount` appearing AFTER `user.call{value}()`
- [ ] ERC777/ERC1155 token hooks evaluated as reentry vectors (not just ETH sends)
- [ ] Cross-contract interactions audited for shared state reentrancy
