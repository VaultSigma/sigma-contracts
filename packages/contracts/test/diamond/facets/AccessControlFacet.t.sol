// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {DiamondTestSetup} from "../DiamondTestSetup.sol";
import {AccessControlFacet} from "../../../src/facets/AccessControlFacet.sol";
import {AddressUtils} from "../../../src/libraries/AddressUtils.sol";
import {UintUtils} from "../../../src/libraries/UintUtils.sol";
import "../../../src/libraries/Constants.sol";

contract AccessControlFacetTest is DiamondTestSetup {
    using AddressUtils for address;
    using UintUtils for uint256;

    address mockSender = makeAddr("mockSender");
    address mockRecipient = makeAddr("mockRecipient");

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function testGrantRole_ShouldWork() public {
        vm.prank(admin);

        vm.expectEmit(true, true, true, true);
        emit RoleGranted(SIGMA_TOKEN_BURNER_ROLE, mockRecipient, admin);
        accessControlFacet.grantRole(SIGMA_TOKEN_BURNER_ROLE, mockRecipient);
    }

    function testGrantRole_ShouldRevertIfSenderIsNotAdmin() public {
        vm.prank(mockSender);

        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                mockSender.toString(),
                " is missing role ",
                uint256(DEFAULT_ADMIN_ROLE).toHexString(32)
            )
        );
        accessControlFacet.grantRole(SIGMA_TOKEN_BURNER_ROLE, mockRecipient);
    }

    function testRevokeRole_ShouldWork() public {
        vm.prank(admin);
        accessControlFacet.grantRole(SIGMA_TOKEN_BURNER_ROLE, mockRecipient);
        emit RoleGranted(SIGMA_TOKEN_BURNER_ROLE, mockRecipient, admin);

        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit RoleRevoked(SIGMA_TOKEN_BURNER_ROLE, mockRecipient, admin);
        accessControlFacet.revokeRole(SIGMA_TOKEN_BURNER_ROLE, mockRecipient);
    }

    // function testRevokeRole_ShouldWork() public {
}
