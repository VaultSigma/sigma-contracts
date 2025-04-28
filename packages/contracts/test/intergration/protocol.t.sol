// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {DiamondTestSetup} from "../diamond/DiamondTestSetup.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";
import {LibStrategyRegistry} from "../../src/libraries/LibStrategyRegistry.sol";

contract ProtocolIntegrationTest is DiamondTestSetup {
    MockERC20 collateralToken;
    MockERC20 sigmaToken;
    
    address user = makeAddr("user");
    uint256 depositAmount = 1000 ether;
    uint256 timelock = 10000; // 10,000 seconds

    function setUp() public override {
        super.setUp();
        
        // Deploy mock tokens
        collateralToken = new MockERC20("Mock Collateral", "MCT", 18);
        sigmaToken = new MockERC20("Mock Sigma", "MST", 18);
        address feeTreasury = makeAddr("feeTreasury");

        // Setup protocol
        vm.startPrank(admin);
        
        // // Initialize pool
        sigmaPoolFacet.initialize(address(sigmaToken), 1000, 365000);
        sigmaPoolFacet.setFeeTreasury(feeTreasury);
        // sigmaPoolFacet.setSigmaRebalancer(sigmaRebalancer);
        
        // // Add and enable collateral
        sigmaPoolFacet.addCollateralToken(address(collateralToken));
        sigmaPoolFacet.enableCollateral(0);

        // // Add strategy
        // string memory ipfsUri = "ipfs://QmS4ghgMgPXqVZMQ74v2QZ8Q6K4Q6K4Q6K4Q6K4Q6K4Q6K4";
        // string memory strategyDesc = "Experimental AI Trading Strategy";
        // strategyRegistryFacet.addStrategy(ipfsUri, strategyDesc, LibStrategyRegistry.StrategyType.Experimental);
        
        vm.stopPrank();

        // Fund user
        vm.prank(admin);
        collateralToken.mint(user, depositAmount);
    }

    function test_CompleteDepositFlow() public {
        // 1. User approves pool to spend collateral
        vm.prank(user);
        collateralToken.approve(address(diamond), depositAmount);

        // 2. Verify initial state
        assertEq(collateralToken.balanceOf(user), depositAmount);
        assertEq(collateralToken.balanceOf(address(diamond)), 0);
        assertEq(sigmaToken.balanceOf(user), 0);
        assertEq(sigmaPoolFacet.getTotalAssets(), 0);
        assertEq(sigmaPoolFacet.getTotalShares(), 0);

        // 3. User deposits collateral
        vm.prank(user);
        sigmaPoolFacet.deposit(0, depositAmount, timelock);

        // 4. Verify final state
        assertEq(collateralToken.balanceOf(user), 0);
        assertEq(collateralToken.balanceOf(address(diamond)), depositAmount);
    //     assertEq(sigmaToken.balanceOf(user), depositAmount); // 1:1 ratio
    //     assertEq(sigmaPoolFacet.getTotalAssets(), depositAmount);
    //     assertEq(sigmaPoolFacet.getTotalShares(), depositAmount);

    //     // 5. Verify user's collateral balance
    //     assertEq(sigmaPoolFacet.getUserCollateralBalance(user, 0), depositAmount);

    //     // 6. Verify strategy is active
    //     uint256 strategyId = uint256(keccak256(abi.encodePacked("ipfs://QmS4ghgMgPXqVZMQ74v2QZ8Q6K4Q6K4Q6K4Q6K4Q6K4Q6K4")));
    //     LibStrategyRegistry.StrategyInfo memory strategy = strategyRegistryFacet.getStrategyInfo(strategyId);
    //     assertEq(strategy.isActive, false); // Strategy starts inactive
    //     assertEq(uint256(strategy.strategyType), uint256(LibStrategyRegistry.StrategyType.Experimental));
    }

    // function test_DepositWithActiveStrategy() public {
    //     // 1. Activate strategy
    //     vm.prank(admin);
    //     uint256 strategyId = uint256(keccak256(abi.encodePacked("ipfs://QmS4ghgMgPXqVZMQ74v2QZ8Q6K4Q6K4Q6K4Q6K4Q6K4Q6K4")));
    //     strategyRegistryFacet.toggleStrategy(strategyId, true);

    //     // 2. User approves and deposits
    //     vm.prank(user);
    //     collateralToken.approve(address(diamond), depositAmount);
    //     sigmaPoolFacet.deposit(0, depositAmount, timelock);

    //     // 3. Verify strategy allocation
    //     assertEq(sigmaPoolFacet.getUserCollateralBalance(user, 0), depositAmount);
        
    //     // 4. Verify strategy is active
    //     LibStrategyRegistry.StrategyInfo memory strategy = strategyRegistryFacet.getStrategyInfo(strategyId);
    //     assertEq(strategy.isActive, true);
    // }
}

