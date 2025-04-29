// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "forge-std/Script.sol";
import "../src/core/vSigmaToken.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy implementation
        vSigmaToken implementation = new vSigmaToken();

        // Encode initialization data
        bytes memory initData = abi.encodeWithSelector(
            vSigmaToken.initialize.selector,
            msg.sender // Using deployer as initial manager
        );

        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        // The proxy address is what users will interact with
        vSigmaToken token = vSigmaToken(address(proxy));

        vm.stopBroadcast();

        console.log("vSigmaToken implementation deployed to:", address(implementation));
        console.log("vSigmaToken proxy deployed to:", address(proxy));
    }
}
