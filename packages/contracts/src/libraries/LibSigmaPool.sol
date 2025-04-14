// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {AppStorage, LibAppStorage} from "./LibAppStorage.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

library LibSigmaPool {

    using SafeERC20 for IERC20;
    using Math for uint256;

    bytes32 constant SIGMA_POOL_STORAGE_POSITION =
        bytes32(
            uint256(keccak256("sigma.contracts.sigma.pool.storage")) - 1
        ) & ~bytes32(uint256(0xff));

    struct SigmaPoolStorage {
        // IERC20 asset; // Experimenting with a 2 asset pool
        address vSigmaToken;
        uint256 totalAssets; 
        uint256 totalShares;
        uint256[] mintingFee;
        uint256[] redemptionFee;
        address[] collateralAddresses;
        string[] collateralSymbols;
        bool[] isMintPaused;
        bool[] isRedeemPaused;
        mapping(address collateralAddress => bool isEnabled) isCollateralEnabled;
        mapping(address collateralAddress => uint256 collateralIndex) collateralIndex;
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

    function deposit(uint256 amount) internal {
        SigmaPoolStorage storage s = sigmaPoolStorage();

        require(amount > 0, "SigmaPool: deposit amount is zero");
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
    
    

}
