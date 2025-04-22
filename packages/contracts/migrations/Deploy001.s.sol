// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Script} from "forge-std/Script.sol";
import {Diamond, DiamondArgs} from "../src/Diamond.sol";
import {AccessControlFacet} from "../src/facets/AccessControlFacet.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {ManagerFacet} from "../src/facets/ManagerFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../src/interfaces/IDiamondLoupe.sol";
import {IERC173} from "../src/interfaces/IERC173.sol";
import {DEFAULT_ADMIN_ROLE} from "../src/libraries/Constants.sol";
import {LibAccessControl} from "../src/libraries/LibAccessControl.sol";
import {AppStorage, LibAppStorage, Modifiers} from "../src/libraries/LibAppStorage.sol";
import {LibDiamond} from "../src/libraries/LibDiamond.sol";
import {DiamondTestHelper} from "../test/helpers/DiamondTestHelper.sol";
import {SigmaPoolFacet} from "../src/facets/SigmaPoolFacet.sol";
import {vSigmaToken} from "../src/core/vSigmaToken.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @notice It is expected that this contract is customized if you want to deploy your diamond
 * with data from a deployment script. Use the init function to initialize state variables
 * of your diamond. Add parameters to the init function if you need to.
 *
 * @notice How it works:
 * 1. New `Diamond` contract is created
 * 2. Inside the diamond's constructor there is a `delegatecall()` to `DiamondInit` with the provided args
 * 3. `DiamondInit` updates diamond storage
 */
contract DiamondInit is Modifiers {
    /// @notice Struct used for diamond initialization
    struct Args {
        address admin;
    }

    /**
     * @notice Initializes a diamond with state variables
     * @dev You can add parameters to this function in order to pass in data to set your own state variables
     * @param _args Init args
     */
    function init(Args memory _args) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        LibAccessControl.grantRole(DEFAULT_ADMIN_ROLE, _args.admin);

        AppStorage storage appStore = LibAppStorage.appStorage();
        appStore.paused = false;
        appStore.treasuryAddress = _args.admin;

        // reentrancy guard
        _initReentrancyGuard();
    }
}

/**
 * @notice Migration contract
 * @dev Initial production migration includes the following contracts:
 * - SigmaPool (which is a facet of the Diamond contract)
 *
 * So we're deploying only contracts and facets necessary for features
 * connected with the contracts above. Hence we omit the following facets
 * from deployment:
 */
