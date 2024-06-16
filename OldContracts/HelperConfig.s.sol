// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../../test/mocks/LinkToken.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address linkToken;
        string margheritaUri;
        string marinaraUri;
        string diavolaUri;
        string capricciosaUri;
        string sbagliataUri;
    }

    NetworkConfig public activeNewtorkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNewtorkConfig = getSepoliaEthConfig();
        } else {
            activeNewtorkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
                gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0, // Update with actual subId 6917
                callbackGasLimit: 2500000,
                linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                margheritaUri: "",
                marinaraUri: "",
                diavolaUri: "",
                capricciosaUri: "",
                sbagliataUri: ""
            });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNewtorkConfig.vrfCoordinator != address(0)) {
            return activeNewtorkConfig;
        }

        uint96 baseFee = 0.25 ether; // 0.25 LINK
        uint96 gasPriceLink = 1e9; // 1 gwei

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(
            baseFee,
            gasPriceLink
        );
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();

        return
            NetworkConfig({
                vrfCoordinator: address(vrfCoordinatorMock),
                gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0, // our script will add this
                callbackGasLimit: 500000,
                linkToken: address(linkToken),
                margheritaUri: "",
                marinaraUri: "",
                diavolaUri: "",
                capricciosaUri: "",
                sbagliataUri: ""
            });
    }
}
