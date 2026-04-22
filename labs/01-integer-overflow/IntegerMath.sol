// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IntegerMath
 * @notice Demonstrates the difference between checked (default) and unchecked arithmetic.
 *
 * @dev AUDIT TARGET: Every `unchecked` block in production code requires manual proof
 *      that the arithmetic invariant holds. The compiler no longer helps you here.
 *
 *      Gas note: checked arithmetic costs ~3 extra gas per operation (JUMPI for overflow check).
 *      This is why devs reach for `unchecked` in loops — and sometimes break invariants doing so.
 */
contract IntegerMath {

    /// @notice Adds two uint256 values with default checked arithmetic.
    /// @dev Reverts on overflow. This is Solidity 0.8+ default behavior.
    ///      The EVM itself does NOT enforce this — the compiler emits the check.
    function checkedAdd(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b;
    }

    /// @notice Adds two uint256 values inside an unchecked block.
    /// @dev DANGEROUS: silently wraps on overflow.
    ///      Use ONLY when you can algebraically prove overflow is impossible.
    function uncheckedAdd(uint256 a, uint256 b) external pure returns (uint256) {
        unchecked {
            return a + b; // wraps: max + 1 = 0
        }
    }

    /// @notice Subtracts b from a with default checked arithmetic.
    function checkedSub(uint256 a, uint256 b) external pure returns (uint256) {
        return a - b;
    }

    /// @notice Subtracts b from a without overflow check.
    /// @dev DANGEROUS: 0 - 1 = type(uint256).max — wraps to max value.
    ///      This was the default in Solidity < 0.8.0.
    function uncheckedSub(uint256 a, uint256 b) external pure returns (uint256) {
        unchecked {
            return a - b;
        }
    }

    /// @notice Demonstrates silent truncation when casting uint256 → uint8.
    /// @dev AUDIT FLAG: No revert occurs. High bits are silently discarded.
    ///      256 casts to 0. 257 casts to 1. The caller is never warned.
    function truncatingCast(uint256 value) external pure returns (uint8) {
        return uint8(value);
    }

    /// @notice Multiplies two uint256 values inside unchecked block.
    /// @dev CRITICAL: multiplication overflow is the most dangerous variant.
    ///      result = a * b mod 2^256. The BEC exploit used exactly this pattern.
    function uncheckedMul(uint256 a, uint256 b) external pure returns (uint256) {
        unchecked {
            return a * b;
        }
    }

    /// @notice Safe loop pattern using unchecked increment.
    /// @dev This is the ONLY common valid use of unchecked in modern Solidity:
    ///      a loop counter bounded by array length, which is bounded by block gas.
    function sumArray(uint256[] calldata values) external pure returns (uint256 total) {
        for (uint256 i = 0; i < values.length;) {
            total += values[i];
            unchecked { ++i; }
        }
    }
}
