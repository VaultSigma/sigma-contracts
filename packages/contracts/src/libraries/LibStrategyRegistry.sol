// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

library LibStrategyRegistry {
    bytes32 internal constant STORAGE_SLOT = keccak256("sigma.storage.strategy.registry");

    struct StrategyInfo {
        address deploymentAddress;
        string strategyDesc; // This describes the strategy
        bool isActive;
    }

    struct StrategyRegistryStorage {
        uint256 strategyCount;
        mapping(bytes32 strategyId => StrategyInfo strategyInfo) stratByIds;
        mapping(address deploymentAddress => bytes32 strategyId) stratAddrByIds;
        bytes32[] strategyIds;
    }

    event StrategyAdded(bytes32 strategyId, string strategyDesc);

    function registryStorage() internal pure returns (StrategyRegistryStorage storage ds) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            ds.slot := slot
        }
    }

    function addStrategy(address deploymentAddress, string memory strategyDesc) internal {
        StrategyRegistryStorage storage s = registryStorage();
        
        // Might consider using a simple uint256 counter instead of a keccak256 hash in future
        bytes32 strategyId = keccak256(abi.encodePacked(deploymentAddress));

        require(deploymentAddress != address(0), "StrategyRegistry: deployment address is zero");
        require(s.stratByIds[strategyId].deploymentAddress == address(0), "StrategyRegistry: strategy already exists");

        // Leaving this in for now
        s.strategyCount++;
        s.strategyIds.push(strategyId); 
        s.stratByIds[strategyId] = StrategyInfo({
            deploymentAddress: deploymentAddress,
            strategyDesc: strategyDesc,
            isActive: false
        });

        s.stratAddrByIds[deploymentAddress] = strategyId;

        emit StrategyAdded(strategyId, strategyDesc);
    }

    function toggleStrategy(bytes32 strategyId, bool isActive) internal {
        StrategyRegistryStorage storage s = registryStorage();

        require(s.stratByIds[strategyId].deploymentAddress != address(0), "StrategyRegistry: strategy does not exist");

        s.stratByIds[strategyId].isActive = isActive;
    }

    function getStrategyInfo(bytes32 strategyId) internal view returns (StrategyInfo memory strategyInfo) {
        StrategyRegistryStorage storage s = registryStorage();

        require(s.stratByIds[strategyId].deploymentAddress != address(0), "StrategyRegistry: strategy does not exist");

        return s.stratByIds[strategyId];
    }


}
