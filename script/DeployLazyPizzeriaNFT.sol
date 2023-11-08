// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {LazyPizzeriaNFT} from "../src/LazyPizzeriaNFT.sol";

contract DeployLazyPizzeriaNFT is Script {
    function run() external returns (LazyPizzeriaNFT) {
        vm.startBroadcast();
        LazyPizzeriaNFT lazyPizzeriaNFT = new LazyPizzeriaNFT();
        vm.stopBroadcast();
        return lazyPizzeriaNFT;
    }
}
