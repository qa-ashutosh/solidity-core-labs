// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title DataLocations
 * @notice Demonstrates the three data locations in Solidity: calldata, memory, storage.
 *
 * @dev There are exactly three places data can live in the EVM:
 *
 *      STORAGE  — persistent, on-chain, expensive (SLOAD ~2100 gas cold, SSTORE ~22100 gas cold)
 *      MEMORY   — temporary, per-call scratch space, cheap but wiped after call ends
 *      CALLDATA — read-only input data sent with a transaction, cheapest to read
 *
 *      The keyword you choose in a function signature is NOT cosmetic.
 *      It determines WHERE the data lives, WHETHER it can be modified,
 *      and HOW MUCH GAS the function costs.
 *
 * AUDIT TARGET:
 *      - `memory` on large arrays in loops = quadratic gas (memory expansion)
 *      - Missing `calldata` on external function params = unnecessary copy cost
 *      - Storage pointer vs memory copy = different mutation semantics entirely
 */
contract DataLocations {
    struct UserProfile {
        address wallet;
        uint256 balance;
        string username;
    }

    UserProfile[] public profiles;
    mapping(address => uint256) public profileIndex;

    // ── calldata vs memory on arrays ─────────────────────────────────────

    /// @notice Sums an array using calldata — data is read directly from the call.
    /// @dev calldata: no copy made, read-only, cheapest path for external functions.
    ///      Use this when you only need to read the input.
    function sumCalldata(
        uint256[] calldata values
    ) external pure returns (uint256 total) {
        for (uint256 i = 0; i < values.length; ) {
            total += values[i];
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Sums an array using memory — data is copied from calldata into memory first.
    /// @dev memory: a full copy is made on entry. Costs more gas than calldata for reads.
    ///      Only use memory when you need to MODIFY the array inside the function.
    ///      Using memory here for a read-only sum is a gas anti-pattern.
    function sumMemory(
        uint256[] memory values
    ) external pure returns (uint256 total) {
        for (uint256 i = 0; i < values.length; ) {
            total += values[i];
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Demonstrates that calldata arrays cannot be modified.
    /// @dev This function takes memory so it CAN mutate. If param were calldata,
    ///      the assignment `values[0] = 0` would not compile — calldata is read-only.
    ///      This is the ONLY valid reason to prefer memory over calldata for arrays.
    function zeroFirstElement(
        uint256[] memory values
    ) external pure returns (uint256[] memory) {
        values[0] = 0; // valid: memory is mutable
        return values;
    }

    // ── storage pointer vs memory copy ───────────────────────────────────

    /// @notice Adds a new profile to storage.
    function addProfile(
        address wallet,
        uint256 balance,
        string calldata username
    ) external {
        profileIndex[wallet] = profiles.length;
        profiles.push(
            UserProfile({wallet: wallet, balance: balance, username: username})
        );
    }

    /// @notice Updates balance via a STORAGE POINTER — modifies state directly.
    /// @dev `storage` keyword makes `profile` a reference, not a copy.
    ///      Writing to `profile.balance` writes directly to the storage slot.
    ///      No extra SSTORE needed — it IS the storage slot.
    function updateBalanceViaStoragePointer(
        address wallet,
        uint256 newBalance
    ) external {
        UserProfile storage profile = profiles[profileIndex[wallet]]; // pointer, not copy
        profile.balance = newBalance; // directly writes to storage — one SSTORE
    }

    /// @notice Updates balance via a MEMORY COPY — silent no-op for state.
    /// @dev `memory` keyword makes `profile` a full copy of the struct.
    ///      Writing to `profile.balance` modifies the LOCAL copy only.
    ///      The storage slot is NEVER updated. This looks correct but does nothing.
    ///      
    //       COMPILER WARNING (intentional): Solidity warns this function "can be restricted
    ///      to view" — because it detects zero storage writes. That warning IS the bug.
    ///      Do NOT add `view` here. A real vulnerable contract wouldn't have it either.
    ///
    ///      AUDIT FLAG: this is one of the most common "looks right, is wrong" bugs.
    ///      Devs coming from other languages expect struct assignment to work by reference.
    ///      In Solidity, `memory` = copy. Your writes vanish at the end of the call.
    function updateBalanceViaMemoryCopy(
        address wallet,
        uint256 newBalance
    ) external {
        UserProfile memory profile = profiles[profileIndex[wallet]]; // COPY, not pointer
        profile.balance = newBalance; // modifies local copy only — storage unchanged
        // storage is never written — this function is a silent no-op
    }

    /// @notice Returns a profile — uses memory because return values must be memory or value types.
    function getProfile(
        address wallet
    ) external view returns (UserProfile memory) {
        return profiles[profileIndex[wallet]];
    }

    // ── string and bytes calldata ─────────────────────────────────────────

    /// @notice Concatenates two strings — must use memory because abi.encodePacked returns memory.
    /// @dev Input strings are calldata (read-only), but the output is a new memory allocation.
    ///      This demonstrates that calldata inputs can feed memory outputs without copying input.
    function concatStrings(
        string calldata a,
        string calldata b
    ) external pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    /// @notice Returns the byte length of a calldata string without copying it.
    /// @dev bytes(str).length on a calldata string reads the length directly.
    ///      No memory allocation — pure calldata read.
    function stringLength(string calldata str) external pure returns (uint256) {
        return bytes(str).length;
    }
}
