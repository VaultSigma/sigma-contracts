// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {LibSigmaPool} from "../libraries/LibSigmaPool.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

/**
 * @title SigmaPoolFacet
 * @notice Facet for managing the Sigma pool operations
 * @dev Handles deposits, redemptions, collateral management, and rebalancing
 */
contract SigmaPoolFacet is Modifiers {
    /**
     * @notice Emitted when a user deposits collateral
     * @param user Address of the depositor
     * @param collateralIndex Index of the collateral token
     * @param amount Amount of collateral deposited
     * @param shares Amount of shares minted
     */
    event Deposit(address indexed user, uint256 collateralIndex, uint256 amount, uint256 shares);

    /**
     * @notice Emitted when a lock is created
     * @param user Address of the user creating the lock
     * @param id Unique identifier of the lock
     * @param amount Amount of tokens locked
     * @param unlockTime Timestamp when the lock expires
     */
    event LockCreated(address indexed user, uint256 id, uint256 amount, uint256 unlockTime);

    /**
     * @notice Emitted when a lock is extended
     * @param user Address of the user extending the lock
     * @param id Unique identifier of the lock
     * @param timelock New lock duration
     * @param unlockTime New unlock timestamp
     */
    event LockExtended(address indexed user, uint256 id, uint256 timelock, uint256 unlockTime);

    /**
     * @notice Emitted when a new collateral token is added
     * @param collateralAddress Address of the collateral token
     * @param index Index assigned to the collateral
     */
    event CollateralAdded(address indexed collateralAddress, uint256 index);

    /**
     * @notice Emitted when fees are updated
     * @param redemptionFee New redemption fee
     */
    event FeesSet(uint256 redemptionFee);

    /**
     * @notice Initializes the pool with basic parameters
     * @dev Only callable by admin
     * @param _vSigmaToken Address of the vSigma token
     * @param _minLockTime Minimum lock time in seconds
     * @param _maxLockTime Maximum lock time in seconds
     */
    function initialize(address _vSigmaToken, uint256 _minLockTime, uint256 _maxLockTime) external onlyAdmin {
        LibSigmaPool.initialize(_vSigmaToken, _minLockTime, _maxLockTime);
    }

    /**
     * @notice Sets the fee treasury address
     * @dev Only callable by admin
     * @param _feeTreasury Address of the fee treasury
     */
    function setFeeTreasury(address _feeTreasury) external onlyAdmin {
        LibSigmaPool.setFeeTreasury(_feeTreasury);
    }

    /**
     * @notice Sets the rebalancer address
     * @dev Only callable by admin
     * @param _sigmaRebalancer Address of the rebalancer
     */
    function setSigmaRebalancer(address _sigmaRebalancer) external onlyAdmin {
        LibSigmaPool.setSigmaRebalancer(_sigmaRebalancer);
    }

    /**
     * @notice Gets a user's collateral balance for a specific token
     * @param user Address of the user
     * @param collateralIndex Index of the collateral token
     * @return uint256 Amount of collateral held by the user
     */
    function getUserCollateralBalance(address user, uint256 collateralIndex) external view returns (uint256) {
        return LibSigmaPool.getUserCollateralBalance(user, collateralIndex);
    }

    /**
     * @notice Deposits collateral into the pool
     * @param collateralIndex Index of the collateral token
     * @param amount Amount of collateral to deposit
     * @param timelock Duration to lock the collateral
     */
    function deposit(uint256 collateralIndex, uint256 amount, uint256 timelock) external {
        LibSigmaPool.deposit(collateralIndex, amount, timelock);
    }

    /**
     * @notice Redeems collateral from the pool
     * @param collateralIndex Index of the collateral token
     * @param amount Amount of collateral to redeem
     */
    function redeem(uint256 collateralIndex, uint256 amount) external {
        LibSigmaPool.redeem(collateralIndex, amount);
    }

    /**
     * @notice Calculates shares for a given amount of collateral
     * @param amount Amount of collateral
     * @return uint256 Number of shares
     */
    function calculateShares(uint256 amount) external view returns (uint256) {
        return LibSigmaPool.calculateShares(amount);
    }

    /**
     * @notice Calculates collateral amount for a given number of shares
     * @param shares Number of shares
     * @return uint256 Amount of collateral
     */
    function calculateAssets(uint256 shares) external view returns (uint256) {
        return LibSigmaPool.calculateAssets(shares);
    }

    /**
     * @notice Extends the duration of a lock
     * @param id Lock identifier
     * @param additional_time Additional time to lock
     */
    function extendLock(uint256 id, uint256 additional_time) external {
        LibSigmaPool.extendLock(id, additional_time);
    }

    /**
     * @notice Adds a new collateral token
     * @dev Only callable by admin
     * @param collateralAddress Address of the collateral token
     */
    function addCollateralToken(address collateralAddress) external onlyAdmin {
        LibSigmaPool.addCollateralToken(collateralAddress);
    }

    /**
     * @notice Enables a collateral token
     * @dev Only callable by admin
     * @param collateralIndex Index of the collateral token
     */
    function enableCollateral(uint256 collateralIndex) external onlyAdmin {
        LibSigmaPool.enableCollateral(collateralIndex);
    }

    /**
     * @notice Disables a collateral token
     * @dev Only callable by admin
     * @param collateralIndex Index of the collateral token
     */
    function disableCollateral(uint256 collateralIndex) external onlyAdmin {
        LibSigmaPool.disableCollateral(collateralIndex);
    }

    /**
     * @notice Sets the redemption fee
     * @param redemptionFee New redemption fee
     */
    function setFees(uint256 redemptionFee) external {
        LibSigmaPool.setFees(redemptionFee);
    }

    /**
     * @notice Gets pool information
     * @return totalAssets Total assets in the pool
     * @return totalShares Total shares in the pool
     * @return minLockTime Minimum lock time
     * @return maxLockTime Maximum lock time
     */
    function getPoolInfo()
        external
        view
        returns (uint256 totalAssets, uint256 totalShares, uint256 minLockTime, uint256 maxLockTime)
    {
        return LibSigmaPool.getPoolInfo();
    }

    /**
     * @notice Gets user information
     * @param user Address of the user
     * @return totalLocked Total amount locked by the user
     */
    function getUserInfo(address user) external view returns (uint256 totalLocked) {
        return LibSigmaPool.getUserInfo(user);
    }

    /**
     * @notice Gets collateral token information
     * @param collateralAddress Address of the collateral token
     * @return index Index of the collateral
     * @return collateralAddr Address of the collateral token
     * @return isMintPaused Whether minting is paused
     * @return isRedeemPaused Whether redemption is paused
     */
    function collateralInformation(address collateralAddress)
        external
        view
        returns (uint256 index, address collateralAddr, bool isMintPaused, bool isRedeemPaused)
    {
        return LibSigmaPool.collateralInformation(collateralAddress);
    }

    /**
     * @notice Gets total assets in the pool
     * @return uint256 Total assets
     */
    function getTotalAssets() external view returns (uint256) {
        return LibSigmaPool.sigmaPoolStorage().totalAssets;
    }

    /**
     * @notice Gets total shares in the pool
     * @return uint256 Total shares
     */
    function getTotalShares() external view returns (uint256) {
        return LibSigmaPool.sigmaPoolStorage().totalShares;
    }

    /**
     * @notice Gets lock information
     * @param user Address of the user
     * @param id Lock identifier
     * @return amount Amount locked
     * @return timelock Lock duration
     * @return unlockTime Unlock timestamp
     * @return rewards Rewards earned
     */
    function getLockInfo(address user, uint256 id)
        external
        view
        returns (uint256 amount, uint256 timelock, uint256 unlockTime, uint256 rewards)
    {
        LibSigmaPool.Lock memory lock = LibSigmaPool.sigmaPoolStorage().userLocks[user][id];
        return (lock.amount, lock.timelock, lock.unlockTime, lock.rewards);
    }

    /**
     * @notice Gets total amount locked by a user
     * @param user Address of the user
     * @return uint256 Total amount locked
     */
    function getUserTotalLocked(address user) external view returns (uint256) {
        return LibSigmaPool.sigmaPoolStorage().totalLockedPerUser[user];
    }

    /**
     * @notice Gets list of collateral token addresses
     * @return address[] Array of collateral token addresses
     */
    function getCollateralAddresses() external view returns (address[] memory) {
        return LibSigmaPool.sigmaPoolStorage().collateralAddresses;
    }

    /**
     * @notice Checks if a collateral token is enabled
     * @param collateralAddress Address of the collateral token
     * @return bool Whether the collateral is enabled
     */
    function isCollateralEnabled(address collateralAddress) external view returns (bool) {
        return LibSigmaPool.sigmaPoolStorage().isCollateralEnabled[collateralAddress];
    }

    /**
     * @notice Checks if minting is paused for a collateral token
     * @param collateralIndex Index of the collateral token
     * @return bool Whether minting is paused
     */
    function isMintPaused(uint256 collateralIndex) external view returns (bool) {
        return LibSigmaPool.sigmaPoolStorage().isMintPaused[collateralIndex];
    }

    /**
     * @notice Checks if redemption is paused for a collateral token
     * @param collateralIndex Index of the collateral token
     * @return bool Whether redemption is paused
     */
    function isRedeemPaused(uint256 collateralIndex) external view returns (bool) {
        return LibSigmaPool.sigmaPoolStorage().isRedeemPaused[collateralIndex];
    }

    /**
     * @notice Initializes rebalancer balance for a collateral token
     * @param collateralIndex Index of the collateral token
     */
    function initRebalancerBalance(uint256 collateralIndex) external {
        LibSigmaPool.initRebalancerBalance(collateralIndex);
    }

    /**
     * @notice Allocates funds to the rebalancer
     * @param collateralIndex Index of the collateral token
     * @param amount Amount to allocate
     */
    function allocToRebalancer(uint256 collateralIndex, uint256 amount) external {
        LibSigmaPool.allocToRebalancer(collateralIndex, amount);
    }

    /**
     * @notice Gets rebalancer balance for a collateral token
     * @param collateralIndex Index of the collateral token
     * @return uint256 Rebalancer balance
     */
    function getRebalancerBalance(uint256 collateralIndex) external view returns (uint256) {
        return LibSigmaPool.getRebalancerBalance(collateralIndex);
    }

    /**
     * @notice Executes a rebalance operation
     * @param params Rebalance parameters
     */
    function rebalance(LibSigmaPool.RebalanceParams memory params) external {
        LibSigmaPool.rebalance(params);
    }
}
