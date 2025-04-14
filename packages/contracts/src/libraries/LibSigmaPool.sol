// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {AppStorage, LibAppStorage} from "./LibAppStorage.sol";

library LibSigmaPool {

    bytes32 constant SIGMA_POOL_STORAGE_POSITION =
        bytes32(
            uint256(keccak256("sigma.contracts.sigma.pool.storage")) - 1
        ) & ~bytes32(uint256(0xff));

    struct SigmaPoolStorage {
    
    }

    
}
