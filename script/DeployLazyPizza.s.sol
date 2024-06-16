// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {LazyPizzeria} from "../src/LazyPizza.sol";
import {HelperConfig} from "./HelperConfigLight.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./InteractionsLight.s.sol";

contract DeployLazyPizzeria is Script {
    function run() external returns (LazyPizzeria, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            address vrfCoordinator,
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            address linkToken
        ) = helperConfig.activeNewtorkConfig();

        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscribtion(
                vrfCoordinator
            );

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.functionSubscription(
                vrfCoordinator,
                subscriptionId,
                linkToken
            );
        }

        vm.startBroadcast();
        LazyPizzeria lazyPizzeria = new LazyPizzeria(
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit
        );

        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();

        addConsumer.addConsumer(
            address(lazyPizzeria),
            vrfCoordinator,
            subscriptionId
        );

        return (lazyPizzeria, helperConfig);
    }
}
