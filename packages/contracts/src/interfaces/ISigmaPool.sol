// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

interface ISigmaPool {
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
        bool isMintPaused;
        bool isRedeemPaused;
    }

    // Events
    event CollateralAdded(address collateralAddress, uint256 index);
    event FeesSet(uint256 redemptionFee);
    event LockCreated(address user, uint256 id, uint256 amount, uint256 unlockTime);
    event Deposit(uint256 collateralIndex, uint256 amount);
    event LockExtended(address user, uint256 id, uint256 timelock, uint256 unlockTime);

    // Initialization and Configuration
    function initialize(address _asset, address _vSigmaToken) external;
    function setFeeTreasury(address _feeTreasury) external;
    function setSigmaRebalancer(address _sigmaRebalancer) external;
    function setFees(uint256 redemptionFee) external;

    // Pool Operations
    function deposit(uint256 collateralIndex, uint256 amount, uint256 timelock) external;
    function extendLock(uint256 id, uint256 additional_time) external;
    function addCollateralToken(address collateralAddress) external;

    // View Functions
    function collateralInformation(address collateralAddress) external view returns (CollateralInformation memory);
    function getTotalAssets() external view returns (uint256);
    function getTotalShares() external view returns (uint256);
    function getLockInfo(address user, uint256 id) external view returns (
        uint256 amount,
        uint256 timelock,
        uint256 unlockTime,
        uint256 rewards
    );
    function getUserTotalLocked(address user) external view returns (uint256);
    function getCollateralAddresses() external view returns (address[] memory);
    function isCollateralEnabled(address collateralAddress) external view returns (bool);
    function isMintPaused(uint256 collateralIndex) external view returns (bool);
    function isRedeemPaused(uint256 collateralIndex) external view returns (bool);
    function collateralExists(address collateralAddress) external view returns (bool);
} 