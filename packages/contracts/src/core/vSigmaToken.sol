// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../libraries/Constants.sol";
// import {IERC20Sigma} from "../interfaces/IERC20Sigma.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";


abstract contract vSigmaToken is 
    ERC20Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{

    IAccessControl public accessControl;

    event Minting(address indexed minter, address indexed to, uint256 amount);
    event Burning(address indexed burner, uint256 amount);
    
    constructor() {
        _disableInitializers();
    }

    modifier onlySigmaMinter() {
        require(
            accessControl.hasRole(SIGMA_TOKEN_MINTER_ROLE, msg.sender),
            "vSigma Token: not sigma minter"
        );
        _;
    }

    modifier onlySigmaBurner() {
        require(
            accessControl.hasRole(SIGMA_TOKEN_BURNER_ROLE, msg.sender),
            "vSigma Token: not sigma burner"
        );
        _;
    }

    function initialize() external initializer {
        __ERC20_init("Sigma Vault", "vSIGMA");
        __UUPSUpgradeable_init();
    }

    function __ERC20Sigma_init_unchained(address _manager) internal onlyInitializing {
        accessControl = IAccessControl(_manager);
    }

    function mint(address to, uint256 amount) external onlySigmaMinter {
        _mint(to, amount);
        emit Minting(msg.sender, to, amount);
    }

    function burnFrom(address from, uint256 amount) external onlySigmaBurner {
        _burn(from, amount);
        emit Burning(from, amount);
    }

    // function symbol() public view override returns (string memory) {
    //     return symbol;
    // }

    // function setSymbol(string memory _symbol) external onlyOwner {
    //     symbol = _symbol;
    // }
    
    
}