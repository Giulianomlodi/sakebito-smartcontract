// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {LazyPizza} from "../src/LazyPizza.sol";

contract DeployLazyPizza is Script {
    uint256 public TEST_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public deployerKey;

    function run() external returns (LazyPizza) {
        if (block.chainid == 31337) {
            deployerKey = TEST_PRIVATE_KEY;
        } else {
            deployerKey = vm.envUint("DEPLOYER_KEY");
        }

        vm.startBroadcast();
        LazyPizza lazyPizza = new LazyPizza();
        vm.stopBroadcast();
        return lazyPizza;
    }
}
