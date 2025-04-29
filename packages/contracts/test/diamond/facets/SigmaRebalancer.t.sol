// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {DiamondTestSetup} from "../DiamondTestSetup.sol";
import {SigmaPoolFacet} from "../../../src/facets/SigmaPoolFacet.sol";
import {MockERC20} from "../../../src/mocks/MockERC20.sol";
import {AddressUtils} from "../../../src/libraries/AddressUtils.sol";
import {UintUtils} from "../../../src/libraries/UintUtils.sol";
import "../../../src/libraries/Constants.sol";

contract SigmaRebalancerFacetTest is DiamondTestSetup {
    using AddressUtils for address;
    using UintUtils for uint256;

    address CrocSwapDex = 0xaAAaAaaa82812F0a1f274016514ba2cA933bF24D;

    function setUp() public override {
        super.setUp();
    }

    function testSetDexRouter_ShouldWork() public {
        vm.startPrank(admin);
        sigmaRebalancerFacet.setDexRouter(CrocSwapDex);
        vm.stopPrank();

        vm.assertEq(sigmaRebalancerFacet.getDexRouter(), CrocSwapDex);
    }

    function testSetSigmaPool_ShouldWork() public {
        vm.startPrank(admin);
        sigmaRebalancerFacet.setSigmaPool(address(sigmaPoolFacet));
        vm.stopPrank();

        vm.assertEq(sigmaRebalancerFacet.getSigmaPool(), address(sigmaPoolFacet));
    }
}
