// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "abdk/ABDKMathQuad.sol";

/// @dev Default admin role name
bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

bytes32 constant SIGMA_TOKEN_MINTER_ROLE = keccak256("SIGMA_TOKEN_MINTER_ROLE");

bytes32 constant SIGMA_TOKEN_BURNER_ROLE = keccak256("SIGMA_TOKEN_BURNER_ROLE");

bytes32 constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

/// @dev 1 ETH
uint256 constant ONE = uint256(1 ether);

/// @dev Reentrancy constant
uint256 constant _NOT_ENTERED = 1;
/// @dev Reentrancy constant
uint256 constant _ENTERED = 2;

/// @dev Minimum timelock for a deposit
uint256 constant MIN_LOCK_TIME = 1 days;
/// @dev Maximum timelock for a deposit
uint256 constant MAX_LOCK_TIME = 365 days;
/// @dev Base reward rate for a timelock
uint256 constant BASE_REWARD_RATE = 15e17; // PLS DOUBLE CHECK THIS
/// @dev Boost rate for a timelock
uint256 constant BOOST_RATE = 100;
