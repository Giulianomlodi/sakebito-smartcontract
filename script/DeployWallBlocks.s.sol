// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {WallBlocks} from "../src/Wallblocks.sol";

contract DeployWallblocks is Script {
    function run() external returns (WallBlocks) {
        vm.startBroadcast();
        WallBlocks wallblocks = new WallBlocks();
        vm.stopBroadcast();

        return wallblocks;
    }
}
