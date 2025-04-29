// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {LibStrategyRegistry} from "../libraries/LibStrategyRegistry.sol";

interface IStrategyRegistry {
    function addStrategy(
        string memory ipfsUri,
        string memory strategyDesc,
        LibStrategyRegistry.StrategyType strategyType
    ) external;
    function updateStrategy(uint256 strategyId, string memory ipfsUri, LibStrategyRegistry.StrategyType strategyType)
        external;
    function toggleStrategy(uint256 strategyId, bool isActive) external;
    function getStrategyInfo(uint256 strategyId) external view returns (LibStrategyRegistry.StrategyInfo memory);
    function getAllStrategies() external view returns (LibStrategyRegistry.StrategyInfo[] memory);
}