contract Deploy001 is Script, DiamondTestHelper {
    // env variables
    uint256 adminPrivateKey;
    uint256 ownerPrivateKey;

    // owner and admin addresses derived from private keys store in `.env` file
    address adminAddress;
    address ownerAddress;

    vSigmaToken sigmaToken;
    ERC1967Proxy sigmaTokenProxy;

    Diamond diamond;
    DiamondInit diamondInit;

    // diamond facet implementation instances (should not be used directly)
    AccessControlFacet accessControlFacetImplementation;
    DiamondCutFacet diamondCutFacetImplementation;
    DiamondLoupeFacet diamondLoupeFacetImplementation;
    ManagerFacet managerFacetImplementation;
    OwnershipFacet ownershipFacetImplementation;
    SigmaPoolFacet sigmaPoolFacetImplementation;

    // selectors for all of the facets
    bytes4[] selectorsOfAccessControlFacet;
    bytes4[] selectorsOfDiamondCutFacet;
    bytes4[] selectorsOfDiamondLoupeFacet;
    bytes4[] selectorsOfManagerFacet;
    bytes4[] selectorsOfOwnershipFacet;
    bytes4[] selectorsOfSigmaPoolFacet;

    function run() public virtual {
        // read env variables
        adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        ownerPrivateKey = vm.envUint("OWNER_PRIVATE_KEY");

        adminAddress = vm.addr(adminPrivateKey);
        ownerAddress = vm.addr(ownerPrivateKey);

        //==================
        // Before scripts
        //==================

        beforeRun();

        //===================
        // Deploy Diamond
        //===================

        // start sending owner transactions
        vm.startBroadcast(ownerPrivateKey);

        // set all function selectors
        selectorsOfAccessControlFacet = getSelectorsFromAbi(
            "/out/AccessControlFacet.sol/AccessControlFacet.json"
        );
        selectorsOfDiamondCutFacet = getSelectorsFromAbi(
            "/out/DiamondCutFacet.sol/DiamondCutFacet.json"
        );
        selectorsOfDiamondLoupeFacet = getSelectorsFromAbi(
            "/out/DiamondLoupeFacet.sol/DiamondLoupeFacet.json"
        );
        selectorsOfManagerFacet = getSelectorsFromAbi(
            "/out/ManagerFacet.sol/ManagerFacet.json"
        );
        selectorsOfOwnershipFacet = getSelectorsFromAbi(
            "/out/OwnershipFacet.sol/OwnershipFacet.json"
        );
        selectorsOfSigmaPoolFacet = getSelectorsFromAbi(
            "/out/SigmaPoolFacet.sol/SigmaPoolFacet.json"
        );

        // deploy facet implementation instances
        accessControlFacetImplementation = new AccessControlFacet();
        diamondCutFacetImplementation = new DiamondCutFacet();
        diamondLoupeFacetImplementation = new DiamondLoupeFacet();
        managerFacetImplementation = new ManagerFacet();
        ownershipFacetImplementation = new OwnershipFacet();
        sigmaPoolFacetImplementation = new SigmaPoolFacet();
        // prepare DiamondInit args
        diamondInit = new DiamondInit();
        DiamondInit.Args memory diamondInitArgs = DiamondInit.Args({
            admin: adminAddress
        });
        // prepare Diamond arguments
        DiamondArgs memory diamondArgs = DiamondArgs({
            owner: ownerAddress,
            init: address(diamondInit),
            initCalldata: abi.encodeWithSelector(
                DiamondInit.init.selector,
                diamondInitArgs
            )
        });

        // prepare facet cuts
        FacetCut[] memory cuts = new FacetCut[](6);
        cuts[0] = (
            FacetCut({
                facetAddress: address(accessControlFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfAccessControlFacet
            })
        );
        cuts[1] = (
            FacetCut({
                facetAddress: address(diamondCutFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfDiamondCutFacet
            })
        );
        cuts[2] = (
            FacetCut({
                facetAddress: address(diamondLoupeFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfDiamondLoupeFacet
            })
        );
        cuts[3] = (
            FacetCut({
                facetAddress: address(managerFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfManagerFacet
            })
        );
        cuts[4] = (
            FacetCut({
                facetAddress: address(ownershipFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfOwnershipFacet
            })
        );
        cuts[5] = (
            FacetCut({
                facetAddress: address(sigmaPoolFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfSigmaPoolFacet
            })
        );

        // deploy diamond
        diamond = new Diamond(diamondArgs, cuts);

        // stop sending owner transactions
        vm.stopBroadcast();

        //=======================
        // Diamond permissions
        //=======================

        // start sending admin transactions
        vm.startBroadcast(adminPrivateKey);

        AccessControlFacet accessControlFacet = AccessControlFacet(
            address(diamond)
        );

        // stop sending admin transactions
        vm.stopBroadcast();

        //=========================
        // SigmaPoolFacet setup
        //=========================

        // start sending admin transactions
        vm.startBroadcast(adminPrivateKey);

        // set SigmaToken address in the SigmaPoolFacet
        SigmaPoolFacet sigmaPoolFacet = SigmaPoolFacet(address(diamond));

        // stop sending admin transactions
        vm.stopBroadcast();

        //==================
        // Sigma deploy
        //==================

        // start sending owner transactions
        vm.startBroadcast(ownerPrivateKey);

        bytes memory initSigmaPayload = abi.encodeWithSignature(
            "initialize",
            address(diamond)    
        );

        sigmaToken = new vSigmaToken();

        // sigmaTokenProxy = new ERC1967Proxy(
        //     address(sigmaToken),
        //     initSigmaPayload
        // );

        // sigmaToken = vSigmaToken(address(sigmaTokenProxy));
        sigmaToken = vSigmaToken(address(sigmaToken));

        vm.stopBroadcast();

        //================
        // Sigma setup
        //================

        // start sending admin transactions
        vm.startBroadcast(adminPrivateKey);

        // set Sigma token address in the Diamond
        ManagerFacet managerFacet = ManagerFacet(address(diamond));
        managerFacet.setSigmaToken(address(sigmaToken));

        address collateralToken = 0x4200000000000000000000000000000000000006;

        // set Sigma token address in the SigmaPoolFacet
        sigmaPoolFacet.initialize(collateralToken, address(sigmaToken));

        // stop sending admin transactions
        vm.stopBroadcast();

        //=================
        // After scripts
        //=================

    }

    /**
     * @notice Runs before the main `run()` method
     *
     * @dev Initializes collateral token
     * @dev Collateral token is different for mainnet and development:
     * - development: deploys mocked ERC20 token from scratch
     */
    function beforeRun() public virtual {
        //=================================
        // Collateral ERC20 token deploy
        //=================================

        // start sending owner transactions
        vm.startBroadcast(ownerPrivateKey);

        // deploy ERC20 mock token for ease of debugging

        // stop sending owner transactions
        vm.stopBroadcast();
    }

    
}