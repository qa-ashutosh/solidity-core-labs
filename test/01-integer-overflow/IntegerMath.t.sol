// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../labs/01-integer-overflow/IntegerMath.sol";

/**
 * @title IntegerMathTest
 * @notice Foundry tests for Lab 01: Integer Overflow & Underflow
 *
 * Convention: test_<behavior>_<expectedOutcome>
 *
 * Coverage:
 *  - checked arithmetic reverts on overflow/underflow
 *  - unchecked arithmetic wraps silently
 *  - type truncation discards bits without revert
 *  - multiplication overflow (BEC pattern)
 *  - safe unchecked loop counter pattern
 */
contract IntegerMathTest is Test {

    IntegerMath math;

    function setUp() public {
        math = new IntegerMath();
    }

    /// @notice Checked addition reverts when result exceeds uint256 max.
    function test_checkedAdd_revertsOnOverflow() public {
        vm.expectRevert();
        math.checkedAdd(type(uint256).max, 1);
    }

    /// @notice Unchecked addition silently wraps: max + 1 = 0.
    function test_uncheckedAdd_wrapsToZeroOnOverflow() public view {
        uint256 result = math.uncheckedAdd(type(uint256).max, 1);
        assertEq(result, 0, "Expected overflow wrap to 0");
    }

    /// @notice Checked subtraction reverts on underflow (b > a).
    function test_checkedSub_revertsOnUnderflow() public {
        vm.expectRevert();
        math.checkedSub(0, 1);
    }

    /// @notice Unchecked subtraction: 0 - 1 = type(uint256).max.
    function test_uncheckedSub_wrapsToMaxOnUnderflow() public view {
        uint256 result = math.uncheckedSub(0, 1);
        assertEq(result, type(uint256).max, "Expected underflow wrap to uint256 max");
    }

    /// @notice Truncating cast silently corrupts — no revert, wrong value.
    /// @dev This looks safe. It is not. 256 becomes 0. 257 becomes 1.
    function test_truncatingCast_silentlyDiscardsBits() public view {
        assertEq(math.truncatingCast(256), 0,   "256 must truncate to 0 in uint8");
        assertEq(math.truncatingCast(257), 1,   "257 must truncate to 1 in uint8");
        assertEq(math.truncatingCast(255), 255, "255 fits in uint8, no truncation");
    }

    /// @notice Unchecked multiplication wraps — the BEC exploit pattern.
    function test_uncheckedMul_wrapsOnLargeInputs() public view {
        uint256 a = type(uint256).max / 2 + 1;
        uint256 b = 2;
        uint256 result = math.uncheckedMul(a, b);
        assertTrue(result < a, "Overflow must produce value smaller than one operand");
    }

    /// @notice Safe unchecked loop produces correct sum.
    function test_safeUncheckedLoop_correctSumForBoundedArray() public view {
        uint256[] memory values = new uint256[](5);
        values[0] = 10;
        values[1] = 20;
        values[2] = 30;
        values[3] = 40;
        values[4] = 50;
        assertEq(math.sumArray(values), 150, "Expected sum of 150");
    }
}
