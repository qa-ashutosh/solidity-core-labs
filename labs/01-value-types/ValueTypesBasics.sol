// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title ValueTypesBasics
/// @notice Experiments with Solidity value types and their default behavior
contract ValueTypesBasics {
    uint256 public number;
    bool public flag;
    address public owner;
    bytes32 public data;

    /// @notice Demonstrates default values of value types
    function defaultValues()
        external
        pure
        returns (uint256, bool, address, bytes32)
    {
        uint256 a;
        bool b;
        address c;
        bytes32 d;

        return (a, b, c, d);
    }

    /// @notice Value types are copied, not referenced
    function valueCopy(uint256 input) external pure returns (uint256) {
        uint256 localCopy = input;
        localCopy += 1;

        return input; // unchanged
    }

    /// @notice Demonstrates overflow protection in Solidity >=0.8
    function safeOverflow(uint256 x) external pure returns (uint256) {
        return x + 1; // reverts on overflow
    }

    /// @notice Explicit unchecked overflow
    function uncheckedOverflow(uint256 x) external pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }

    /// @notice Address comparison is value-based
    function isZeroAddress(address addr) external pure returns (bool) {
        return addr == address(0);
    }
}
