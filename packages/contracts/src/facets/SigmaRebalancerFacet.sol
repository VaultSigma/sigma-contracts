// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {LibStrategyRegistry} from "../libraries/LibStrategyRegistry.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibSigmaRebalancer} from "../libraries/LibSigmaRebalancer.sol";
import {ISigmaRebalancer} from "../interfaces/ISigmaRebalancer.sol";

/**
 * @title SigmaRebalancerFacet
 * @notice Facet for managing the Sigma rebalancer operations
 * @dev Handles rebalancing operations and configuration of the rebalancer
 */
contract SigmaRebalancerFacet is Modifiers {
    /**
     * @notice Executes a rebalance operation
     * @dev Only callable by admin
     * @param data Encoded rebalance parameters
     */
    function rebalance(bytes memory data) external onlyAdmin {
        LibSigmaRebalancer.rebalance(data);
    }

    /**
     * @notice Sets the DEX router address
     * @dev Only callable by admin
     * @param _dexRouter Address of the DEX router
     */
    function setDexRouter(address _dexRouter) external onlyAdmin {
        LibSigmaRebalancer.setDexRouter(_dexRouter);
    }

    /**
     * @notice Gets the current DEX router address
     * @return address Current DEX router address
     */
    function getDexRouter() external view returns (address) {
        return LibSigmaRebalancer.getDexRouter();
    }

    /**
     * @notice Sets the Sigma pool address
     * @dev Only callable by admin
     * @param _sigmaPool Address of the Sigma pool
     */
    function setSigmaPool(address _sigmaPool) external onlyAdmin {
        LibSigmaRebalancer.setSigmaPool(_sigmaPool);
    }

    /**
     * @notice Gets the current Sigma pool address
     * @return address Current Sigma pool address
     */
    function getSigmaPool() external view returns (address) {
        return LibSigmaRebalancer.getSigmaPool();
    }
}
