// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {DiamondTestSetup} from "../diamond/DiamondTestSetup.sol";

abstract contract LocalTestHelper is DiamondTestSetup {
    address public constant NATIVE_ASSET = address(0);
    address curve3CRVTokenAddress = address(0x101);
    address public treasuryAddress = address(0x111222333);

    address metaPoolAddress;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);
        // set treasury address
        managerFacet.setTreasuryAddress(treasuryAddress);

        vm.stopPrank();
    }
}
