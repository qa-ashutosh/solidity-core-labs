// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title ProxyStore
 * @notice Minimal proxy contract that stores an implementation address and delegates calls.
 *
 * @dev COLLISION DEMONSTRATION:
 *      This proxy declares `implementation` at slot 0.
 *      If the implementation contract ALSO uses slot 0 for its own variable,
 *      a delegatecall will OVERWRITE the implementation address.
 *
 *      This is the exact bug class that has drained proxy-based protocols.
 *      EIP-1967 exists specifically to solve this by using a pseudo-random slot
 *      (keccak256("eip1967.proxy.implementation") - 1) instead of slot 0.
 *
 * AUDIT FLAG: Any proxy that stores admin/implementation in sequential slots 0,1,2
 *             is vulnerable to collision with the implementation contract's own storage.
 */
contract ProxyStore {

    // ⚠️  SLOT 0 — implementation address lives here
    // If the implementation contract writes to slot 0, this gets overwritten.
    address public implementation;

    // ⚠️  SLOT 1 — admin address
    address public admin;

    constructor(address _impl) {
        implementation = _impl;
        admin = msg.sender;
    }

    /// @notice Delegates all calls to the implementation contract.
    /// @dev CRITICAL: delegatecall runs the implementation's code
    ///      but reads/writes THIS contract's storage.
    ///      If implementation.slot0 != proxy.slot0 semantically → collision.
    fallback() external payable {
        address impl = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}

/**
 * @title VulnerableLogic
 * @notice Implementation contract with slot 0 collision.
 *
 * @dev This contract declares `owner` at slot 0.
 *      When called via ProxyStore (delegatecall), writing to `owner`
 *      actually writes to ProxyStore's slot 0 — overwriting `implementation`.
 *
 *      After one call to initialize(), the proxy's implementation pointer
 *      is replaced with the caller's address. All future delegatecalls go
 *      to that address — which is an EOA, not a contract. Everything breaks.
 */
contract VulnerableLogic {

    // ⚠️  SLOT 0 — collides with ProxyStore.implementation
    address public owner;

    // ⚠️  SLOT 1 — collides with ProxyStore.admin
    uint256 public value;

    /// @notice Called via proxy to "initialize" the logic contract.
    /// @dev EXPLOIT: this writes msg.sender to slot 0 of the PROXY,
    ///      overwriting the implementation pointer with an EOA address.
    function initialize(address _owner) external {
        owner = _owner; // writes to proxy's slot 0 → corrupts implementation pointer
    }

    function setValue(uint256 _value) external {
        value = _value; // writes to proxy's slot 1 → corrupts admin pointer
    }
}

/**
 * @title SafeLogic
 * @notice Implementation contract with EIP-1967-style collision resistance.
 *
 * @dev Uses a gap pattern: reserves slot 0 and 1 as empty to match
 *      the proxy's layout before declaring its own variables.
 *      Real EIP-1967 uses keccak256-derived slots for the proxy pointers,
 *      but the gap pattern demonstrates the alignment requirement clearly.
 */
contract SafeLogic {

    // Reserves slots 0 and 1 to match ProxyStore's layout.
    // These variables are never written — they act as alignment spacers.
    address private _reserved0; // slot 0: matches ProxyStore.implementation
    address private _reserved1; // slot 1: matches ProxyStore.admin

    // slot 2 onward: safe to use
    address public owner;       // slot 2
    uint256 public value;       // slot 3

    function initialize(address _owner) external {
        owner = _owner; // writes to slot 2 — proxy slot 0 untouched
    }

    function setValue(uint256 _value) external {
        value = _value; // writes to slot 3 — proxy slot 1 untouched
    }
}
