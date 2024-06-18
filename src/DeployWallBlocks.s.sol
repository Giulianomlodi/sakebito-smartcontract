// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Wallblocks} from "./Wallblocks.sol";

contract DeployWallblocks is Script {
    function run() external returns (Wallblocks) {
        vm.startBroadcast();
        Wallblocks wallblocks = new Wallblocks();
        vm.stopBroadcast();

        return wallblocks;
    }
}
