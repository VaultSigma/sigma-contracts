// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Modifiers} from "../libraries/LibAppStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libraries/LibAccessControl.sol";

/**
 * @title ManagerFacet
 * @notice Facet for setting protocol parameters
 * @dev This facet manages critical protocol parameters and addresses
 * @dev Only callable by admin role
 */
contract ManagerFacet is Modifiers {
    /**
     * @notice Sets treasury address
     * @dev Treasury fund is used to maintain the protocol
     * @dev Only callable by admin
     * @param _treasuryAddress Treasury address
     */
    function setTreasuryAddress(address _treasuryAddress) external onlyAdmin {
        store.treasuryAddress = _treasuryAddress;
    }

    /**
     * @notice Returns treasury address
     * @return address Treasury address
     */
    function treasuryAddress() external view returns (address) {
        return store.treasuryAddress;
    }

    /**
     * @notice Sets the Sigma token address
     * @dev Only callable by admin
     * @param _sigmaTokenAddress Address of the Sigma token contract
     */
    function setSigmaToken(address _sigmaTokenAddress) external onlyAdmin {
        store.sigmaTokenAddress = _sigmaTokenAddress;
    }

    /**
     * @notice Returns the Sigma token address
     * @return address Address of the Sigma token contract
     */
    function sigmaTokenAddress() external view returns (address) {
        return store.sigmaTokenAddress;
    }
}
