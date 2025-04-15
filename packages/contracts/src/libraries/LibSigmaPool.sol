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
        // IERC20 asset; // Experimenting with a 2 asset pool
        address vSigmaToken;
        uint256 lockIds;
        uint256 totalAssets; 
        uint256 totalShares;
        uint256[] mintingFee;
        uint256[] redemptionFee;
        address[] collateralAddresses;
        string[] collateralSymbols;
        bool[] isMintPaused;
        bool[] isRedeemPaused;
        mapping(address user => Lock[] locks) userLocks;
        mapping(address user => uint256 value) totalLockedPerUser;
        mapping(address collateralAddress => bool isEnabled) isCollateralEnabled;
        mapping(address collateralAddress => uint256 collateralIndex) collateralIndex;
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
        address collateralAddress;
        string symbol;
        uint256 mintingFee;
        uint256 redemptionFee;
        bool isMintPaused;
        bool isRedeemPaused;
    }

    event CollateralAdded(address collateralAddress, uint256 index);
    event FeesSet(uint256 collateralIndex, uint256 mintingFee, uint256 redemptionFee);
    event LockCreated(address user, uint256 id, uint256 amount, uint256 unlockTime);
    event Deposit(uint256 collateralIndex, uint256 amount);
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

    function initialize(address _asset, address _vSigmaToken) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        // require(address(s.asset) == address(0), "SigmaPool: already initialized");
        require(_asset != address(0), "SigmaPool: asset is zero address");

        // s.asset = IERC20(_asset);
        s.vSigmaToken = _vSigmaToken;
    }

    function deposit(uint256 collateralIndex, uint256 amount, uint256 timelock) internal collateralEnabled(collateralIndex) {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        require(amount > 0, "SigmaPool: deposit amount is zero");
        require(timelock > MIN_LOCK_TIME, "SigmaPool: timelock is zero");
        require(timelock < MAX_LOCK_TIME, "SigmaPool: timelock is greater than 365 days");
        require(s.isMintPaused[collateralIndex] == false, "SigmaPool: minting is paused");

        // Transfer collateral from user to pool
        IERC20(s.collateralAddresses[collateralIndex]).safeTransferFrom(msg.sender, address(this), amount);
        
        // s.totalAssets[collateralIndex] = s.totalAssets[collateralIndex].add(amount);
        createLock(amount, timelock);
        uint256 shares = calculateShares(amount, s.totalAssets, s.totalShares);

        s.totalAssets = s.totalAssets + amount;
        s.totalShares = s.totalShares + shares;

        _mintSigma(msg.sender, shares, collateralIndex);

        emit Deposit(collateralIndex, amount);
    }

    function redeem() internal {}

    function _mintSigma(address to, uint256 amount, uint256 collateralIndex) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        require(to != address(0), "SigmaPool: mint to the zero address");
        require(s.isMintPaused[collateralIndex] == false, "SigmaPool: minting is paused");

        // Remember to set minting and redeeem fees
        s.totalShares = s.totalShares + amount;
        IvSigmaToken(s.vSigmaToken).mint(to, amount);
    }

    function calculateShares(uint256 amount, uint256 totalAssets, uint256 totalShares) internal returns(uint256) {
        SigmaPoolStorage storage s = sigmaPoolStorage();
        
        if (s.totalShares == 0) {
            return amount;
        }

        return (amount * totalShares)/ totalAssets;
    }

    function createLock(uint256 amount, uint256 timelock) internal {
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

    function calculateTimelockRewards(uint256 timelock) internal pure returns (uint256) {
        // Experimenting with a simple linear model
        // TODO: Implement a more complex reward model
        return BASE_REWARD_RATE + (timelock * BOOST_RATE)/MAX_LOCK_TIME;
    }


    function collateralInformation(
        address collateralAddress
    ) internal view returns (CollateralInformation memory collateralInfo) {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        require(s.isCollateralEnabled[collateralAddress], "SigmaPool: collateral is not enabled");

        uint256 index = s.collateralIndex[collateralAddress];

        collateralInfo = CollateralInformation(
            index,
            collateralAddress,
            s.collateralSymbols[index],
            s.mintingFee[index],
            s.redemptionFee[index],
            s.isMintPaused[index],
            s.isRedeemPaused[index]
        );
    }

    function addCollateralToken(address collateralAddress) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        require(s.collateralIndex[collateralAddress] == 0, "SigmaPool: collateral already exists");

        uint256 index = s.collateralAddresses.length;

        s.collateralAddresses.push(collateralAddress);
        s.collateralIndex[collateralAddress] = index;
        s.isCollateralEnabled[collateralAddress] = false;
        s.collateralSymbols.push(ERC20(collateralAddress).symbol());
        s.mintingFee.push(0);
        s.redemptionFee.push(0);

        emit CollateralAdded(collateralAddress, index);

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

    function setFees(uint256 collateralIndex, uint256 mintingFee, uint256 redemptionFee) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        s.mintingFee[collateralIndex] = mintingFee;
        s.redemptionFee[collateralIndex] = redemptionFee;

        emit FeesSet(collateralIndex, mintingFee, redemptionFee);
    }
    

}
