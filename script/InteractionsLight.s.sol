// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfigLight.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() internal returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (address vrfCoordinator, , , , address linkToken) = helperConfig
            .activeNewtorkConfig();
        return createSubscribtion(vrfCoordinator);
    }

    function createSubscribtion(
        address vrfCoordinator
    ) public returns (uint64) {
        console.log("Creating subscription on ChainID:", block.chainid);
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console.log("Subscription created with ID:", subId);
        console.log("Please update the subscriptionId in HelperConfig.s.sol");
        return subId;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            address vrfCoordinator,
            ,
            uint64 subscriptionId,
            ,
            address linkToken
        ) = helperConfig.activeNewtorkConfig();
        functionSubscription(vrfCoordinator, subscriptionId, linkToken);
    }

    function functionSubscription(
        address vrfCoordinator,
        uint64 subscriptionId,
        address linkToken
    ) public {
        console.log("Funding subscription on ChainID:", block.chainid);
        console.log("Subscription ID:", subscriptionId);
        console.log("Using vrfCoordinator:", vrfCoordinator);
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(
        address lazyPizza,
        address vrfCoordinator,
        uint64 subscriptionId
    ) public {
        console.log("Adding consumer:", lazyPizza);
        console.log("Using vrfCoordinator:", vrfCoordinator);
        console.log("Using subscriptionId:", subscriptionId);
        console.log("On chain:", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(
            subscriptionId,
            lazyPizza
        );
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address lazypizza) public {
        HelperConfig helperConfig = new HelperConfig();
        (address vrfCoordinator, , uint64 subscriptionId, , ) = helperConfig
            .activeNewtorkConfig();
        addConsumer(lazypizza, vrfCoordinator, subscriptionId);
    }

    function run() external {
        address lazyPizza = DevOpsTools.get_most_recent_deployment(
            "LazyPizza",
            block.chainid
        );
        addConsumerUsingConfig(lazyPizza);
    }
}
