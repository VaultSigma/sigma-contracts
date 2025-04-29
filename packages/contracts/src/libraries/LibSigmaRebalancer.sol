// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {AppStorage, LibAppStorage} from "./LibAppStorage.sol";
import "../interfaces/ISigmaPool.sol";
import "../interfaces/ICrocSwapDex.sol";
import "abdk/ABDKMathQuad.sol";

/**
 * @title LibSigmaRebalancer
 * @notice Library for managing the Sigma rebalancer operations
 * @dev Handles rebalancing operations and interactions with DEX routers
 */
library LibSigmaRebalancer {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    /// @notice Storage slot for the Sigma rebalancer
    bytes32 constant SIGMA_REBALANCER_STORAGE_POSITION =
        bytes32(uint256(keccak256("sigma.contracts.rebalancer.storage")) - 1) & ~bytes32(uint256(0xff));

    /**
     * @notice Structure to store Sigma rebalancer state
     * @dev Contains rebalancer-related state variables
     */
    struct SigmaRebalancerStorage {
        address sigmaToken;
        ISigmaPool sigmaPool;
        ICrocSwapDex dexRouter;
    }

    /**
     * @notice Emitted when an allocation is made
     * @param collateralIndex Index of the collateral
     * @param allocation Amount allocated
     */
    event Allocation(uint256 collateralIndex, uint256 allocation);

    /**
     * @notice Emitted when a rebalance operation is executed
     * @param base Base token address
     * @param quote Quote token address
     * @param poolIdx Pool index
     * @param isBuy Whether the operation is a buy
     * @param inBaseQty Whether the quantity is in base token
     * @param qty Quantity involved in the rebalance
     */
    event Rebalance(address base, address quote, uint256 poolIdx, bool isBuy, bool inBaseQty, uint128 qty);

    /**
     * @notice Returns the Sigma rebalancer storage
     * @return sigmaRebalancerStorage Storage struct for the Sigma rebalancer
     */
    function getSigmaRebalancerStorage()
        internal
        pure
        returns (SigmaRebalancerStorage storage sigmaRebalancerStorage)
    {
        bytes32 position = SIGMA_REBALANCER_STORAGE_POSITION;
        assembly {
            sigmaRebalancerStorage.slot := position
        }
    }

    /**
     * @notice Sets the DEX router address
     * @param _dexRouter Address of the DEX router
     */
    function setDexRouter(address _dexRouter) internal {
        SigmaRebalancerStorage storage s = getSigmaRebalancerStorage();
        // require(s.dexRouter == address(0), "SigmaRebalancer: dex router already set");

        // address _dexRouter = ISigmaPool(s.sigmaPool).getDexRouter();

        s.dexRouter = ICrocSwapDex(_dexRouter);
    }

    /**
     * @notice Gets the current DEX router address
     * @return address Current DEX router address
     */
    function getDexRouter() internal view returns (address) {
        SigmaRebalancerStorage storage s = getSigmaRebalancerStorage();
        return address(s.dexRouter);
    }

    /**
     * @notice Sets the Sigma pool address
     * @param _sigmaPool Address of the Sigma pool
     */
    function setSigmaPool(address _sigmaPool) internal {
        SigmaRebalancerStorage storage s = getSigmaRebalancerStorage();
        require(_sigmaPool != address(0), "SigmaRebalancer: zero address");

        s.sigmaPool = ISigmaPool(_sigmaPool);
    }

    /**
     * @notice Gets the current Sigma pool address
     * @return address Current Sigma pool address
     */
    function getSigmaPool() internal view returns (address) {
        SigmaRebalancerStorage storage s = getSigmaRebalancerStorage();
        return address(s.sigmaPool);
    }

    // Experimenting with a new model here.

    /**
     * @notice Gets an allocation of collateral tokens from the Sigma pool
     * @param collateralIndex Index of the collateral
     * @param _allocation Amount to allocate
     */
    function getAllocation(uint256 collateralIndex, uint256 _allocation) internal {
        SigmaRebalancerStorage storage s = getSigmaRebalancerStorage();

        // Implement this. Aim is to get the allocation of the collateral tokens in the sigma pool
        ISigmaPool sigmaPool = s.sigmaPool;
        sigmaPool.allocToRebalancer(collateralIndex, _allocation);

        emit Allocation(collateralIndex, _allocation);
    }

    // function redeemAllocation(uint256 _allocation) internal {
    //     SigmaRebalancerStorage storage s = getSigmaRebalancerStorage();

    //     // Implement this. Aim is to redeem the allocation of the collateral tokens in the sigma pool

    // }

    /**
     * @notice Executes a rebalance operation
     * @dev Uses the DEX router to execute the rebalance
     * @param data Encoded rebalance parameters
     */
    function rebalance(bytes memory data) internal {
        SigmaRebalancerStorage storage s = getSigmaRebalancerStorage();

        require(s.dexRouter != ICrocSwapDex(address(0)), "SigmaRebalancer: dex router not set");

        ICrocSwapDex dexRouter = s.dexRouter;

        uint16 SWAP_PROXY = 1;

        dexRouter.userCmd(SWAP_PROXY, data);
    }
}
