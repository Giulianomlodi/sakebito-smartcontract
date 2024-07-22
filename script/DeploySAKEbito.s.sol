// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {SAKEbito} from "../src/SAKEbito.sol";

contract DeploySAKEbito is Script {
    function run() external returns (SAKEbito) {
        address devAddress = 0x1234567890123456789012345678901234567890; // This should match the DEV address in the test
        vm.startBroadcast();
        SAKEbito sakebito = new SAKEbito(devAddress);
        vm.stopBroadcast();
        return sakebito;
    }
}
