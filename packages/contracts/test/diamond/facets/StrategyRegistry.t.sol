// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {DiamondTestSetup} from "../DiamondTestSetup.sol";
import {StrategyRegistryFacet} from "../../../src/facets/StrategyRegistryFacet.sol";
import {LibStrategyRegistry} from "../../../src/libraries/LibStrategyRegistry.sol";
import {AddressUtils} from "../../../src/libraries/AddressUtils.sol";
import {UintUtils} from "../../../src/libraries/UintUtils.sol";
import "../../../src/libraries/Constants.sol";

contract SigmaPoolFacetTest is DiamondTestSetup {

    string ipfsUri = "ipfs://QmS4ghgMgPXqVZMQ74v2QZ8Q6K4Q6K4Q6K4Q6K4Q6K4Q6K4";
    string strategyDesc = "Experimental AI Trading Strategy";

    function testAddStrategy_ShouldWork() public {
        vm.startPrank(admin);
        strategyRegistryFacet.addStrategy(ipfsUri, strategyDesc, LibStrategyRegistry.StrategyType.Experimental);
        vm.stopPrank();
    }

    function testUpdateStrategy_ShouldWork() public {
        vm.startPrank(admin);

        uint256 strategyId = uint256(keccak256(abi.encodePacked(ipfsUri)));

        strategyRegistryFacet.addStrategy(ipfsUri, strategyDesc, LibStrategyRegistry.StrategyType.Experimental);
        strategyRegistryFacet.updateStrategy(strategyId, ipfsUri, LibStrategyRegistry.StrategyType.Stable);
        vm.stopPrank();
    }



}