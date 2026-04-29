// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title SecureVault
 * @notice ETH vault secured against reentrancy using two independent patterns.
 *
 * @dev Two defenses are demonstrated:
 *
 *      DEFENSE 1 — CEI (Checks-Effects-Interactions) pattern
 *          The state update happens BEFORE the external call.
 *          Even if the attacker re-enters, balances[msg.sender] is already 0.
 *          The require() check fails on reentry. No extra gas. No locks.
 *          This is the preferred pattern — free and composable.
 *
 *      DEFENSE 2 — Reentrancy Guard (mutex lock)
 *          A boolean lock prevents any reentrant call from executing.
 *          Used when CEI alone is insufficient — e.g. cross-function reentrancy
 *          where two different functions share state and both make external calls.
 *
 *      In this contract both are applied together. In production, CEI alone
 *      is sufficient for single-function reentrancy. The guard adds defense-in-depth.
 */
contract SecureVault {

    mapping(address => uint256) public balances;
    bool private _locked; // reentrancy guard state

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    /// @notice Reentrancy guard modifier.
    /// @dev Sets _locked = true for the duration of the call.
    ///      Any reentrant call hits the require and reverts immediately.
    ///      Gas cost: 2 SSTOREs per guarded call (~5,000 gas overhead).
    ///      Note: OpenZeppelin's ReentrancyGuard uses the same pattern
    ///      but with uint256 (1/2) instead of bool to avoid SSTORE cold slot cost.
    modifier nonReentrant() {
        require(!_locked, "reentrant call");
        _locked = true;
        _;
        _locked = false;
    }

    /// @notice Deposit ETH into the vault.
    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Withdraw ETH — secured with CEI + reentrancy guard.
    /// @dev CEI order:
    ///      1. CHECK  — require balance sufficient
    ///      2. EFFECT — zero out balance BEFORE sending
    ///      3. INTERACT — send ETH last
    ///
    ///      Even without the guard, the CEI order alone prevents reentrancy:
    ///      on reentry, balances[msg.sender] is already 0, so require fails.
    function withdraw(uint256 amount) external nonReentrant {
        require(balances[msg.sender] >= amount, "insufficient balance"); // 1. Check

        balances[msg.sender] -= amount;                                  // 2. Effect first
        emit Withdrawal(msg.sender, amount);

        (bool ok,) = msg.sender.call{value: amount}("");                 // 3. Interact last
        require(ok, "transfer failed");
    }

    function totalBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
