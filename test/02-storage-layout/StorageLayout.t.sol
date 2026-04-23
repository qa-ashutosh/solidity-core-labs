// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../labs/02-storage-layout/StorageLayout.sol";
import "../../labs/02-storage-layout/StorageCollision.sol";

/**
 * @title StorageLayoutTest
 * @notice Foundry tests for Lab 02: Storage Layout & Slot Collision
 *
 * Convention: test_<behavior>_<expectedOutcome>
 *
 * Key tool: vm.load(address, bytes32 slot) — reads raw storage slot value directly.
 * This is how auditors verify layout assumptions without relying on public getters.
 *
 * Verified slot map for StorageLayout.sol:
 *   Slot 0 → fullSlot
 *   Slot 1 → packedA + packedB + packedC (7 bytes packed)
 *   Slot 2 → breakerA (uint256, full)
 *   Slot 3 → wastedX  (uint8, isolated — 31 bytes wasted)
 *   Slot 4 → breakerB (uint256, full)
 *   Slot 5 → wastedY  (uint8, isolated — 31 bytes wasted)
 *   Slot 6 → fixedBytes
 *   Slot 7 → balances mapping marker
 *   Slot 8 → dynamicArray length
 */
contract StorageLayoutTest is Test {

    StorageLayout   layout;
    ProxyStore      proxy;
    VulnerableLogic vulnLogic;
    SafeLogic       safeLogic;

    address constant ALICE = address(0xA11CE);

    function setUp() public {
        layout    = new StorageLayout();
        vulnLogic = new VulnerableLogic();
        safeLogic = new SafeLogic();
        proxy     = new ProxyStore(address(vulnLogic));

        // populate() called directly on the contract address — no prank needed.
        // We call it as the test contract itself (address(this)),
        // so msg.sender inside populate() == address(this).
        // The mapping test uses address(this) as the key to match.
        layout.populate();
    }

    // ── Slot layout tests ────────────────────────────────────────────────

    /// @notice uint256 at slot 0 — raw vm.load matches written value.
    function test_fullSlot_occupiesSlotZero() public view {
        bytes32 raw = vm.load(address(layout), bytes32(uint256(0)));
        assertEq(uint256(raw), 0xDEADBEEF);
    }

    /// @notice packedA, packedB, packedC all live in slot 1.
    /// @dev Solidity stores packed values at increasing byte offsets (little-endian within slot).
    ///      packedA at offset 0, packedB at offset 1, packedC at offset 3.
    function test_packedVariables_shareOneSlot() public view {
        bytes32 slot1 = vm.load(address(layout), bytes32(uint256(1)));

        uint8  a = uint8(uint256(slot1));
        uint16 b = uint16(uint256(slot1) >> 8);
        uint32 c = uint32(uint256(slot1) >> 24);

        assertEq(a, 0xAA,         "packedA should be 0xAA");
        assertEq(b, 0xBBBB,       "packedB should be 0xBBBB");
        assertEq(c, 0xCCCCCCCC,   "packedC should be 0xCCCCCCCC");
    }

    /// @notice breakerA (uint256) forces wastedX into its own slot.
    /// @dev wastedX is uint8 — identical type to packedA — but it cannot
    ///      pack with slot 1 because breakerA sits between them.
    ///      Reading wastedX costs a full SLOAD for 1 byte. That's the waste.
    function test_wastedLayout_breakerForcesIsolatedSlots() public view {
        // breakerA at slot 2 — zero (never set in populate)
        bytes32 slot2 = vm.load(address(layout), bytes32(uint256(2)));
        assertEq(uint256(slot2), 0, "breakerA should be 0");

        // wastedX at slot 3 — isolated, also zero (never set)
        bytes32 slot3 = vm.load(address(layout), bytes32(uint256(3)));
        assertEq(uint256(slot3), 0, "wastedX should be 0 isolated in own slot");

        // breakerB at slot 4
        bytes32 slot4 = vm.load(address(layout), bytes32(uint256(4)));
        assertEq(uint256(slot4), 0, "breakerB should be 0");

        // wastedY at slot 5 — also isolated
        bytes32 slot5 = vm.load(address(layout), bytes32(uint256(5)));
        assertEq(uint256(slot5), 0, "wastedY should be 0 isolated in own slot");
    }

    /// @notice Dynamic array stores its LENGTH at its declared slot (slot 8).
    /// @dev Element data lives at keccak256(abi.encode(8)) + index, NOT at slot 9.
    function test_dynamicArray_lengthInDeclaredSlot() public view {
        bytes32 slot8 = vm.load(address(layout), bytes32(uint256(8)));
        assertEq(uint256(slot8), 1, "Array length should be 1 after one push");
    }

    /// @notice Mapping value for caller lives at keccak256(abi.encode(caller, 7)).
    /// @dev This is the standard EVM storage derivation for mappings.
    ///      populate() stores balances[msg.sender] = 1 ether.
    ///      msg.sender in setUp() context = address(this) = this test contract.
    function test_mappingValue_atKeccakDerivedSlot() public view {
        // The key is address(this) because layout.populate() was called by this test contract
        bytes32 slot = keccak256(abi.encode(address(this), uint256(7)));
        bytes32 raw  = vm.load(address(layout), slot);
        assertEq(uint256(raw), 1 ether, "balance should be 1 ether at derived slot");
    }

    // ── Collision tests ──────────────────────────────────────────────────

    /// @notice Calling initialize() via vulnerable proxy overwrites slot 0 (implementation).
    /// @dev VulnerableLogic.initialize writes `owner = _owner` to slot 0.
    ///      Via delegatecall, slot 0 belongs to the PROXY — overwriting implementation.
    ///      After one call, the proxy points to ALICE (an EOA). Protocol is dead.
    function test_collision_vulnerableLogicCorruptsImplementationPointer() public {
        assertEq(proxy.implementation(), address(vulnLogic), "should start pointing to vulnLogic");

        vm.prank(ALICE);
        (bool ok,) = address(proxy).call(
            abi.encodeWithSelector(VulnerableLogic.initialize.selector, ALICE)
        );
        assertTrue(ok, "call should succeed");

        // implementation pointer is now ALICE — an EOA, not a contract
        assertEq(proxy.implementation(), ALICE, "slot 0 collision: implementation overwritten");
    }

    /// @notice Safe logic with gap pattern leaves proxy slot 0 untouched.
    function test_safeLogic_doesNotCorruptProxySlots() public {
        ProxyStore safeProxy = new ProxyStore(address(safeLogic));
        address originalImpl = safeProxy.implementation();

        vm.prank(ALICE);
        (bool ok,) = address(safeProxy).call(
            abi.encodeWithSelector(SafeLogic.initialize.selector, ALICE)
        );
        assertTrue(ok, "call should succeed");

        assertEq(safeProxy.implementation(), originalImpl, "implementation must be unchanged");
    }

    /// @notice fixedBytes lives at slot 6 — confirmed via raw read.
    function test_fixedBytes_occupiesSlotSix() public view {
        bytes32 slot6 = vm.load(address(layout), bytes32(uint256(6)));
        assertEq(uint256(slot6), 0xFF, "fixedBytes should be 0xFF at slot 6");
    }
}
