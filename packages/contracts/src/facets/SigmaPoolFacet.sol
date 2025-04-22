// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {LibSigmaPool} from "../libraries/LibSigmaPool.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SigmaPoolFacet {
    using LibSigmaPool for LibSigmaPool.SigmaPoolStorage;

    event Deposit(address indexed user, uint256 collateralIndex, uint256 amount, uint256 shares);
    event LockCreated(address indexed user, uint256 id, uint256 amount, uint256 unlockTime);
    event LockExtended(address indexed user, uint256 id, uint256 timelock, uint256 unlockTime);
    event CollateralAdded(address indexed collateralAddress, uint256 index);
    event FeesSet(uint256 redemptionFee);

    function initialize(address _asset, address _vSigmaToken) external {
        LibSigmaPool.initialize(_asset, _vSigmaToken);
    }

    function setFeeTreasury(address _feeTreasury) external {
        LibSigmaPool.setFeeTreasury(_feeTreasury);
    }

    function setSigmaRebalancer(address _sigmaRebalancer) external {
        LibSigmaPool.setSigmaRebalancer(_sigmaRebalancer);
    }

    function deposit(uint256 collateralIndex, uint256 amount, uint256 timelock) external {
        LibSigmaPool.deposit(collateralIndex, amount, timelock);
    }

    function extendLock(uint256 id, uint256 additional_time) external {
        LibSigmaPool.extendLock(id, additional_time);
    }

    function addCollateralToken(address collateralAddress) external {
        LibSigmaPool.addCollateralToken(collateralAddress);
    }

    function setFees(uint256 redemptionFee) external {
        LibSigmaPool.setFees(redemptionFee);
    }

    function collateralInformation(
        address collateralAddress
    ) external view returns (LibSigmaPool.CollateralInformation memory) {
        return LibSigmaPool.collateralInformation(collateralAddress);
    }

    function getTotalAssets() external view returns (uint256) {
        return LibSigmaPool.sigmaPoolStorage().totalAssets;
    }

    function getTotalShares() external view returns (uint256) {
        return LibSigmaPool.sigmaPoolStorage().totalShares;
    }

    function getLockInfo(address user, uint256 id) external view returns (
        uint256 amount,
        uint256 timelock,
        uint256 unlockTime,
        uint256 rewards
    ) {
        LibSigmaPool.Lock memory lock = LibSigmaPool.sigmaPoolStorage().userLocks[user][id];
        return (lock.amount, lock.timelock, lock.unlockTime, lock.rewards);
    }

    function getUserTotalLocked(address user) external view returns (uint256) {
        return LibSigmaPool.sigmaPoolStorage().totalLockedPerUser[user];
    }

    function getCollateralAddresses() external view returns (address[] memory) {
        return LibSigmaPool.sigmaPoolStorage().collateralAddresses;
    }

    function isCollateralEnabled(address collateralAddress) external view returns (bool) {
        return LibSigmaPool.sigmaPoolStorage().isCollateralEnabled[collateralAddress];
    }

    function isMintPaused(uint256 collateralIndex) external view returns (bool) {
        return LibSigmaPool.sigmaPoolStorage().isMintPaused[collateralIndex];
    }

    function isRedeemPaused(uint256 collateralIndex) external view returns (bool) {
        return LibSigmaPool.sigmaPoolStorage().isRedeemPaused[collateralIndex];
    }
}