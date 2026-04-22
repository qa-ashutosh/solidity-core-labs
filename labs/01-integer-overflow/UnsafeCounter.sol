// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

/**
 * @title UnsafeCounter
 * @notice Simulates a pre-Solidity-0.8 counter WITHOUT overflow protection.
 *
 * @dev WARNING: This contract is intentionally vulnerable.
 *      In Solidity < 0.8.0, ALL arithmetic wraps silently.
 *      SafeMath was the conventional (not enforced) mitigation.
 *      This contract omits SafeMath deliberately — representing real pre-2021 DeFi code.
 *
 * AUDIT NOTE: If you see `pragma solidity ^0.7.x` on a live contract,
 *             every arithmetic operation is a manual audit target.
 */
contract UnsafeCounter {

    uint8 public count; // uint8: max 255 — overflows at 256

    /// @notice Increments the counter. Wraps silently to 0 at 256.
    function increment() external {
        count += 1; // 255 + 1 = 0
    }

    /// @notice Sets count to an explicit value.
    function set(uint8 value) external {
        count = value;
    }

    /// @notice Decrements counter. Wraps to 255 when count == 0.
    function decrement() external {
        count -= 1; // 0 - 1 = 255
    }
}
