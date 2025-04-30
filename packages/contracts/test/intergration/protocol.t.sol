// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {DiamondTestSetup} from "../diamond/DiamondTestSetup.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";
import {LibStrategyRegistry} from "../../src/libraries/LibStrategyRegistry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ProtocolIntegrationTest is DiamondTestSetup {
    IERC20 collateralToken;
    MockERC20 sigmaToken;

    // This is actually a whale addr on swell mainnet used for testing purposes.
    address user = 0xadA85B59F0fE127b81B499aFB6a73335dEF41E74;
    uint256 depositAmount = 10 ether;
    uint256 timelock = 10000; // 10,000 seconds

    function setUp() public override {
        super.setUp();

        // Deploy mock tokens
        // collateralToken = new MockERC20("Mock Collateral", "MCT", 18);

        collateralToken = IERC20(0x18d33689AE5d02649a859A1CF16c9f0563975258);
        sigmaToken = new MockERC20("Mock Sigma", "MST", 18);
        address feeTreasury = makeAddr("feeTreasury");
        address CrocSwapDex = 0xaAAaAaaa82812F0a1f274016514ba2cA933bF24D;

        uint256 initialBalance = collateralToken.balanceOf(user);

        // Setup protocol
        vm.startPrank(admin);

        // Initialize pool
        sigmaPoolFacet.initialize(address(sigmaToken), 1000, 365000);
        sigmaPoolFacet.setFeeTreasury(feeTreasury);
        sigmaPoolFacet.setSigmaRebalancer(address(sigmaRebalancerFacet));

        // Initialize sigma rebalancer. The contracts are linked to each other.
        sigmaRebalancerFacet.setDexRouter(CrocSwapDex);
        sigmaRebalancerFacet.setSigmaPool(address(sigmaPoolFacet));

        // Add and enable collateral
        sigmaPoolFacet.addCollateralToken(address(collateralToken));
        sigmaPoolFacet.enableCollateral(0);

        // Add strategy
        string memory ipfsUri = "ipfs://QmS4ghgMgPXqVZMQ74v2QZ8Q6K4Q6K4Q6K4Q6K4Q6K4Q6K4"; // TODO: Add actual uri
        string memory strategyDesc = "Experimental AI Trading Strategy";
        strategyRegistryFacet.addStrategy(ipfsUri, strategyDesc, LibStrategyRegistry.StrategyType.Experimental);

        vm.stopPrank();

        // Fund user: Need to find a whale to fund the user
        // vm.prank(admin);
        // deal(address(collateralToken), user, depositAmount);
    }

    function test_CompleteProtocolFlow() public {
        // 1. User approves pool to spend collateral
        vm.prank(user);
        collateralToken.approve(address(sigmaPoolFacet), depositAmount);

        // 2. Verify initial state
        assertEq(collateralToken.balanceOf(address(diamond)), 0);
        assertEq(sigmaToken.balanceOf(user), 0);
        assertEq(sigmaPoolFacet.getTotalAssets(), 0);
        assertEq(sigmaPoolFacet.getTotalShares(), 0);

        // 3. User deposits collateral
        vm.prank(user);
        sigmaPoolFacet.deposit(0, depositAmount, timelock);

        // 4. Verify final state
        assertEq(collateralToken.balanceOf(address(sigmaPoolFacet)), depositAmount);
        assertEq(sigmaToken.balanceOf(user), depositAmount); // 1:1 ratio
        assertEq(sigmaPoolFacet.getTotalAssets(), depositAmount);
        assertEq(sigmaPoolFacet.getTotalShares(), depositAmount);

        // 5. Verify user's collateral balance
        assertEq(sigmaPoolFacet.getUserCollateralBalance(user, 0), depositAmount);

        // 6. Verify strategy is active
        uint256 strategyId = uint256(keccak256(abi.encodePacked("ipfs://QmS4ghgMgPXqVZMQ74v2QZ8Q6K4Q6K4Q6K4Q6K4Q6K4Q6K4")));
        LibStrategyRegistry.StrategyInfo memory strategy = strategyRegistryFacet.getStrategyInfo(strategyId);
        vm.startPrank(admin);
        strategyRegistryFacet.toggleStrategy(strategyId, true);
        assertEq(strategyRegistryFacet.getStrategyInfo(strategyId).isActive, true); // Strategy starts inactive
        vm.stopPrank();
        assertEq(uint256(strategy.strategyType), uint256(LibStrategyRegistry.StrategyType.Experimental));

        // 7. Allocate to rebalancer
        vm.startPrank(admin);
        // sigmaPoolFacet.setSigmaRebalancer(address(sigmaRebalancerFacet));
        sigmaPoolFacet.allocToRebalancer(0, 5 ether);
        // assertEq(collateralToken.balanceOf(address(sigmaPoolFacet)), depositAmount - 5 ether);
        vm.stopPrank();

        // 8. Verify rebalancer balance
        // assertEq(collateralToken.balanceOf(address(sigmaRebalancerFacet)), 5 ether);
        
        // IERC20(address(collateralToken)).transfer(address(diamond), 5 ether);
        // sigmaRebalancerFacet.rebalance();
        
        
    }
}
