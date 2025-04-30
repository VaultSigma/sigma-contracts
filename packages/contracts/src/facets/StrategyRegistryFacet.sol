// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {LibStrategyRegistry} from "../libraries/LibStrategyRegistry.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

/**
 * @title StrategyRegistryFacet
 * @notice Facet for managing investment strategies
 * @dev Handles registration, updates, and management of investment strategies
 */
contract StrategyRegistryFacet is Modifiers {
    /**
     * @notice Adds a new investment strategy
     * @dev Only callable by admin
     * @param ipfsUri IPFS URI containing strategy details
     * @param strategyDesc Description of the strategy
     * @param strategyType Type of the strategy
     */
    function addStrategy(
        string memory ipfsUri,
        string memory strategyDesc,
        LibStrategyRegistry.StrategyType strategyType
    ) external onlyAdmin {
        LibStrategyRegistry.addStrategy(ipfsUri, strategyDesc, strategyType);
    }

    /**
     * @notice Updates an existing strategy
     * @dev Only callable by admin
     * @param strategyId ID of the strategy to update
     * @param ipfsUri New IPFS URI containing strategy details
     * @param strategyType New strategy type
     */
    function updateStrategy(uint256 strategyId, string memory ipfsUri, LibStrategyRegistry.StrategyType strategyType)
        external
        onlyAdmin
    {
        LibStrategyRegistry.updateStrategy(strategyId, ipfsUri, strategyType);
    }

    /**
     * @notice Toggles a strategy's active status
     * @dev Only callable by admin
     * @param strategyId ID of the strategy to toggle
     * @param isActive New active status
     */
    function toggleStrategy(uint256 strategyId, bool isActive) external onlyAdmin {
        LibStrategyRegistry.toggleStrategy(strategyId, isActive);
    }

    /**
     * @notice Gets information about a specific strategy
     * @dev Only callable by admin
     * @param strategyId ID of the strategy
     * @return StrategyInfo Strategy information
     */
    function getStrategyInfo(uint256 strategyId)
        external
        view
        returns (LibStrategyRegistry.StrategyInfo memory)
    {
        return LibStrategyRegistry.getStrategyInfo(strategyId);
    }

    /**
     * @notice Gets information about all strategies
     * @return StrategyInfo[] Array of all strategies
     */
    function getAllStrategies() external view returns (LibStrategyRegistry.StrategyInfo[] memory) {
        return LibStrategyRegistry.getAllStrategies();
    }
}
