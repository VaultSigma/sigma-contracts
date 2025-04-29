// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

interface ISigmaRebalancer {
    function rebalance(bytes memory data) external;
    function getDexRouter() external view returns (address);
    function setDexRouter(address _dexRouter) external;
    function setSigmaPool(address _sigmaPool) external;
    function getSigmaPool() external view returns (address);
}
