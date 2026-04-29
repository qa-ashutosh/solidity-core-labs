// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title VulnerableVault
 * @notice A simple ETH vault that is vulnerable to reentrancy attack.
 *
 * @dev THE BUG: This contract follows the wrong order of operations:
 *      1. Checks condition (balance >= amount)        ← correct
 *      2. Sends ETH via call()                        ← WRONG: external call before state update
 *      3. Updates balance AFTER the call              ← WRONG: state updated too late
 *
 *      Between steps 2 and 3, the caller's receive() / fallback() runs.
 *      At that moment, balances[msg.sender] is still the original value.
 *      The attacker re-enters withdraw() — the check still passes.
 *      This repeats until the vault is drained.
 *
 *      This is the exact pattern that drained The DAO in 2016 ($60M).
 *      It still appears in production code today.
 *
 * CORRECT ORDER (CEI — Checks, Effects, Interactions):
 *      1. Checks   — validate inputs and conditions
 *      2. Effects  — update all state variables
 *      3. Interactions — make external calls LAST
 *
 * AUDIT FLAG: Any function that sends ETH or makes an external call
 *             BEFORE updating state is a reentrancy candidate.
 */
contract VulnerableVault {

    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    /// @notice Deposit ETH into the vault.
    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Withdraw ETH from the vault.
    /// @dev VULNERABLE: external call happens before state update.
    ///      An attacker's receive() can re-enter this function before
    ///      balances[msg.sender] is set to zero.
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "insufficient balance"); // 1. Check

        // ⚠️  INTERACTION before EFFECT — this is the vulnerability
        (bool ok,) = msg.sender.call{value: amount}("");                 // 2. Interact
        require(ok, "transfer failed");

        // unchecked: in a real vulnerable contract (pre-0.8 or assembly-heavy),
        // this subtraction would wrap instead of revert — allowing the drain to
        // complete without reverting the tx. We replicate that here.
        unchecked {
            balances[msg.sender] -= amount;                              // 3. Effect (too late)
        }
        emit Withdrawal(msg.sender, amount);
    }

    /// @notice Returns vault's total ETH balance.
    function totalBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
