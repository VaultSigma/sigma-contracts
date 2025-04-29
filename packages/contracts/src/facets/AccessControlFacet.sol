// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IAccessControl} from "../interfaces/IAccessControl.sol";
import {AccessControlInternal} from "../access/AccessControlInternal.sol";
import {LibAccessControl} from "../libraries/LibAccessControl.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

/**
 * @title AccessControlFacet
 * @notice Role-based access control facet for the Sigma protocol
 * @dev Derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 * @dev https://github.com/solidstate-network/solidstate-solidity/blob/master/contracts/access/access_control/AccessControl.sol
 * @dev This facet implements role-based access control using the Diamond pattern
 */
contract AccessControlFacet is Modifiers, IAccessControl, AccessControlInternal {
    /**
     * @notice Grants a role to an account
     * @dev Only callable by accounts with the role's admin role
     * @param role The role to grant
     * @param account The account to grant the role to
     */
    function grantRole(bytes32 role, address account) external onlyRole(_getRoleAdmin(role)) {
        return _grantRole(role, account);
    }

    /**
     * @notice Sets the admin role for a given role
     * @dev Only callable by the admin
     * @param role The role to set the admin for
     * @param adminRole The new admin role
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external onlyAdmin {
        _setRoleAdmin(role, adminRole);
    }

    /**
     * @notice Checks if an account has a specific role
     * @param role The role to check
     * @param account The account to check
     * @return bool True if the account has the role, false otherwise
     */
    function hasRole(bytes32 role, address account) external view returns (bool) {
        return _hasRole(role, account);
    }

    /**
     * @notice Gets the admin role for a given role
     * @param role The role to get the admin for
     * @return bytes32 The admin role
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32) {
        return _getRoleAdmin(role);
    }

    /**
     * @notice Revokes a role from an account
     * @dev Only callable by accounts with the role's admin role
     * @param role The role to revoke
     * @param account The account to revoke the role from
     */
    function revokeRole(bytes32 role, address account) external onlyRole(_getRoleAdmin(role)) {
        return _revokeRole(role, account);
    }

    /**
     * @notice Allows an account to renounce a role
     * @param role The role to renounce
     */
    function renounceRole(bytes32 role) external {
        return _renounceRole(role);
    }

    /**
     * @notice Returns the paused state of the contract
     * @return bool True if the contract is paused, false otherwise
     */
    function paused() public view returns (bool) {
        return LibAccessControl.paused();
    }

    /**
     * @notice Pauses the contract
     * @dev Only callable by the admin when the contract is not paused
     */
    function pause() external whenNotPaused onlyAdmin {
        LibAccessControl.pause();
    }

    /**
     * @notice Unpauses the contract
     * @dev Only callable by the admin when the contract is paused
     */
    function unpause() external whenPaused onlyAdmin {
        LibAccessControl.unpause();
    }
}
