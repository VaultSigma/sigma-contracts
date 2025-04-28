// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {AppStorage, LibAppStorage} from "./LibAppStorage.sol";
import "../interfaces/ISigmaPool.sol";
import "../interfaces/ICrocSwapDex.sol";
import "abdk/ABDKMathQuad.sol";

library LibSigmaRebalancer {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

 
    bytes32 constant SIGMA_REBALANCER_STORAGE_POSITION =
        bytes32(
            uint256(keccak256("sigma.contracts.rebalancer.storage")) - 1
        ) & ~bytes32(uint256(0xff));

    struct SigmaRebalancerStorage {
        address rebalancerManager;
        address[] collateralTokens;
        address sigmaToken;
        ISigmaPool sigmaPool;
        ICrocSwapDex dexRouter;
    }

    event Rebalance(
        address base,
        address quote,
        uint256 poolIdx,
        bool isBuy,
        bool inBaseQty,
        uint128 qty
    );

    function getSigmaRebalancerStorage() internal pure returns (SigmaRebalancerStorage storage sigmaRebalancerStorage) {
        bytes32 position = SIGMA_REBALANCER_STORAGE_POSITION;
        assembly {
            sigmaRebalancerStorage.slot := position
        }
    }

    function initialize(address[] memory _collateralTokens) internal {
        SigmaRebalancerStorage storage s = getSigmaRebalancerStorage();
        // s.rebalancerManager = _rebalancerManager;

        for (uint256 i = 0; i < _collateralTokens.length; i++) {
            require(_collateralTokens[i] != address(0), "SigmaRebalancer: zero address");

            s.collateralTokens.push(_collateralTokens[i]);
        }
    }

    function setDexRouter(address _dexRouter) internal {
        SigmaRebalancerStorage storage s = getSigmaRebalancerStorage();
        // require(s.dexRouter == address(0), "SigmaRebalancer: dex router already set");
        require(_dexRouter != address(0), "SigmaRebalancer: zero address");

        s.dexRouter = ICrocSwapDex(_dexRouter);
    }

    function setSigmaToken(address _sigmaToken) internal {
        SigmaRebalancerStorage storage s = getSigmaRebalancerStorage();
        require(s.sigmaToken == address(0), "SigmaRebalancer: address already set");
        require(_sigmaToken != address(0), "SigmaRebalancer: zero address");

        s.sigmaToken = _sigmaToken;
    }

    function setSigmaPool(address _sigmaPoolAddress) internal {
        SigmaRebalancerStorage storage s = getSigmaRebalancerStorage();
        // require(s.sigmaPool == address(0), "SigmaRebalancer: address already set");

        require(_sigmaPoolAddress != address(0), "SigmaRebalancer: zero address");

        s.sigmaPool = ISigmaPool(_sigmaPoolAddress);
    }

    function getAllocation(uint256 _allocation) internal {
        SigmaRebalancerStorage storage s = getSigmaRebalancerStorage();

        // Implement this. Aim is to get the allocation of the collateral tokens in the sigma pool


    }

    function redeemAllocation(uint256 _allocation) internal {
        SigmaRebalancerStorage storage s = getSigmaRebalancerStorage();

        // Implement this. Aim is to redeem the allocation of the collateral tokens in the sigma pool


    }

    function rebalance(address _base, address _quote, uint256 _poolIdx, bool _isBuy, bool _inBaseQty, uint256 _qty, uint256 _tip, uint256 _limitPrice, uint256 _minOut, uint256 _reserveFlags) internal {
        SigmaRebalancerStorage storage s = getSigmaRebalancerStorage();

        uint128 qty = uint128(_qty);
        uint16 tip = uint16(_tip);
        uint128 limitPrice = uint128(_limitPrice);
        uint128 minOut = uint128(_minOut);
        uint8 reserveFlags = uint8(_reserveFlags);

        uint16 SWAP_PROXY = 1;

        s.dexRouter.userCmd(SWAP_PROXY, abi.encode(
            _base,
            _quote,
            _poolIdx,
            _isBuy,
            _inBaseQty,
            qty,
            tip,
            limitPrice,
            minOut,
            reserveFlags
        ));

        emit Rebalance(
            _base,
            _quote,
            _poolIdx,
            _isBuy,
            _inBaseQty,
            qty
        );
    }
}