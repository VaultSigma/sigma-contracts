// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

library LibStrategyRegistry {
    bytes32 internal constant STORAGE_SLOT = keccak256("sigma.storage.strategy.registry");

    struct StrategyInfo {
        string ipfsUri;
        string strategyDesc; // This describes the strategy
        bool isActive;
        uint256 createdAt;
        StrategyType strategyType;
    }

    struct StrategyRegistryStorage {
        uint256 strategyCount;
        mapping(uint256 strategyId => StrategyInfo strategyInfo) stratByIds;
        uint256[] strategyIds;
    }

    enum StrategyType {
        Experimental,
        Stable
    }

    event StrategyAdded(uint256 strategyId, string strategyDesc);

    function registryStorage() internal pure returns (StrategyRegistryStorage storage ds) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            ds.slot := slot
        }
    }

    function addStrategy(string memory ipfsUri, string memory strategyDesc, StrategyType strategyType) internal {
        StrategyRegistryStorage storage s = registryStorage();

        // Might consider using a simple uint256 counter instead of a keccak256 hash in future
        uint256 strategyId = uint256(keccak256(abi.encodePacked(ipfsUri)));

        require(bytes(s.stratByIds[strategyId].ipfsUri).length == 0, "StrategyRegistry: strategy already exists");

        // Leaving this in for now
        s.strategyCount++;
        s.strategyIds.push(strategyId);
        s.stratByIds[strategyId] = StrategyInfo({
            ipfsUri: ipfsUri,
            strategyDesc: strategyDesc,
            isActive: false,
            createdAt: block.timestamp,
            strategyType: strategyType
        });

        emit StrategyAdded(strategyId, strategyDesc);
    }

    function updateStrategy(uint256 strategyId, string memory ipfsUri, StrategyType strategyType) internal {
        StrategyRegistryStorage storage s = registryStorage();

        require(bytes(s.stratByIds[strategyId].ipfsUri).length > 0, "StrategyRegistry: strategy does not exist");

        s.stratByIds[strategyId].ipfsUri = ipfsUri;
        s.stratByIds[strategyId].strategyType = strategyType;
    }

    function toggleStrategy(uint256 strategyId, bool isActive) internal {
        StrategyRegistryStorage storage s = registryStorage();

        require(bytes(s.stratByIds[strategyId].ipfsUri).length > 0, "StrategyRegistry: strategy does not exist");

        s.stratByIds[strategyId].isActive = isActive;
    }

    function getStrategyInfo(uint256 strategyId) internal view returns (StrategyInfo memory strategyInfo) {
        StrategyRegistryStorage storage s = registryStorage();

        require(bytes(s.stratByIds[strategyId].ipfsUri).length > 0, "StrategyRegistry: strategy does not exist");

        return s.stratByIds[strategyId];
    }

    function getAllStrategies() internal view returns (StrategyInfo[] memory strategies) {
        StrategyRegistryStorage storage s = registryStorage();

        strategies = new StrategyInfo[](s.strategyCount);
        for (uint256 i = 0; i < s.strategyCount; i++) {
            strategies[i] = s.stratByIds[s.strategyIds[i]];
        }
    }
}
