// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title StorageLayout
 * @notice Demonstrates how Solidity assigns storage slots and packs variables.
 *
 * @dev CORE RULE: Every state variable occupies a 32-byte slot (slot 0, 1, 2...).
 *      Solidity packs multiple small variables into one slot IF they fit together
 *      AND are declared consecutively. Order of declaration controls packing.
 *
 *      Verified slot map (traced manually and confirmed via forge inspect):
 *
 *      Slot 0: fullSlot (uint256, 32 bytes — full slot)
 *      Slot 1: packedA(1) + packedB(2) + packedC(4) = 7 bytes, 25 remaining
 *      Slot 2: breakerA (uint256, 32 bytes — full slot, forces split)
 *      Slot 3: wastedX(1) only — breakerA pushed it to new slot
 *      Slot 4: breakerB (uint256, 32 bytes — full slot, forces split)
 *      Slot 5: wastedY(1) only — breakerB pushed it to new slot
 *      Slot 6: fixedBytes (bytes32, 32 bytes — full slot)
 *      Slot 7: balances mapping (marker only; data at keccak256(key ++ 7))
 *      Slot 8: dynamicArray (length only; data at keccak256(8) + index)
 *
 * AUDIT TARGET: Storage layout is the foundation of every proxy pattern.
 */
contract StorageLayout {

    // ── Slot 0 ───────────────────────────────────────────────────────────
    uint256 public fullSlot;                          // slot 0 (32 bytes, always full)

    // ── Slot 1 ───────────────────────────────────────────────────────────
    // Three small types pack together: 1 + 2 + 4 = 7 bytes, fits in one slot.
    uint8  public packedA;                            // slot 1, offset 0
    uint16 public packedB;                            // slot 1, offset 1
    uint32 public packedC;                            // slot 1, offset 3
    // 25 bytes remain unused in slot 1

    // ── Slot 2 ───────────────────────────────────────────────────────────
    // uint256 never packs — always starts a new slot.
    uint256 public breakerA;                          // slot 2 (32 bytes, full)

    // ── Slot 3 ───────────────────────────────────────────────────────────
    // wastedX cannot pack back with packedA/B/C — breakerA sits between them.
    // Same type as packedA/B/C, but isolated = separate SLOAD every time.
    uint8 public wastedX;                             // slot 3, offset 0 (31 bytes wasted)

    // ── Slot 4 ───────────────────────────────────────────────────────────
    uint256 public breakerB;                          // slot 4 (32 bytes, full)

    // ── Slot 5 ───────────────────────────────────────────────────────────
    uint8 public wastedY;                             // slot 5, offset 0 (31 bytes wasted)

    // ── Slot 6 ───────────────────────────────────────────────────────────
    bytes32 public fixedBytes;                        // slot 6 (32 bytes, always full)

    // ── Slot 7 ───────────────────────────────────────────────────────────
    // Mapping: slot 7 holds a marker. Actual value for key k lives at:
    //   keccak256(abi.encode(k, 7))
    mapping(address => uint256) public balances;      // slot 7 (marker only)

    // ── Slot 8 ───────────────────────────────────────────────────────────
    // Dynamic array: slot 8 holds the LENGTH. Element at index i lives at:
    //   keccak256(abi.encode(8)) + i
    uint256[] public dynamicArray;                    // slot 8 (length only)

    // ─────────────────────────────────────────────────────────────────────

    /// @notice Populates all variables so tests can verify raw slot contents.
    /// @dev msg.sender is used for the mapping key — caller must be known in tests.
    function populate() external {
        fullSlot   = 0xDEADBEEF;
        packedA    = 0xAA;
        packedB    = 0xBBBB;
        packedC    = 0xCCCCCCCC;
        fixedBytes = bytes32(uint256(0xFF));
        balances[msg.sender] = 1 ether;
        dynamicArray.push(42);
    }

    /// @notice Returns the declared slot of the balances mapping.
    /// @dev Use this to compute storage keys: keccak256(abi.encode(address, slot))
    function balancesSlot() external pure returns (uint256) {
        return 7;
    }
}
