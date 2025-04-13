// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import "../libraries/LibAppStorage.sol";
import "../libraries/LibAccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

/**
 * @notice It is expected that this contract is customized if you want to deploy your diamond
 * with data from a deployment script. Use the init function to initialize state variables
 * of your diamond. Add parameters to the init function if you need to.
 *
 * @notice How it works:
 * 1. New `Diamond` contract is created
 * 2. Inside the diamond's constructor there a `delegatecall()` to `DiamondInit` with the provided args
 * 3. `DiamondInit` updates diamond storage
 */
contract DiamondInit is Modifiers {
    /// @notice Struct used for diamond initialization
    struct Args {
        address admin;
    }

    /**
     * @notice Initializes a diamond with state variables
     * @dev You can add parameters to this function in order to pass in data to set your own state variables
     * @param _args Init args
     */
    function init(Args memory _args) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        LibAccessControl.grantRole(DEFAULT_ADMIN_ROLE, _args.admin);

        AppStorage storage appStore = LibAppStorage.appStorage();

        appStore.paused = false;
        appStore.treasuryAddress = _args.admin;

        // reentrancy guard
        _initReentrancyGuard();

    }
}