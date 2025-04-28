// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {LibSigmaPool} from "../libraries/LibSigmaPool.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

contract SigmaPoolFacet is Modifiers {

    event Deposit(address indexed user, uint256 collateralIndex, uint256 amount, uint256 shares);
    event LockCreated(address indexed user, uint256 id, uint256 amount, uint256 unlockTime);
    event LockExtended(address indexed user, uint256 id, uint256 timelock, uint256 unlockTime);
    event CollateralAdded(address indexed collateralAddress, uint256 index);
    event FeesSet(uint256 redemptionFee);

    function initialize(address _vSigmaToken, uint256 _minLockTime, uint256 _maxLockTime) external onlyAdmin() {
        LibSigmaPool.initialize(_vSigmaToken, _minLockTime, _maxLockTime);
    }

    function setFeeTreasury(address _feeTreasury) external onlyAdmin() {
        LibSigmaPool.setFeeTreasury(_feeTreasury);
    }

    function setSigmaRebalancer(address _sigmaRebalancer) external onlyAdmin() {
        LibSigmaPool.setSigmaRebalancer(_sigmaRebalancer);
    }

    function getUserCollateralBalance(address user, uint256 collateralIndex) external view returns (uint256) {
        return LibSigmaPool.getUserCollateralBalance(user, collateralIndex);
    }

    function deposit(uint256 collateralIndex, uint256 amount, uint256 timelock) external {
        LibSigmaPool.deposit(collateralIndex, amount, timelock);
    }

    function redeem(uint256 collateralIndex, uint256 amount) external {
        LibSigmaPool.redeem(collateralIndex, amount);
    }

    function calculateShares(uint256 amount) external view returns (uint256) {
        return LibSigmaPool.calculateShares(amount);
    }

    function calculateAssets(uint256 shares) external view returns (uint256) {
        return LibSigmaPool.calculateAssets(shares);
    }

    function extendLock(uint256 id, uint256 additional_time) external {
        LibSigmaPool.extendLock(id, additional_time);
    }

    function addCollateralToken(address collateralAddress) external onlyAdmin() {
        LibSigmaPool.addCollateralToken(collateralAddress);
    }

    function enableCollateral(uint256 collateralIndex) external onlyAdmin() {
        LibSigmaPool.enableCollateral(collateralIndex);
    }

    function disableCollateral(uint256 collateralIndex) external onlyAdmin() {
        LibSigmaPool.disableCollateral(collateralIndex);
    }

    function setFees(uint256 redemptionFee) external {
        LibSigmaPool.setFees(redemptionFee);
    }

    function getPoolInfo() external view returns (uint256 totalAssets, uint256 totalShares, uint256 minLockTime, uint256 maxLockTime) {
        return LibSigmaPool.getPoolInfo();
    }

    function getUserInfo(address user) external view returns (uint256 totalLocked) {
        return LibSigmaPool.getUserInfo(user);
    }

    function collateralInformation(
        address collateralAddress
    ) external view returns (uint256 index, address collateralAddr, bool isMintPaused, bool isRedeemPaused) {
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