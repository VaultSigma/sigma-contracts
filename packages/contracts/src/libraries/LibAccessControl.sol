// SPDX-License-Identifier: MIT

pragma solidity 0.8.29;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {AddressUtils} from "../libraries/AddressUtils.sol";
import {UintUtils} from "../libraries/UintUtils.sol";
import {LibAppStorage} from "./LibAppStorage.sol";

/**
 * @title LibAccessControl
 * @notice Library for managing access control in the protocol
 * @dev Provides role-based access control functionality with role hierarchy
 */
library LibAccessControl {
    using AddressUtils for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using UintUtils for uint256;

    /// @notice Storage slot used to store data for this library
    bytes32 constant ACCESS_CONTROL_STORAGE_SLOT =
        bytes32(uint256(keccak256("sigma.contracts.access.control.storage")) - 1) & ~bytes32(uint256(0xff));

    /**
     * @notice Structure to keep all role members with their admin role
     * @dev Uses EnumerableSet for efficient role membership management
     */
    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    /**
     * @notice Structure to keep all protocol roles
     * @dev Maps role identifiers to their respective RoleData
     */
    struct Layout {
        mapping(bytes32 => RoleData) roles;
    }

    /**
     * @notice Emitted when admin role of a role is updated
     * @param role Role whose admin was changed
     * @param previousAdminRole Previous admin role
     * @param newAdminRole New admin role
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @notice Emitted when role is granted to account
     * @param role Role that was granted
     * @param account Account that received the role
     * @param sender Account that granted the role
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @notice Emitted when role is revoked from account
     * @param role Role that was revoked
     * @param account Account that lost the role
     * @param sender Account that revoked the role
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @notice Emitted when the pause is triggered
     * @param account Account that triggered the pause
     */
    event Paused(address account);

    /**
     * @notice Emitted when the pause is lifted
     * @param account Account that lifted the pause
     */
    event Unpaused(address account);

    /**
     * @notice Returns struct used as a storage for this library
     * @return l Struct used as a storage
     */
    function accessControlStorage() internal pure returns (Layout storage l) {
        bytes32 slot = ACCESS_CONTROL_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice Checks that a method can only be called by the provided role
     * @dev Reverts if the caller doesn't have the required role
     * @param role Role name to check
     */
    modifier onlyRole(bytes32 role) {
        checkRole(role);
        _;
    }

    /**
     * @notice Returns true if the contract is paused and false otherwise
     * @return bool Whether the contract is paused
     */
    function paused() internal view returns (bool) {
        return LibAppStorage.appStorage().paused;
    }

    /**
     * @notice Checks whether role is assigned to account
     * @param role Role to check
     * @param account Address to check
     * @return bool Whether role is assigned to account
     */
    function hasRole(bytes32 role, address account) internal view returns (bool) {
        return accessControlStorage().roles[role].members.contains(account);
    }

    /**
     * @notice Reverts if sender does not have a given role
     * @dev Reverts with a descriptive error message
     * @param role Role to query
     */
    function checkRole(bytes32 role) internal view {
        checkRole(role, msg.sender);
    }

    /**
     * @notice Reverts if given account does not have a given role
     * @dev Reverts with a descriptive error message
     * @param role Role to query
     * @param account Address to query
     */
    function checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        account.toString(),
                        " is missing role ",
                        uint256(role).toHexString(32)
                    )
                )
            );
        }
    }

    /**
     * @notice Returns admin role for a given role
     * @param role Role to query
     * @return bytes32 Admin role for the provided role
     */
    function getRoleAdmin(bytes32 role) internal view returns (bytes32) {
        return accessControlStorage().roles[role].adminRole;
    }

    /**
     * @notice Sets a new admin role for a provided role
     * @param role Role for which admin role should be set
     * @param adminRole Admin role to set
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        bytes32 previousAdminRole = getRoleAdmin(role);
        accessControlStorage().roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @notice Assigns role to a given account
     * @param role Role to assign
     * @param account Recipient of role assignment
     */
    function grantRole(bytes32 role, address account) internal {
        accessControlStorage().roles[role].members.add(account);
        emit RoleGranted(role, account, msg.sender);
    }

    /**
     * @notice Unassign role from a given account
     * @param role Role to unassign
     * @param account Address from which the provided role should be unassigned
     */
    function revokeRole(bytes32 role, address account) internal {
        accessControlStorage().roles[role].members.remove(account);
        emit RoleRevoked(role, account, msg.sender);
    }

    /**
     * @notice Renounces role
     * @param role Role to renounce
     */
    function renounceRole(bytes32 role) internal {
        revokeRole(role, msg.sender);
    }

    /**
     * @notice Pauses the contract
     * @dev Emits a Paused event
     */
    function pause() internal {
        LibAppStorage.appStorage().paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses the contract
     * @dev Emits an Unpaused event
     */
    function unpause() internal {
        LibAppStorage.appStorage().paused = false;
        emit Unpaused(msg.sender);
    }
}
