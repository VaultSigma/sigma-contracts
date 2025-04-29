// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {DiamondTestSetup} from "../DiamondTestSetup.sol";
import {SigmaPoolFacet} from "../../../src/facets/SigmaPoolFacet.sol";
import {MockERC20} from "../../../src/mocks/MockERC20.sol";
import {AddressUtils} from "../../../src/libraries/AddressUtils.sol";
import {UintUtils} from "../../../src/libraries/UintUtils.sol";
import "../../../src/libraries/Constants.sol";
import {LibSigmaPool} from "../../../src/libraries/LibSigmaPool.sol";

contract SigmaPoolFacetTest is DiamondTestSetup {
    using AddressUtils for address;
    using UintUtils for uint256;

    MockERC20 collateralToken = new MockERC20("Mock Collateral Token", "MCT", 18);
    MockERC20 sigmaToken = new MockERC20("Mock Sigma Token", "MST", 18);

    address mockSender = makeAddr("mockSender");
    address mockRecipient = makeAddr("mockRecipient");
    address feeTreasury = makeAddr("feeTreasury");
    address sigmaRebalancer = makeAddr("sigmaRebalancer");

    struct CollateralInformation {
        uint256 index;
        address collateralAddress;
        string symbol;
        bool isMintPaused;
        bool isRedeemPaused;
    }

    function setUp() public override {
        super.setUp();

        vm.prank(admin);
        collateralToken.mint(mockSender, 1000000);

        // Setup in setUp to ensure it's done before each test
        // Initialize the pool
        vm.startPrank(admin);
        sigmaPoolFacet.initialize(address(sigmaToken), 1000, 365000);
        sigmaPoolFacet.setFeeTreasury(address(feeTreasury));
        sigmaPoolFacet.setSigmaRebalancer(address(sigmaRebalancer));

        // Add and enable collateral token
        sigmaPoolFacet.addCollateralToken(address(collateralToken));
        // This is index not boolean
        sigmaPoolFacet.enableCollateral(0);
        vm.stopPrank();
    }

    function testInitialize_ShouldWork() public view {
        // Test is now handled in setUp
        (uint256 totalAssets, uint256 totalShares, uint256 minLockTime, uint256 maxLockTime) =
            sigmaPoolFacet.getPoolInfo();
        assertEq(totalAssets, 0);
        assertEq(totalShares, 0);
        assertEq(minLockTime, 1000);
        assertEq(maxLockTime, 365000);

        (uint256 index, address collateralAddress, bool isMintPaused, bool isRedeemPaused) =
            sigmaPoolFacet.collateralInformation(address(collateralToken));
        assertEq(index, 0);
        assertEq(collateralAddress, address(collateralToken));
        assertEq(isMintPaused, false);
        assertEq(isRedeemPaused, false);
    }

    function testInitialize_ShouldRevertIfSigmaTokenIsZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodePacked("SigmaPool: vSigmaToken is zero address"));
        sigmaPoolFacet.initialize(address(0), 1000, 365000);
    }

    function testInitialize_ShouldRevertIfNotAdmin() public {
        vm.prank(mockSender);
        vm.expectRevert(abi.encodePacked("Manager: Caller is not admin"));
        sigmaPoolFacet.initialize(address(sigmaToken), 1000, 365000);
    }

    function testSetFeeTreasury_ShouldWork() public {
        vm.prank(admin);
        sigmaPoolFacet.setFeeTreasury(address(feeTreasury));
    }

    function testSetFeeTreasury_ShouldRevertIfSenderIsNotAdmin() public {
        vm.prank(mockSender);
        vm.expectRevert(abi.encodePacked("Manager: Caller is not admin"));
        sigmaPoolFacet.setFeeTreasury(address(feeTreasury));
    }

    function testSetSigmaRebalancer_ShouldWork() public {
        vm.prank(admin);
        sigmaPoolFacet.setSigmaRebalancer(address(sigmaRebalancer));
    }

    function testSetSigmaRebalancer_ShouldRevertIfSenderIsNotAdmin() public {
        vm.prank(mockSender);
        vm.expectRevert(abi.encodePacked("Manager: Caller is not admin"));
        sigmaPoolFacet.setSigmaRebalancer(address(sigmaRebalancer));
    }

    function testDeposit_ShouldWork() public {
        // Mint tokens to user

        // Approve the pool to spend user's tokens
        vm.prank(mockSender);
        collateralToken.approve(address(diamond), 1000);

        // Deposit
        vm.startPrank(mockSender);
        collateralToken.approve(address(diamond), 1000);
        sigmaPoolFacet.deposit(0, 10, 10000);
        vm.stopPrank();

        // Verify the deposit
        assertEq(sigmaPoolFacet.getTotalAssets(), 10);
        assertEq(collateralToken.balanceOf(address(sigmaPoolFacet)), 10);
        assertEq(sigmaToken.balanceOf(mockSender), 10);

        // // // Verify the lock was created
        // (uint256 amount, uint256 timelock, uint256 unlockTime, uint256 rewards) =
        //     sigmaPoolFacet.getLockInfo(mockSender, 0);

        // assertEq(amount, 10);
        // assertEq(timelock, 10000);
        // assertEq(unlockTime, block.timestamp + 10000);
        // assertEq(rewards > 0, true);
    }

    function testCalculateShares_ShouldWorkIfTotalSharesIsZero() public {
        uint256 shares = sigmaPoolFacet.calculateShares(0);
        assertEq(shares, 0);
    }

    function testCalculateShares_ShouldWork(uint256 amount) public {
        vm.startPrank(mockSender);

        amount = bound(amount, 1, 1000000);
        deal(address(collateralToken), mockSender, amount);

        collateralToken.approve(address(diamond), amount);
        sigmaPoolFacet.deposit(0, amount, 10000);
        vm.stopPrank();

        uint256 calc_shares = (amount * sigmaPoolFacet.getTotalShares()) / sigmaPoolFacet.getTotalAssets();

        uint256 shares = sigmaPoolFacet.calculateShares(amount);
        assertEq(shares, calc_shares);
    }

    function testCalculateAssets_ShouldRevertIfAmountIsZero() public {
        vm.expectRevert(abi.encodePacked("SigmaPool: total shares is zero"));
        sigmaPoolFacet.calculateAssets(0);
    }

    function testCalculateAssets_ShouldWork(uint256 amount) public {
        vm.startPrank(mockSender);

        amount = bound(amount, 1, 1000000);
        deal(address(collateralToken), mockSender, amount);

        collateralToken.approve(address(diamond), amount);
        sigmaPoolFacet.deposit(0, amount, 10000);
        vm.stopPrank();

        uint256 calc_assets = (amount * sigmaPoolFacet.getTotalAssets()) / sigmaPoolFacet.getTotalShares();
        uint256 assets = sigmaPoolFacet.calculateAssets(amount);
        assertEq(assets, calc_assets);
    }

    function testRedeem_ShouldWork() public {
        vm.startPrank(mockSender);
        collateralToken.approve(address(diamond), 1000);
        sigmaPoolFacet.deposit(0, 10, 10000);
        vm.stopPrank();

        vm.startPrank(mockSender);
        sigmaToken.approve(address(diamond), 10);
        sigmaPoolFacet.redeem(0, 10);
        vm.stopPrank();

        assertEq(sigmaPoolFacet.getTotalAssets(), 0);
        assertEq(collateralToken.balanceOf(address(sigmaPoolFacet)), 0);
        assertEq(sigmaToken.balanceOf(mockSender), 0);
    }

    function testAddCollateralToken_ShouldWork() public {
        // vm.startPrank(admin);
        // sigmaPoolFacet.addCollateralToken(address(collateralToken));
        // sigmaPoolFacet.enableCollateral(1);
        // vm.stopPrank();

        (uint256 index, address collateralAddress, bool isMintPaused, bool isRedeemPaused) =
            sigmaPoolFacet.collateralInformation(address(collateralToken));
        assertEq(index, 0);
        assertEq(collateralAddress, address(collateralToken));
        assertEq(isMintPaused, false);
        assertEq(isRedeemPaused, false);
    }

    // Testing this as a unit test is not possible because it requires the crocswap dex router
    // function testRebalance_ShouldWork() public {
    //     LibSigmaPool.RebalanceParams memory params = LibSigmaPool.RebalanceParams({
    //         base: address(collateralToken),
    //         quote: address(sigmaToken),
    //         poolIdx: 0,
    //         isBuy: true,
    //         inBaseQty: true,
    //         qty: 10,
    //         tip: 1000,
    //         limitPrice: 1000,
    //         minOut: 1000,
    //         reserveFlags: 1000,
    //         collateralIndex: 0
    //     });

    //     vm.startPrank(admin);
    //     sigmaPoolFacet.rebalance(params);
    //     vm.stopPrank();
    // }
}
