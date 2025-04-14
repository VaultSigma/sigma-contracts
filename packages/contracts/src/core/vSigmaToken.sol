// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ERC20Sigma} from "./ERC20Sigma.sol";

import "../libraries/Constants.sol";

contract vSigmaToken is ERC20Sigma {
    
    constructor() {
        _disableInitializers();
    }

    function initialize(_manager) external initializer {
        __ERC20Sigma_init(_manager, "Sigma Vault", "vSIGMA");
    }


    modifier onlySigmaMinter() {
        require(
            accessControl.hasRole(SIGMA_MINTER_ROLE, msg.sender),
            "vSigma Token: not sigma minter"
        );
        _;
    }
    
    
}