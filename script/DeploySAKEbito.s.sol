// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {SAKEbito} from "../src/SAKEbito.sol";

contract DeploySAKEbito is Script {
    function run() external returns (SAKEbito) {
        address devAddress = 0x6dfa2fBF2b0b9c867Ff0a7420afBb4a20EF33E9E;
        address adminAddress = 0x06c101e446c23E75384D542410C0d5246c886580;

        vm.startBroadcast();
        SAKEbito sakebito = new SAKEbito(devAddress, adminAddress);
        vm.stopBroadcast();

        return sakebito;
    }
}
