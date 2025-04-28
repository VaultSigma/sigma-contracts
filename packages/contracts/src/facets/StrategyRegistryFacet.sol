// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {LibStrategyRegistry} from "../libraries/LibStrategyRegistry.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

contract StrategyRegistryFacet is Modifiers {
    function addStrategy(
        string memory ipfsUri,
        string memory strategyDesc,
        LibStrategyRegistry.StrategyType strategyType
    ) external onlyAdmin() {
        LibStrategyRegistry.addStrategy(ipfsUri, strategyDesc, strategyType);
    }

    function updateStrategy(
        uint256 strategyId,
        string memory ipfsUri,
        LibStrategyRegistry.StrategyType strategyType
    ) external onlyAdmin() {
        LibStrategyRegistry.updateStrategy(strategyId, ipfsUri, strategyType);
    }

    function toggleStrategy(uint256 strategyId, bool isActive) external onlyAdmin() {
        LibStrategyRegistry.toggleStrategy(strategyId, isActive);
    }

    function getStrategyInfo(
        uint256 strategyId
    ) external view onlyAdmin() returns (LibStrategyRegistry.StrategyInfo memory) {
        return LibStrategyRegistry.getStrategyInfo(strategyId);
    }

    function getAllStrategies() external view returns (LibStrategyRegistry.StrategyInfo[] memory) {
        return LibStrategyRegistry.getAllStrategies();
    }
} 