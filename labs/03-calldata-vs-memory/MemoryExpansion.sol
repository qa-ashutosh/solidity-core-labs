// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title MemoryExpansion
 * @notice Demonstrates how memory allocation costs grow non-linearly (quadratic).
 *
 * @dev The EVM charges for memory expansion using this formula:
 *
 *      cost = (words * 3) + (words^2 / 512)
 *
 *      Where `words` = number of 32-byte chunks used.
 *
 *      The quadratic term (words^2 / 512) is small for small arrays
 *      but grows aggressively at scale. A function allocating a 10,000-element
 *      array in memory costs dramatically more than 100x a 100-element array.
 *
 *      This matters when:
 *      - Building large in-memory arrays inside loops
 *      - Returning large datasets from view functions called on-chain
 *      - Any function that allocates memory proportional to user input
 *
 * AUDIT TARGET:
 *      - `new uint256[](n)` where n is user-controlled = gas griefing vector
 *      - Returning dynamic arrays from on-chain calls = unbounded memory cost
 *      - Any memory allocation inside a loop = O(n²) memory expansion
 */
contract MemoryExpansion {

    /// @notice Allocates a fixed small array in memory and sums it.
    /// @dev Baseline reference: known small allocation, predictable gas.
    function sumSmallArray(uint256 size) external pure returns (uint256 total) {
        require(size <= 10, "use sumLargeArray for bigger sizes");
        uint256[] memory arr = new uint256[](size);
        for (uint256 i = 0; i < size;) {
            arr[i] = i + 1;
            unchecked { ++i; }
        }
        for (uint256 i = 0; i < size;) {
            total += arr[i];
            unchecked { ++i; }
        }
    }

    /// @notice Allocates a larger array — demonstrates gas growth vs sumSmallArray.
    /// @dev Compare gas cost of sumLargeArray(100) vs sumSmallArray(10) in the gas report.
    ///      The ratio will be > 10x despite only being 10x more elements,
    ///      because memory expansion cost is non-linear.
    function sumLargeArray(uint256 size) external pure returns (uint256 total) {
        require(size <= 1000, "capped to prevent OOG in tests");
        uint256[] memory arr = new uint256[](size);
        for (uint256 i = 0; i < size;) {
            arr[i] = i + 1;
            unchecked { ++i; }
        }
        for (uint256 i = 0; i < size;) {
            total += arr[i];
            unchecked { ++i; }
        }
    }

    /// @notice Same computation as sumLargeArray but WITHOUT memory allocation.
    /// @dev Uses a running accumulator instead of building an array.
    ///      Same result, dramatically lower gas — no memory expansion at all.
    ///      This is the pattern you should use when the array is only needed for summing.
    function sumWithoutAllocation(uint256 size) external pure returns (uint256 total) {
        require(size <= 1000, "capped");
        for (uint256 i = 1; i <= size;) {
            total += i;
            unchecked { ++i; }
        }
    }

    /// @notice Builds a new memory array inside a loop — the worst pattern.
    /// @dev Each iteration re-allocates memory. Memory is never freed in the EVM
    ///      (no garbage collection). Each `new uint256[](i)` call pushes the memory
    ///      pointer forward — memory from previous iterations is abandoned but
    ///      still counts toward total memory usage for expansion cost calculation.
    ///
    ///      AUDIT FLAG: this pattern appears in poorly written aggregation functions.
    ///      With n=50, gas cost explodes compared to a single pre-allocated array.
    function memoryAllocationInLoop(uint256 n) external pure returns (uint256 total) {
        require(n <= 50, "capped to prevent OOG");
        for (uint256 i = 1; i <= n;) {
            uint256[] memory temp = new uint256[](i); // re-allocates every iteration
            temp[i - 1] = i;
            total += temp[i - 1];
            unchecked { ++i; }
        }
    }
}
