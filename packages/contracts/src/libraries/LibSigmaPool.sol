// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {AppStorage, LibAppStorage} from "./LibAppStorage.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IvSigmaToken} from "../interfaces/IvSigmaToken.sol";
import {ISigmaRebalancer} from "../interfaces/ISigmaRebalancer.sol";
import "abdk/ABDKMathQuad.sol";

import "./Constants.sol";

/**
 * @title LibSigmaPool
 * @notice Library for managing the Sigma pool operations
 * @dev Handles deposits, redemptions, locks, and rebalancing operations
 */
library LibSigmaPool {
    using SafeERC20 for IERC20;
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    /// @notice Storage slot for the Sigma pool
    bytes32 constant SIGMA_POOL_STORAGE_POSITION =
        bytes32(uint256(keccak256("sigma.contracts.pool.storage")) - 1) & ~bytes32(uint256(0xff));

    /**
     * @notice Structure to store Sigma pool state
     * @dev Contains all pool-related state variables and mappings
     */
    struct SigmaPoolStorage {
        // IERC20 asset; // Experimenting with a 1 asset pool ??swETH
        address vSigmaToken;
        address feeTreasury;
        address sigmaRebalancer;
        address dexRouter;
        uint256 redemptionFee;
        uint256 lockIds;
        uint256 totalAssets;
        uint256 totalShares;
        uint256 MIN_LOCK_TIME;
        uint256 MAX_LOCK_TIME;
        uint256 BASE_REWARD_RATE;
        uint256 BOOST_RATE;
        // uint256[] mintingFee;
        // uint256[] redemptionFee;
        uint256 collateralIdx;
        address[] collateralAddresses;
        // string[] collateralSymbols;
        bool[] isMintPaused;
        bool[] isRedeemPaused;
        mapping(address user => Lock[] locks) userLocks;
        mapping(address user => mapping(uint256 collateralIndex => uint256 amount)) userCollateralBalance;
        mapping(address user => uint256 value) totalLockedPerUser;
        mapping(address collateralAddress => bool isEnabled) isCollateralEnabled;
        mapping(address collateralAddress => uint256 collateralIndex) collateralIndex;
        mapping(address collateralAddress => CollateralInformation collateralInformation) collateralInformation;
        mapping(uint256 collateralIndex => uint256 rebalancerBalance) rebalancerBalance;
    }

    /**
     * @notice Structure to store user lock information
     * @dev Contains lock details including amount, timelock, and rewards
     */
    struct Lock {
        uint256 id;
        uint256 amount;
        uint256 timelock;
        uint256 unlockTime;
        uint256 rewards;
    }

    /**
     * @notice Structure to store collateral information
     * @dev Contains collateral details including index and pause status
     */
    struct CollateralInformation {
        uint256 index;
        address collateralAddr;
        bool isMintPaused;
        bool isRedeemPaused;
    }

    /**
     * @notice Structure to store rebalance parameters
     * @dev Contains all parameters needed for rebalancing operations
     */
    struct RebalanceParams {
        address base;
        address quote;
        uint256 poolIdx;
        bool isBuy;
        bool inBaseQty;
        uint256 qty;
        uint256 tip;
        uint256 limitPrice;
        uint256 minOut;
        uint256 reserveFlags;
        uint256 collateralIndex;
    }

    /**
     * @notice Emitted when a new collateral is added to the pool
     * @param collateralAddress Address of the collateral token
     * @param index Index of the collateral in the pool
     */
    event CollateralAdded(address collateralAddress, uint256 index);

    /**
     * @notice Emitted when pool fees are updated
     * @param redemptionFee New redemption fee value
     */
    event FeesSet(uint256 redemptionFee);

    /**
     * @notice Emitted when a new lock is created
     * @param user Address of the user creating the lock
     * @param id Lock ID
     * @param amount Amount locked
     * @param unlockTime Time when the lock can be unlocked
     */
    event LockCreated(address user, uint256 id, uint256 amount, uint256 unlockTime);

    /**
     * @notice Emitted when a deposit is made
     * @param collateralIndex Index of the collateral token
     * @param amount Amount deposited
     */
    event Deposit(uint256 collateralIndex, uint256 amount);

    /**
     * @notice Emitted when a redemption is made
     * @param collateralIndex Index of the collateral token
     * @param amount Amount redeemed
     */
    event Redeem(uint256 collateralIndex, uint256 amount);

    /**
     * @notice Emitted when a lock is extended
     * @param user Address of the user extending the lock
     * @param id Lock ID
     * @param timelock New timelock duration
     * @param unlockTime New unlock time
     */
    event LockExtended(address user, uint256 id, uint256 timelock, uint256 unlockTime);

    /**
     * @notice Emitted when a rebalance operation is executed
     * @param base Base token address
     * @param quote Quote token address
     * @param poolIdx Pool index
     * @param isBuy Whether the operation is a buy
     * @param inBaseQty Whether the quantity is in base token
     * @param qty Quantity involved in the rebalance
     */
    event Rebalance(address base, address quote, uint256 poolIdx, bool isBuy, bool inBaseQty, uint256 qty);

    /**
     * @notice Modifier to check if collateral is enabled
     * @dev Reverts if collateral is not enabled
     * @param collateralIndex Index of the collateral to check
     */
    modifier collateralEnabled(uint256 collateralIndex) {
        SigmaPoolStorage storage s = sigmaPoolStorage();
        require(s.isCollateralEnabled[s.collateralAddresses[collateralIndex]], "Sigma Pool: collateral is not enabled");
        _;
    }

    /**
     * @notice Returns the Sigma pool storage
     * @return sigmaPool Storage struct for the Sigma pool
     */
    function sigmaPoolStorage() internal pure returns (SigmaPoolStorage storage sigmaPool) {
        bytes32 position = SIGMA_POOL_STORAGE_POSITION;
        assembly {
            sigmaPool.slot := position
        }
    }

    /**
     * @notice Initializes the Sigma pool
     * @dev Sets up initial pool parameters
     * @param _vSigmaToken Address of the vSigma token
     * @param _minLockTime Minimum lock time
     * @param _maxLockTime Maximum lock time
     */
    function initialize(address _vSigmaToken, uint256 _minLockTime, uint256 _maxLockTime) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        // require(address(s.asset) == address(0), "SigmaPool: already initialized");
        require(_vSigmaToken != address(0), "SigmaPool: vSigmaToken is zero address");
        require(_maxLockTime > _minLockTime, "SigmaPool: maxLockTime is less than minLockTime");

        s.MIN_LOCK_TIME = _minLockTime;
        s.MAX_LOCK_TIME = _maxLockTime;

        // s.asset = IERC20(_asset);
        s.vSigmaToken = _vSigmaToken;
    }

    // Look into multisig implementation
    /**
     * @notice Sets the fee treasury address
     * @dev Only callable by admin
     * @param _feeTreasury Address of the fee treasury
     */
    function setFeeTreasury(address _feeTreasury) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        require(_feeTreasury != address(0), "SigmaPool: feeTreasury is zero address");

        s.feeTreasury = _feeTreasury;
    }

    /**
     * @notice Sets the Sigma rebalancer address
     * @param _sigmaRebalancer Address of the Sigma rebalancer
     */
    function setSigmaRebalancer(address _sigmaRebalancer) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        s.sigmaRebalancer = _sigmaRebalancer;
    }

    /**
     * @notice Gets the user's collateral balance
     * @param user Address of the user
     * @param collateralIndex Index of the collateral
     * @return uint256 User's collateral balance
     */
    function getUserCollateralBalance(address user, uint256 collateralIndex) internal view returns (uint256) {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        return s.userCollateralBalance[user][collateralIndex];
    }

    // Pool is 1:1 ratio of collateral to sigma tokens and collateral. So uni-collateral vault???
    /**
     * @notice Deposits collateral into the pool
     * @dev Creates a lock and mints vSigma tokens
     * @param collateralIndex Index of the collateral
     * @param amount Amount to deposit
     * @param timelock Duration of the lock
     */
    function deposit(uint256 collateralIndex, uint256 amount, uint256 timelock)
        internal
        collateralEnabled(collateralIndex)
    {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        require(amount > 0, "SigmaPool: deposit amount is zero");
        require(timelock > s.MIN_LOCK_TIME, "SigmaPool: timelock is zero");
        require(timelock < s.MAX_LOCK_TIME, "SigmaPool: timelock is greater than 365 days");
        require(s.isMintPaused[collateralIndex] == false, "SigmaPool: minting is paused");

        // Transfer collateral from user to pool
        IERC20(s.collateralAddresses[collateralIndex]).safeTransferFrom(msg.sender, address(this), amount);

        // COuld potentially cause problems as this could become desynced.
        s.userCollateralBalance[msg.sender][collateralIndex] =
            s.userCollateralBalance[msg.sender][collateralIndex] + amount;

        // I don't think we need to create a lock here since it purely incentive based.
        // createLock(amount, timelock);
        uint256 shares = calculateShares(amount);

        s.totalAssets = s.totalAssets + amount;
        s.totalShares = s.totalShares + shares;

        _mintSigma(msg.sender, shares, collateralIndex);

        emit Deposit(collateralIndex, amount);
    }

    /**
     * @notice Redeems collateral from the pool
     * @dev Burns vSigma tokens and transfers collateral
     * @param collateralIndex Index of the collateral
     * @param amount Amount to redeem
     */
    function redeem(uint256 collateralIndex, uint256 amount) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        require(
            amount > 0 && amount <= s.userCollateralBalance[msg.sender][collateralIndex],
            "SigmaPool: redeem amount is greater than user collateral balance"
        );
        // This is probably safer as it's a balance check.
        require(
            amount <= IvSigmaToken(s.vSigmaToken).balanceOf(msg.sender),
            "SigmaPool: redeem amount is greater than user vSigmaToken balance"
        );
        require(s.isRedeemPaused[collateralIndex] == false, "SigmaPool: redeeming is paused");

        // Verify time lock has passed
        // This is a bit of a hack, but it's the only way to do it.
        Lock[] memory locks = s.userLocks[msg.sender];
        for (uint256 i = 0; i < locks.length; i++) {
            require(block.timestamp >= locks[i].unlockTime, "SigmaPool: time lock has not passed");
        }

        // require(block.timestamp >= s.userLocks[msg.sender][lockIndex].unlockTime, "SigmaPool: time lock has not passed");

        uint256 collateralAmount = calculateAssets(amount);
        s.totalAssets = s.totalAssets - collateralAmount;
        s.totalShares = s.totalShares - amount;

        // Burn vSigma tokens; Fix this
        IERC20(s.vSigmaToken).safeTransferFrom(msg.sender, address(this), amount);
        // IvSigmaToken(s.vSigmaToken).burnFrom(address(this), amount);

        // // Transfer collateral from pool to user
        IERC20(s.collateralAddresses[collateralIndex]).safeTransfer(msg.sender, collateralAmount);

        // Update collateral balance
        s.userCollateralBalance[msg.sender][collateralIndex] =
            s.userCollateralBalance[msg.sender][collateralIndex] - amount;

        emit Redeem(collateralIndex, collateralAmount);
    }

    /**
     * @notice Mints vSigma tokens
     * @param to Address to mint tokens to
     * @param amount Amount to mint
     * @param collateralIndex Index of the collateral
     */
    function _mintSigma(address to, uint256 amount, uint256 collateralIndex) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        require(to != address(0), "SigmaPool: mint to the zero address");
        require(s.isMintPaused[collateralIndex] == false, "SigmaPool: minting is paused");

        // Remember to set minting and redeeem fees
        // s.totalShares = s.totalShares + amount;
        IvSigmaToken(s.vSigmaToken).mint(to, amount);
    }

    /**
     * @notice Calculates shares for a given amount
     * @param amount Amount to calculate shares for
     * @return uint256 Number of shares
     */
    function calculateShares(uint256 amount) internal view returns (uint256) {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        if (s.totalShares == 0) {
            return amount;
        }

        return (amount * s.totalShares) / s.totalAssets;
    }

    /**
     * @notice Calculates assets for a given number of shares
     * @param shares Number of shares
     * @return uint256 Amount of assets
     */
    function calculateAssets(uint256 shares) internal view returns (uint256) {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        require(s.totalShares > 0, "SigmaPool: total shares is zero");

        return (shares * s.totalAssets) / s.totalShares;
    }

    /**
     * @notice Creates a new lock
     * @param amount Amount to lock
     * @param timelock Duration of the lock
     */
    function createLock(uint256 amount, uint256 timelock) internal {
        _createLock(amount, timelock);
    }

    /**
     * @notice Internal function to create a lock
     * @param amount Amount to lock
     * @param timelock Duration of the lock
     */
    function _createLock(uint256 amount, uint256 timelock) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        uint256 unlockTime = block.timestamp + timelock;
        uint256 rewards = calculateTimelockRewards(timelock);
        uint256 id = s.lockIds++;
        s.userLocks[msg.sender].push(Lock(id, amount, timelock, unlockTime, rewards));

        s.totalLockedPerUser[msg.sender] = s.totalLockedPerUser[msg.sender] + amount;
        emit LockCreated(msg.sender, id, amount, unlockTime);
    }

    /**
     * @notice Extends an existing lock
     * @param id Lock ID
     * @param additional_time Additional time to extend the lock
     */
    function extendLock(uint256 id, uint256 additional_time) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        require(s.userLocks[msg.sender].length > 0, "SigmaPool: no locks found");
        require(id < s.userLocks[msg.sender].length, "SigmaPool: lock not found");
        require(additional_time > 0, "SigmaPool: additional time is zero");
        require(additional_time < MAX_LOCK_TIME, "SigmaPool: additional time is greater than 365 days");

        Lock storage l = s.userLocks[msg.sender][id];
        l.timelock = l.timelock + additional_time;
        l.unlockTime = l.unlockTime + additional_time;
        l.rewards = calculateTimelockRewards(l.timelock);

        emit LockExtended(msg.sender, id, l.timelock, l.unlockTime);
    }

    /**
     * @notice Calculates rewards for a timelock
     * @param timelock Duration of the lock
     * @return uint256 Calculated rewards
     */
    function calculateTimelockRewards(uint256 timelock) internal returns (uint256) {
        // Experimenting with a simple linear model
        // TODO: Implement a more complex reward model
        // return BASE_REWARD_RATE + (timelock * BOOST_RATE)/MAX_LOCK_TIME;

        uint256 normalizedRewards = normalizeRewards(timelock);
        return BASE_REWARD_RATE + (normalizedRewards * normalizedRewards * BOOST_RATE) / 1e36;
    }

    /**
     * @notice Normalizes rewards to a 0-1 range
     * @param timelock Duration of the lock
     * @return uint256 Normalized rewards
     */
    function normalizeRewards(uint256 timelock) internal returns (uint256) {
        // TODO: Implement a more complex reward model
        SigmaPoolStorage storage s = sigmaPoolStorage();

        return ((timelock - s.MIN_LOCK_TIME) * 1e18) / (s.MAX_LOCK_TIME - s.MIN_LOCK_TIME);
    }

    /**
     * @notice Gets pool information
     * @return totalAssets Total assets in the pool
     * @return totalShares Total shares in the pool
     * @return minLockTime Minimum lock time
     * @return maxLockTime Maximum lock time
     */
    function getPoolInfo()
        internal
        view
        returns (uint256 totalAssets, uint256 totalShares, uint256 minLockTime, uint256 maxLockTime)
    {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        return (s.totalAssets, s.totalShares, s.MIN_LOCK_TIME, s.MAX_LOCK_TIME);
    }

    /**
     * @notice Gets user information
     * @param user User address
     * @return totalLocked Total amount locked by user
     */
    function getUserInfo(address user) internal view returns (uint256 totalLocked) {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        return (s.totalLockedPerUser[user]);
    }

    /**
     * @notice Gets collateral information
     * @param collateralAddress Address of the collateral
     * @return index Collateral index
     * @return collateralAddr Collateral address
     * @return isMintPaused Whether minting is paused
     * @return isRedeemPaused Whether redeeming is paused
     */
    function collateralInformation(address collateralAddress)
        internal
        view
        returns (uint256 index, address collateralAddr, bool isMintPaused, bool isRedeemPaused)
    {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        require(s.isCollateralEnabled[collateralAddress], "SigmaPool: collateral is not enabled");

        CollateralInformation memory info = s.collateralInformation[collateralAddress];
        return (info.index, info.collateralAddr, info.isMintPaused, info.isRedeemPaused);
    }

    // rswETH = 0x18d33689AE5d02649a859A1CF16c9f0563975258
    /**
     * @notice Adds a new collateral token
     * @param collateralAddress Address of the collateral token
     */
    function addCollateralToken(address collateralAddress) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        // require(s.collateralIndex[collateralAddress] == 0, "SigmaPool: collateral already exists");

        uint256 index = s.collateralIdx;

        s.collateralAddresses.push(collateralAddress);
        s.collateralIndex[collateralAddress] = index;
        s.isCollateralEnabled[collateralAddress] = false;
        // s.collateralSymbols.push(ERC20(collateralAddress).symbol());
        s.isMintPaused.push(false);
        s.isRedeemPaused.push(false);

        CollateralInformation memory collateralInfo = CollateralInformation(index, collateralAddress, false, false);

        s.collateralInformation[collateralAddress] = collateralInfo;
        // s.mintingFee.push(0);
        // s.redemptionFee.push(0);

        s.collateralIdx++;

        emit CollateralAdded(collateralAddress, index);
    }

    /**
     * @notice Enables a collateral token
     * @param collateralIndex Index of the collateral
     */
    function enableCollateral(uint256 collateralIndex) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        s.isCollateralEnabled[s.collateralAddresses[collateralIndex]] = true;
    }

    /**
     * @notice Disables a collateral token
     * @param collateralIndex Index of the collateral
     */
    function disableCollateral(uint256 collateralIndex) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        s.isCollateralEnabled[s.collateralAddresses[collateralIndex]] = false;
    }

    /**
     * @notice Checks if a collateral exists
     * @param collateralAddress Address of the collateral
     * @return bool Whether the collateral exists
     */
    function collateralExists(address collateralAddress) internal view returns (bool) {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        address[] memory collateralAddresses = s.collateralAddresses;

        for (uint256 i = 0; i < collateralAddresses.length; i++) {
            if (collateralAddresses[i] == collateralAddress) {
                return true;
            }
        }

        return false;
    }

    // Minting fees will be Zero(0). Redemption fees will be 10% of profits.
    /**
     * @notice Sets pool fees
     * @param redemptionFee New redemption fee
     */
    function setFees(uint256 redemptionFee) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        s.redemptionFee = redemptionFee;

        emit FeesSet(redemptionFee);
    }

    // Testing a new model here. It would be nice if the rebalancer could call this. I dont want the rebalancer handling funds.

    /**
     * @notice Initializes rebalancer balance
     * @param collateralIndex Index of the collateral
     */
    function initRebalancerBalance(uint256 collateralIndex) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        s.rebalancerBalance[collateralIndex] = 0;
    }

    /**
     * @notice Allocates funds to rebalancer
     * @param collateralIndex Index of the collateral
     * @param amount Amount to allocate
     */
    function allocToRebalancer(uint256 collateralIndex, uint256 amount) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        s.rebalancerBalance[collateralIndex] = s.rebalancerBalance[collateralIndex] + amount;
        IERC20(s.collateralAddresses[collateralIndex]).safeTransfer(s.sigmaRebalancer, amount);
    }

    /**
     * @notice Gets rebalancer balance
     * @param collateralIndex Index of the collateral
     * @return uint256 Rebalancer balance
     */
    function getRebalancerBalance(uint256 collateralIndex) internal view returns (uint256) {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        return s.rebalancerBalance[collateralIndex];
    }

    /**
     * @notice Sets the strategy router
     */
    function setStrategyRouter() internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        // Get the rebalancer address from storage
        address rebalancer = s.sigmaRebalancer;
        require(rebalancer != address(0), "SigmaPool: rebalancer not set");

        // Call getDexRouter on the rebalancer contract instance
        address _dexRouter = ISigmaRebalancer(rebalancer).getDexRouter();
        s.dexRouter = _dexRouter;
    }

    /**
     * @notice Gets the DEX router address
     * @return address DEX router address
     */
    function getDexRouter() internal view returns (address) {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        return s.dexRouter;
    }

    // Running into stack too deep errors. Need to refactor.
    /**
     * @notice Executes a rebalance operation
     * @param params Rebalance parameters
     */
    function rebalance(RebalanceParams memory params) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        require(s.sigmaRebalancer != address(0), "SigmaPool: sigma rebalancer not set");
        require(s.rebalancerBalance[params.collateralIndex] > 0, "SigmaPool: insufficient balance in rebalancer");

        // TODO: Check if this is correct. Need to check precision
        uint128 qty = uint128(params.qty);
        uint16 tip = uint16(params.tip);
        uint128 limitPrice = uint128(params.limitPrice);
        uint128 minOut = uint128(params.minOut);
        uint8 reserveFlags = uint8(params.reserveFlags);

        bytes memory data = abi.encode(
            params.base,
            params.quote,
            params.poolIdx,
            params.isBuy,
            params.inBaseQty,
            qty,
            tip,
            limitPrice,
            minOut,
            reserveFlags
        );

        ISigmaRebalancer(s.sigmaRebalancer).rebalance(data);

        // emit Rebalance(
        //     _base,
        //     _quote,
        //     _poolIdx,
        //     _isBuy,
        //     _inBaseQty,
        //     qty
        // );
    }
}
