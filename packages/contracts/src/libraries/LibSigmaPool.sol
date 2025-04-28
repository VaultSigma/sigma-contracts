// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {AppStorage, LibAppStorage} from "./LibAppStorage.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IvSigmaToken} from "../interfaces/IvSigmaToken.sol";
import "abdk/ABDKMathQuad.sol";

import "./Constants.sol";

library LibSigmaPool {

    using SafeERC20 for IERC20;
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    bytes32 constant SIGMA_POOL_STORAGE_POSITION =
        bytes32(
            uint256(keccak256("sigma.contracts.pool.storage")) - 1
        ) & ~bytes32(uint256(0xff));

    struct SigmaPoolStorage {
        // IERC20 asset; // Experimenting with a 1 asset pool ??swETH
        address vSigmaToken;
        address feeTreasury;
        address sigmaRebalancer;
        uint256[] rebalancerBalance;

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
    }

    struct Lock {
        uint256 id;
        uint256 amount;
        uint256 timelock;
        uint256 unlockTime;
        uint256 rewards;
    }

    struct CollateralInformation {
        uint256 index;
        address collateralAddr;
        bool isMintPaused;
        bool isRedeemPaused;
    }

    event CollateralAdded(address collateralAddress, uint256 index);
    event FeesSet(uint256 redemptionFee);
    event LockCreated(address user, uint256 id, uint256 amount, uint256 unlockTime);
    event Deposit(uint256 collateralIndex, uint256 amount);
    event Redeem(uint256 collateralIndex, uint256 amount);
    event LockExtended(address user, uint256 id, uint256 timelock, uint256 unlockTime);

    modifier collateralEnabled(uint256 collateralIndex) {
        SigmaPoolStorage storage s = sigmaPoolStorage();
        require(s.isCollateralEnabled[
            s.collateralAddresses[collateralIndex]
        ], "Sigma Pool: collateral is not enabled");
        _;
    }

    function sigmaPoolStorage() internal pure returns (SigmaPoolStorage storage sigmaPool) {
        bytes32 position = SIGMA_POOL_STORAGE_POSITION;
        assembly {
            sigmaPool.slot := position
        }
    }

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

    function allocateToRebalancer(uint256 collateralIndex, uint256 amount) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        IERC20(s.collateralAddresses[collateralIndex]).safeTransfer(s.sigmaRebalancer, amount);
        s.rebalancerBalance[collateralIndex] = s.rebalancerBalance[collateralIndex] + amount;

    }

    // Look into multisig implementation
    function setFeeTreasury(address _feeTreasury) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        require(_feeTreasury != address(0), "SigmaPool: feeTreasury is zero address");

        s.feeTreasury = _feeTreasury;
    }

    function setSigmaRebalancer(address _sigmaRebalancer) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        s.sigmaRebalancer = _sigmaRebalancer;
    }

    function getUserCollateralBalance(address user, uint256 collateralIndex) internal view returns (uint256) {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        return s.userCollateralBalance[user][collateralIndex];
    }

    // Pool is 1:1 ratio of collateral to sigma tokens and collateral. So uni-collateral vault???
    function deposit(uint256 collateralIndex, uint256 amount, uint256 timelock) internal collateralEnabled(collateralIndex) {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        require(amount > 0, "SigmaPool: deposit amount is zero");
        require(timelock > s.MIN_LOCK_TIME, "SigmaPool: timelock is zero");
        require(timelock < s.MAX_LOCK_TIME, "SigmaPool: timelock is greater than 365 days");
        require(s.isMintPaused[collateralIndex] == false, "SigmaPool: minting is paused");

        // Transfer collateral from user to pool
        IERC20(s.collateralAddresses[collateralIndex]).safeTransferFrom(msg.sender, address(this), amount);

        // COuld potentially cause problems as this could become desynced.
        s.userCollateralBalance[msg.sender][collateralIndex] = s.userCollateralBalance[msg.sender][collateralIndex] + amount;
        
        // I don't think we need to create a lock here since it purely incentive based.
        // createLock(amount, timelock);
        uint256 shares = calculateShares(amount);

        s.totalAssets = s.totalAssets + amount;
        s.totalShares = s.totalShares + shares;

        _mintSigma(msg.sender, shares, collateralIndex);

        emit Deposit(collateralIndex, amount);
    }

    function redeem(uint256 collateralIndex, uint256 amount) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        require(amount > 0 && amount <= s.userCollateralBalance[msg.sender][collateralIndex], "SigmaPool: redeem amount is greater than user collateral balance");
        // This is probably safer as it's a balance check.
        require(amount <= IvSigmaToken(s.vSigmaToken).balanceOf(msg.sender), "SigmaPool: redeem amount is greater than user vSigmaToken balance");
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
        s.userCollateralBalance[msg.sender][collateralIndex] = s.userCollateralBalance[msg.sender][collateralIndex] - amount;

        emit Redeem(collateralIndex, collateralAmount);
    }

    function _mintSigma(address to, uint256 amount, uint256 collateralIndex) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        require(to != address(0), "SigmaPool: mint to the zero address");
        require(s.isMintPaused[collateralIndex] == false, "SigmaPool: minting is paused");

        // Remember to set minting and redeeem fees
        // s.totalShares = s.totalShares + amount;
        IvSigmaToken(s.vSigmaToken).mint(to, amount);
    }

    function calculateShares(uint256 amount) internal view returns(uint256) {
        SigmaPoolStorage storage s = sigmaPoolStorage();
        
        if (s.totalShares == 0) {
            return amount;
        }

        return (amount * s.totalShares) / s.totalAssets;
    }

    function calculateAssets(uint256 shares) internal view returns (uint256) {
        SigmaPoolStorage storage s = sigmaPoolStorage();
        
        require(s.totalShares > 0, "SigmaPool: total shares is zero");

        return (shares * s.totalAssets) / s.totalShares;
    }

    function createLock(uint256 amount, uint256 timelock) internal {
        _createLock(amount, timelock);
    }

    function _createLock(uint256 amount, uint256 timelock) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        uint256 unlockTime = block.timestamp + timelock;
        uint256 rewards = calculateTimelockRewards(timelock);
        uint256 id = s.lockIds++;
        s.userLocks[msg.sender].push(Lock(
            id,
            amount, 
            timelock, 
            unlockTime, 
            rewards
        ));

        s.totalLockedPerUser[msg.sender] = s.totalLockedPerUser[msg.sender] + amount;
        emit LockCreated(msg.sender, id, amount, unlockTime);
    }

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

    function calculateTimelockRewards(uint256 timelock) internal returns (uint256) {
        // Experimenting with a simple linear model
        // TODO: Implement a more complex reward model
        // return BASE_REWARD_RATE + (timelock * BOOST_RATE)/MAX_LOCK_TIME;

        uint256 normalizedRewards = normalizeRewards(timelock);
        return BASE_REWARD_RATE + (normalizedRewards * normalizedRewards * BOOST_RATE) / 1e36;
    }

    // Normalize rewards to a 0-1 range. Quadratic reqards. Min 1 week Max 1 year.
    function normalizeRewards(uint256 timelock) internal returns (uint256) {
        // TODO: Implement a more complex reward model
        SigmaPoolStorage storage s = sigmaPoolStorage();

        return ((timelock - s.MIN_LOCK_TIME) * 1e18) / (s.MAX_LOCK_TIME - s.MIN_LOCK_TIME);
    }


    function getPoolInfo() internal view returns (uint256 totalAssets, uint256 totalShares, uint256 minLockTime, uint256 maxLockTime) {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        return (
            s.totalAssets, 
            s.totalShares,
            s.MIN_LOCK_TIME,
            s.MAX_LOCK_TIME
        );
    }

    function getUserInfo(address user) internal view returns (uint256 totalLocked) {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        return (s.totalLockedPerUser[user]);
    }


    function collateralInformation(
        address collateralAddress
    ) internal view returns (uint256 index, address collateralAddr, bool isMintPaused, bool isRedeemPaused) {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        require(s.isCollateralEnabled[collateralAddress], "SigmaPool: collateral is not enabled");

        CollateralInformation memory info = s.collateralInformation[collateralAddress];
        return (info.index, info.collateralAddr, info.isMintPaused, info.isRedeemPaused);
    }

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

        CollateralInformation memory collateralInfo = CollateralInformation(
            index,
            collateralAddress,
            false,
            false
        );

        s.collateralInformation[collateralAddress] = collateralInfo;
        // s.mintingFee.push(0);
        // s.redemptionFee.push(0);

        s.collateralIdx++;

        emit CollateralAdded(collateralAddress, index);

    }

    function enableCollateral(uint256 collateralIndex) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        s.isCollateralEnabled[s.collateralAddresses[collateralIndex]] = true;
    }

    function disableCollateral(uint256 collateralIndex) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        s.isCollateralEnabled[s.collateralAddresses[collateralIndex]] = false;
    }

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
    function setFees(uint256 redemptionFee) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        s.redemptionFee = redemptionFee;

        emit FeesSet(redemptionFee);
    }


    // function setAllocations() internal {
    // }

    // function getAllocations() internal view returns (uint256[] memory allocations) {}
    

}
