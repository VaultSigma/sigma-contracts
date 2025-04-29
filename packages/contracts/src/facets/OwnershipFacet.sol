// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IERC173} from "../interfaces/IERC173.sol";

/**
 * @title OwnershipFacet
 * @notice Used for managing contract's owner
 * @dev Implements the ERC-173 standard for contract ownership
 * @dev Uses Diamond pattern for ownership management
 */
contract OwnershipFacet is IERC173 {
    /**
     * @notice Transfers ownership of the contract to a new address
     * @dev Only callable by the current owner
     * @dev Reverts if new owner is the zero address
     * @param _newOwner Address of the new owner
     */
    function transferOwnership(address _newOwner) external override {
        require((_newOwner != address(0)), "OwnershipFacet: New owner cannot be the zero address");
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    /**
     * @notice Returns the address of the current owner
     * @return owner_ Address of the current owner
     */
    function owner() external view override returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}
