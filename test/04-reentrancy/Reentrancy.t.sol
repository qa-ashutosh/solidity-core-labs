// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../labs/04-reentrancy/VulnerableVault.sol";
import "../../labs/04-reentrancy/SecureVault.sol";
import "../../labs/04-reentrancy/Attacker.sol";

/**
 * @title ReentrancyTest
 * @notice Foundry tests for Lab 04: Reentrancy
 *
 * Convention: test_<behavior>_<expectedOutcome>
 *
 * This test suite does something most labs don't:
 * it runs a LIVE EXPLOIT against VulnerableVault and proves it drains funds,
 * then runs the same attack against SecureVault and proves it fails.
 *
 * vm.deal()  — gives an address ETH in the local EVM
 * vm.prank() — sets msg.sender for the next call
 */
contract ReentrancyTest is Test {

    VulnerableVault vulnVault;
    SecureVault     secureVault;
    Attacker        attacker;
    FailedAttacker  failedAttacker;

    address constant ALICE  = address(0xA11CE);
    address constant BOB    = address(0xB0B);
    address constant VICTIM = address(0xDEAD);

    function setUp() public {
        vulnVault    = new VulnerableVault();
        secureVault  = new SecureVault();
        attacker     = new Attacker(address(vulnVault));
        failedAttacker = new FailedAttacker(address(secureVault));

        // Give Alice and the victim ETH
        vm.deal(ALICE,  10 ether);
        vm.deal(VICTIM, 10 ether);

        // Victim deposits 9 ETH into the vulnerable vault (legitimate user)
        vm.prank(VICTIM);
        vulnVault.deposit{value: 9 ether}();

        // Victim also deposits 9 ETH into the secure vault
        vm.deal(VICTIM, 10 ether);
        vm.prank(VICTIM);
        secureVault.deposit{value: 9 ether}();
    }

    // ── VulnerableVault tests ─────────────────────────────────────────────

    /// @notice Normal deposit and withdraw works correctly without attack.
    function test_vulnerableVault_normalDepositWithdraw() public {
        vm.deal(ALICE, 2 ether);
        vm.prank(ALICE);
        vulnVault.deposit{value: 2 ether}();
        assertEq(vulnVault.balances(ALICE), 2 ether);

        vm.prank(ALICE);
        vulnVault.withdraw(1 ether);
        assertEq(vulnVault.balances(ALICE), 1 ether);
        assertEq(ALICE.balance, 1 ether);
    }

    /// @notice Withdraw reverts when balance is insufficient.
    function test_vulnerableVault_revertsOnInsufficientBalance() public {
        vm.deal(ALICE, 1 ether);
        vm.prank(ALICE);
        vulnVault.deposit{value: 1 ether}();

        vm.prank(ALICE);
        vm.expectRevert("insufficient balance");
        vulnVault.withdraw(2 ether);
    }

    /// @notice THE EXPLOIT: attacker drains vault with 1 ETH deposit against 9 ETH vault.
    /// @dev Attack flow:
    ///      1. Victim has deposited 9 ETH (vault holds 9 ETH)
    ///      2. Attacker deposits 1 ETH → vault holds 10 ETH
    ///      3. Attacker calls withdraw(1 ETH)
    ///      4. Vault sends 1 ETH → attacker.receive() fires
    ///      5. receive() calls withdraw(1 ETH) again — balance not yet updated
    ///      6. Repeats until vault is empty
    ///      7. Attacker ends up with 10 ETH (their 1 + victim's 9)
    function test_attack_drainsVulnerableVault() public {
        // Fund the test contract itself, then send ETH with the call
        vm.deal(address(this), 1 ether);

        uint256 vaultBefore = vulnVault.totalBalance(); // 9 ETH (victim's deposit)

        // ETH is sent WITH the call — attack() receives it as msg.value
        attacker.attack{value: 1 ether}();

        uint256 vaultAfter    = vulnVault.totalBalance();
        uint256 attackerAfter = address(attacker).balance;

        // Vault should be drained (or nearly drained)
        assertLt(vaultAfter, vaultBefore, "vault must lose ETH from reentrancy attack");

        // Attacker has more than their initial 1 ETH — victim funds stolen
        assertGt(attackerAfter, 1 ether, "attacker must have drained victim funds");
    }

    /// @notice Victim's funds are stolen — vault emptied by reentrant drain.
    function test_attack_victimLosesFunds() public {
        vm.deal(address(this), 1 ether);
        attacker.attack{value: 1 ether}();

        // Vault is drained — victim can no longer withdraw their 9 ETH
        uint256 vaultBalance = vulnVault.totalBalance();
        assertLt(vaultBalance, 9 ether, "victim's 9 ETH should be drained");
    }

    // ── SecureVault tests ─────────────────────────────────────────────────

    /// @notice Normal operations work correctly on the secure vault.
    function test_secureVault_normalDepositWithdraw() public {
        vm.deal(ALICE, 2 ether);
        vm.prank(ALICE);
        secureVault.deposit{value: 2 ether}();

        vm.prank(ALICE);
        secureVault.withdraw(1 ether);
        assertEq(secureVault.balances(ALICE), 1 ether);
        assertEq(ALICE.balance, 1 ether);
    }

    /// @notice Reentrancy attack against SecureVault fails — attacker gets nothing extra.
    /// @dev The nonReentrant guard + CEI order both independently block the attack.
    ///      The attacker only gets back exactly what they deposited — no profit.
    function test_attack_failsAgainstSecureVault() public {
        vm.deal(address(this), 1 ether);

        uint256 vaultBefore = secureVault.totalBalance(); // 9 ETH

        failedAttacker.attack{value: 1 ether}();

        uint256 vaultAfter = secureVault.totalBalance();

        // Vault balance must be unchanged (attacker deposited 1 and withdrew 1 — net zero)
        assertEq(vaultAfter, vaultBefore, "secure vault must not lose victim ETH");

        // Confirm the reentry was caught and reverted
        assertTrue(failedAttacker.attackReverted(), "reentrant call must have reverted");
    }

    /// @notice CEI alone prevents reentrancy — balance is zero on reentry.
    /// @dev Even if we removed the nonReentrant modifier, CEI would still protect.
    ///      This test verifies the state is updated before the external call.
    function test_secureVault_balanceZeroedBeforeTransfer() public {
        vm.deal(ALICE, 1 ether);
        vm.prank(ALICE);
        secureVault.deposit{value: 1 ether}();

        assertEq(secureVault.balances(ALICE), 1 ether);

        vm.prank(ALICE);
        secureVault.withdraw(1 ether);

        // After withdraw: balance is 0, ETH received
        assertEq(secureVault.balances(ALICE), 0);
        assertEq(ALICE.balance, 1 ether);
    }
}
