// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../labs/03-calldata-vs-memory/DataLocations.sol";
import "../../labs/03-calldata-vs-memory/MemoryExpansion.sol";

/**
 * @title DataLocationsTest
 * @notice Foundry tests for Lab 03: Calldata vs Memory vs Storage
 *
 * Convention: test_<behavior>_<expectedOutcome>
 *
 * Key insight this test suite proves:
 *  - calldata and memory produce identical results for reads
 *  - memory copy silently discards struct mutations (the "ghost write" bug)
 *  - storage pointer mutations persist correctly
 *  - memory allocation in loops is measurably more expensive
 *
 * Gas comparisons are validated via Foundry's gas metering (visible in --gas-report).
 * The correctness tests prove the semantic difference; the gas report proves the cost.
 */
contract DataLocationsTest is Test {

    DataLocations  dataLoc;
    MemoryExpansion memExp;

    function setUp() public {
        dataLoc = new DataLocations();
        memExp  = new MemoryExpansion();

        // Seed one profile for storage pointer tests
        dataLoc.addProfile(address(0xA11CE), 1000, "alice");
    }

    // ── calldata vs memory correctness ───────────────────────────────────

    /// @notice calldata and memory produce identical sums — results are the same.
    /// @dev The difference is purely gas. Run --gas-report to see it.
    function test_sumCalldata_matchesSumMemory_sameResult() public view {
        uint256[] memory values = new uint256[](5);
        values[0] = 10; values[1] = 20; values[2] = 30; values[3] = 40; values[4] = 50;

        uint256 fromCalldata = dataLoc.sumCalldata(values);
        uint256 fromMemory   = dataLoc.sumMemory(values);

        assertEq(fromCalldata, 150, "calldata sum should be 150");
        assertEq(fromMemory,   150, "memory sum should be 150");
        assertEq(fromCalldata, fromMemory, "results must be identical");
    }

    /// @notice calldata params cannot be mutated — only memory allows modification.
    function test_zeroFirstElement_mutatesMemoryArray() public view {
        uint256[] memory values = new uint256[](3);
        values[0] = 99; values[1] = 42; values[2] = 7;

        uint256[] memory result = dataLoc.zeroFirstElement(values);
        assertEq(result[0], 0,  "first element should be zeroed");
        assertEq(result[1], 42, "second element unchanged");
        assertEq(result[2], 7,  "third element unchanged");
    }

    // ── storage pointer vs memory copy ───────────────────────────────────

    /// @notice Storage pointer update persists — state is actually changed.
    function test_storagePointer_persistsMutation() public {
        dataLoc.updateBalanceViaStoragePointer(address(0xA11CE), 9999);

        DataLocations.UserProfile memory p = dataLoc.getProfile(address(0xA11CE));
        assertEq(p.balance, 9999, "storage pointer must persist the balance update");
    }

    /// @notice Memory copy update is a silent no-op — state is NOT changed.
    /// @dev This is the "ghost write" bug. The function runs without reverting,
    ///      the caller sees no error, but the state is exactly as it was before.
    ///      In a real protocol this means a balance update call silently fails —
    ///      no event, no revert, no indication anything went wrong.
    function test_memoryCopy_silentlyDiscardsUpdate() public {
        uint256 balanceBefore = dataLoc.getProfile(address(0xA11CE)).balance;

        dataLoc.updateBalanceViaMemoryCopy(address(0xA11CE), 9999);

        uint256 balanceAfter = dataLoc.getProfile(address(0xA11CE)).balance;
        assertEq(balanceAfter, balanceBefore, "memory copy must NOT persist, storage unchanged");
        assertNotEq(balanceAfter, 9999, "9999 must not appear in storage after memory copy");
    }

    /// @notice Proves storage pointer and memory copy diverge on the same input.
    /// @dev This is the clearest side-by-side demonstration of the semantic difference.
    function test_storageVsMemory_divergeOnSameInput() public {
        // memory copy first — should do nothing
        dataLoc.updateBalanceViaMemoryCopy(address(0xA11CE), 5555);
        assertEq(dataLoc.getProfile(address(0xA11CE)).balance, 1000, "memory: no change");

        // storage pointer second — should actually update
        dataLoc.updateBalanceViaStoragePointer(address(0xA11CE), 5555);
        assertEq(dataLoc.getProfile(address(0xA11CE)).balance, 5555, "storage: updated");
    }

    // ── string / bytes calldata ───────────────────────────────────────────

    /// @notice String concatenation via calldata inputs works correctly.
    function test_concatStrings_returnsCorrectResult() public view {
        string memory result = dataLoc.concatStrings("hello", "world");
        assertEq(result, "helloworld");
    }

    /// @notice String length reads from calldata without memory copy.
    function test_stringLength_correctForAsciiAndEmpty() public view {
        assertEq(dataLoc.stringLength("hello"), 5);
        assertEq(dataLoc.stringLength(""),      0);
        assertEq(dataLoc.stringLength("solidity core labs"), 18);
    }

    // ── memory expansion gas behaviour ───────────────────────────────────

    /// @notice Small and large allocation produce correct sums.
    /// @dev Correctness check — gas difference visible in --gas-report.
    ///      sumLargeArray(100) costs disproportionately more than sumSmallArray(10).
    function test_memoryAllocation_correctSumRegardlessOfSize() public view {
        assertEq(memExp.sumSmallArray(5),   15,   "1+2+3+4+5 = 15");
        assertEq(memExp.sumLargeArray(100), 5050, "sum 1..100 = 5050");
    }

    /// @notice No-allocation version matches allocated version — same result, less gas.
    /// @dev Run --gas-report: sumWithoutAllocation(100) vs sumLargeArray(100).
    ///      Same output. The gap in gas cost is purely memory expansion overhead.
    function test_sumWithoutAllocation_matchesAllocatedVersion() public view {
        uint256 withAlloc    = memExp.sumLargeArray(100);
        uint256 withoutAlloc = memExp.sumWithoutAllocation(100);
        assertEq(withAlloc, withoutAlloc, "both must return 5050");
    }

    /// @notice Memory allocation inside a loop produces correct result.
    /// @dev Correctness passes — but check gas report for the explosion.
    ///      memoryAllocationInLoop(50) vs sumWithoutAllocation(50): same answer, very different gas.
    function test_memoryInLoop_correctButExpensive() public view {
        uint256 looped      = memExp.memoryAllocationInLoop(50);
        uint256 noAlloc     = memExp.sumWithoutAllocation(50);
        assertEq(looped, noAlloc, "both must return 1275");
    }
}
