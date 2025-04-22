// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {DiamondTestSetup} from "../DiamondTestSetup.sol";
import {SigmaPoolFacet} from "../../../src/facets/SigmaPoolFacet.sol";
import {MockERC20} from "../../../src/mocks/MockERC20.sol";
import {AddressUtils} from "../../../src/libraries/AddressUtils.sol";
import {UintUtils} from "../../../src/libraries/UintUtils.sol";

contract SigmaPoolFacetTest is DiamondTestSetup {
    using AddressUtils for address;
    using UintUtils for uint256;

    address mockSender = makeAddr("mockSender");
    address mockRecipient = makeAddr("mockRecipient");

    MockERC20 collateralToken = new MockERC20("Mock Collateral Token", "MCT", 18);
    MockERC20 sigmaToken = new MockERC20("Mock Sigma Token", "MST", 18);

    function testInitialize_ShouldWork() public {
        vm.prank(admin);
        sigmaPoolFacet.initialize(address(collateralToken), address(sigmaToken));
    }

    // function testInitialize_ShouldRevertIfAssetIsZeroAddress() public {
    //     vm.prank(admin);
    //     vm.expectRevert(SigmaPoolFacet.SigmaPoolFacet__AssetIsZeroAddress.selector);
    //     sigmaPoolFacet.initialize(address(0), address(sigmaToken));
    // }
    
    


}