// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

interface IStrategyRegistry {
    struct StrategyInfo {
        address deploymentAddress;
        string strategyDesc;
        bool isActive;
    }

    event StrategyAdded(bytes32 strategyId, string strategyDesc);

    function addStrategy(address deploymentAddress, string memory strategyDesc) external;
    function toggleStrategy(bytes32 strategyId, bool isActive) external;
    function getStrategyInfo(bytes32 strategyId) external view returns (StrategyInfo memory);
} 