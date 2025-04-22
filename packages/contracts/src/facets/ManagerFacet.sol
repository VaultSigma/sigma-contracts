// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Modifiers} from "../libraries/LibAppStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libraries/LibAccessControl.sol";

/**
 * @notice Facet for setting protocol parameters
 */
contract ManagerFacet is Modifiers {

    /**
     * @notice Sets bonding curve address
     * @param _bondingCurveAddress Bonding curve address
     */
    // function setBondingCurveAddress(
    //     address _bondingCurveAddress
    // ) external onlyAdmin {
    //     store.bondingCurveAddress = _bondingCurveAddress;
    // }

 

    /**
     * @notice Sets treasury address
     * @dev Treasury fund is used to maintain the protocol
     * @param _treasuryAddress Treasury address
     */
    function setTreasuryAddress(address _treasuryAddress) external onlyAdmin {
        store.treasuryAddress = _treasuryAddress;
    }

    
    /**
     * @notice Returns bonding curve address
     * @return Bonding curve address
     */
    // function bondingCurveAddress() external view returns (address) {
    //     return store.bondingCurveAddress;
    // }

    /**
     * @notice Returns treasury address
     * @return Treasury address
     */
    function treasuryAddress() external view returns (address) {
        return store.treasuryAddress;
    }

    function setSigmaToken(address _sigmaTokenAddress) external onlyAdmin {
        store.sigmaTokenAddress = _sigmaTokenAddress;
    }

    function sigmaTokenAddress() external view returns (address) {
        return store.sigmaTokenAddress;
    }
}