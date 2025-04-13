// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "abdk/ABDKMathQuad.sol";

/// @dev Default admin role name
bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

/// @dev 1 ETH
uint256 constant ONE = uint256(1 ether); // 3Crv has 18 decimals

/// @dev Reentrancy constant
uint256 constant _NOT_ENTERED = 1;
/// @dev Reentrancy constant
uint256 constant _ENTERED = 2;
