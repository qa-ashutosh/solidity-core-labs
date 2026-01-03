// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title ValueTypesEdgeCases
/// @notice Edge cases and pitfalls with Solidity value types
contract ValueTypesEdgeCases {
    /// @notice Truncation occurs when casting to smaller uint
    function truncateUint(uint256 bigNumber) external pure returns (uint8) {
        return uint8(bigNumber);
    }

    /// @notice uint8 overflow wraps silently inside unchecked
    function smallUintOverflow(uint8 x) external pure returns (uint8) {
        unchecked {
            return x + 1;
        }
    }

    /// @notice Address to uint160 cast (used internally by Solidity)
    function addressToUint(address addr) external pure returns (uint160) {
        return uint160(addr);
    }

    /// @notice uint160 back to address
    function uintToAddress(uint160 value) external pure returns (address) {
        return address(value);
    }

    /// @notice bytes vs bytes32 comparison
    function bytesComparison(bytes32 a, bytes32 b) external pure returns (bool) {
        return a == b;
    }

    /// @notice Boolean default can be dangerous in conditionals
    function defaultBoolLogic(bool input) external pure returns (bool) {
        bool local;
        return input && local; // always false unless both true
    }
}
