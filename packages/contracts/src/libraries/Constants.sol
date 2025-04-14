// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "abdk/ABDKMathQuad.sol";

/// @dev Default admin role name
bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

bytes32 constant SIGMA_TOKEN_MINTER_ROLE = keccak256(
    "SIGMA_TOKEN_MINTER_ROLE"
);

bytes32 constant SIGMA_TOKEN_BURNER_ROLE = keccak256(
    "SIGMA_TOKEN_BURNER_ROLE"
);

bytes32 constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

/// @dev 1 ETH
uint256 constant ONE = uint256(1 ether);

/// @dev Reentrancy constant
uint256 constant _NOT_ENTERED = 1;
/// @dev Reentrancy constant
uint256 constant _ENTERED = 2;
