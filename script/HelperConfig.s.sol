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
                subscriptionId: 6917, // Update with actual subId 6917
                callbackGasLimit: 2500000,
                linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                margheritaUri: "data:application/json;base64,PHN2ZyB3aWR0aD0iMzczIiBoZWlnaHQ9IjM3MyIgdmlld0JveD0iMCAwIDM3MyAzNzMiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIzNzMiIGhlaWdodD0iMzczIiByeD0iMTg2LjUiIGZpbGw9IiNGN0U1QzYiLz4KPHJlY3QgeD0iMzgiIHk9IjM4IiB3aWR0aD0iMjk3IiBoZWlnaHQ9IjI5NyIgcng9IjE0OC41IiBmaWxsPSIjRkY2MjQyIi8+CjxjaXJjbGUgY3g9IjEyMC41IiBjeT0iMTUwLjUiIHI9IjQyLjUiIGZpbGw9IiNGRUZFRkUiLz4KPGNpcmNsZSBjeD0iMTQ0LjUiIGN5PSIyNDYuNSIgcj0iNDIuNSIgZmlsbD0iI0ZFRkVGRSIvPgo8Y2lyY2xlIGN4PSIyNDIuNSIgY3k9IjIyMC41IiByPSI0Mi41IiBmaWxsPSIjRkVGRUZFIi8+CjxjaXJjbGUgY3g9IjIxOC41IiBjeT0iMTE3LjUiIHI9IjQyLjUiIGZpbGw9IiNGRUZFRkUiLz4KPC9zdmc+Cg==",
                marinaraUri: "data:application/json;base64,PHN2ZyB3aWR0aD0iMzczIiBoZWlnaHQ9IjM3MyIgdmlld0JveD0iMCAwIDM3MyAzNzMiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIzNzMiIGhlaWdodD0iMzczIiByeD0iMTg2LjUiIGZpbGw9IiNGN0U1QzYiLz4KPHJlY3QgeD0iMzgiIHk9IjM4IiB3aWR0aD0iMjk3IiBoZWlnaHQ9IjI5NyIgcng9IjE0OC41IiBmaWxsPSIjRkY2MjQyIi8+Cjwvc3ZnPgo=",
                diavolaUri: "data:application/json;base64,PHN2ZyB3aWR0aD0iMzczIiBoZWlnaHQ9IjM3MyIgdmlld0JveD0iMCAwIDM3MyAzNzMiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIzNzMiIGhlaWdodD0iMzczIiByeD0iMTg2LjUiIGZpbGw9IiNGN0U1QzYiLz4KPHJlY3QgeD0iMzgiIHk9IjM4IiB3aWR0aD0iMjk3IiBoZWlnaHQ9IjI5NyIgcng9IjE0OC41IiBmaWxsPSIjRkY2MjQyIi8+CjxjaXJjbGUgY3g9IjEyMC41IiBjeT0iMTUwLjUiIHI9IjQyLjUiIGZpbGw9IiNGRUZFRkUiLz4KPGNpcmNsZSBjeD0iOTkuNSIgY3k9IjE5OC41IiByPSIyMS41IiBmaWxsPSIjODkwMDAwIi8+CjxjaXJjbGUgY3g9IjE1NC41IiBjeT0iMTAxLjUiIHI9IjIxLjUiIGZpbGw9IiM4OTAwMDAiLz4KPGNpcmNsZSBjeD0iMTQ0LjUiIGN5PSIyNDYuNSIgcj0iNDIuNSIgZmlsbD0iI0ZFRkVGRSIvPgo8Y2lyY2xlIGN4PSIyNDIuNSIgY3k9IjIyMC41IiByPSI0Mi41IiBmaWxsPSIjRkVGRUZFIi8+CjxjaXJjbGUgY3g9IjIxOC41IiBjeT0iMTE3LjUiIHI9IjQyLjUiIGZpbGw9IiNGRUZFRkUiLz4KPGNpcmNsZSBjeD0iMjY5LjUiIGN5PSIxNjAuNSIgcj0iMjEuNSIgZmlsbD0iIzg5MDAwMCIvPgo8Y2lyY2xlIGN4PSIxOTUuNSIgY3k9IjI0Ni41IiByPSIyMS41IiBmaWxsPSIjODkwMDAwIi8+CjxjaXJjbGUgY3g9IjE4NC41IiBjeT0iMTcxLjUiIHI9IjIxLjUiIGZpbGw9IiM4OTAwMDAiLz4KPC9zdmc+Cg==",
                capricciosaUri: "data:application/json;base64,PHN2ZyB3aWR0aD0iMzczIiBoZWlnaHQ9IjM3MyIgdmlld0JveD0iMCAwIDM3MyAzNzMiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIzNzMiIGhlaWdodD0iMzczIiByeD0iMTg2LjUiIGZpbGw9IiNGN0U1QzYiLz4KPHJlY3QgeD0iMzgiIHk9IjM4IiB3aWR0aD0iMjk3IiBoZWlnaHQ9IjI5NyIgcng9IjE0OC41IiBmaWxsPSIjRkY2MjQyIi8+CjxjaXJjbGUgY3g9IjEyMC41IiBjeT0iMTUwLjUiIHI9IjQyLjUiIGZpbGw9IiNGRUZFRkUiLz4KPGNpcmNsZSBjeD0iMTQ0LjUiIGN5PSIyNDYuNSIgcj0iNDIuNSIgZmlsbD0iI0ZFRkVGRSIvPgo8Y2lyY2xlIGN4PSIyNDIuNSIgY3k9IjIyMC41IiByPSI0Mi41IiBmaWxsPSIjRkVGRUZFIi8+CjxjaXJjbGUgY3g9IjIxOC41IiBjeT0iMTE3LjUiIHI9IjQyLjUiIGZpbGw9IiNGRUZFRkUiLz4KPGNpcmNsZSBjeD0iMjI3LjUiIGN5PSI5NS41IiByPSIyMS41IiBmaWxsPSIjRThDQzk0Ii8+CjxjaXJjbGUgY3g9IjEzOS41IiBjeT0iMjMzLjUiIHI9IjIxLjUiIGZpbGw9IiNFOENDOTQiLz4KPGNpcmNsZSBjeD0iMTAxLjUiIGN5PSIxMzkuNSIgcj0iMjEuNSIgZmlsbD0iI0U4Q0M5NCIvPgo8Y2lyY2xlIGN4PSIyNjQuNSIgY3k9IjIxNC41IiByPSIyMS41IiBmaWxsPSIjRThDQzk0Ii8+CjxjaXJjbGUgY3g9IjE2MC41IiBjeT0iMTk5LjUiIHI9IjIxLjUiIGZpbGw9IiNGN0E5QTkiLz4KPGNpcmNsZSBjeD0iMjE5LjUiIGN5PSIxNTkuNSIgcj0iMjEuNSIgZmlsbD0iI0Y3QTlBOSIvPgo8Y2lyY2xlIGN4PSIxNjAuNSIgY3k9IjEzNy41IiByPSIyMS41IiBmaWxsPSIjRjdBOUE5Ii8+Cjwvc3ZnPgo=",
                sbagliataUri: "data:application/json;base64,"
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
                margheritaUri: "data:application/json;base64,PHN2ZyB3aWR0aD0iMzczIiBoZWlnaHQ9IjM3MyIgdmlld0JveD0iMCAwIDM3MyAzNzMiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIzNzMiIGhlaWdodD0iMzczIiByeD0iMTg2LjUiIGZpbGw9IiNGN0U1QzYiLz4KPHJlY3QgeD0iMzgiIHk9IjM4IiB3aWR0aD0iMjk3IiBoZWlnaHQ9IjI5NyIgcng9IjE0OC41IiBmaWxsPSIjRkY2MjQyIi8+CjxjaXJjbGUgY3g9IjEyMC41IiBjeT0iMTUwLjUiIHI9IjQyLjUiIGZpbGw9IiNGRUZFRkUiLz4KPGNpcmNsZSBjeD0iMTQ0LjUiIGN5PSIyNDYuNSIgcj0iNDIuNSIgZmlsbD0iI0ZFRkVGRSIvPgo8Y2lyY2xlIGN4PSIyNDIuNSIgY3k9IjIyMC41IiByPSI0Mi41IiBmaWxsPSIjRkVGRUZFIi8+CjxjaXJjbGUgY3g9IjIxOC41IiBjeT0iMTE3LjUiIHI9IjQyLjUiIGZpbGw9IiNGRUZFRkUiLz4KPC9zdmc+Cg==",
                marinaraUri: "data:application/json;base64,PHN2ZyB3aWR0aD0iMzczIiBoZWlnaHQ9IjM3MyIgdmlld0JveD0iMCAwIDM3MyAzNzMiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIzNzMiIGhlaWdodD0iMzczIiByeD0iMTg2LjUiIGZpbGw9IiNGN0U1QzYiLz4KPHJlY3QgeD0iMzgiIHk9IjM4IiB3aWR0aD0iMjk3IiBoZWlnaHQ9IjI5NyIgcng9IjE0OC41IiBmaWxsPSIjRkY2MjQyIi8+Cjwvc3ZnPgo=",
                diavolaUri: "data:application/json;base64,HN2ZyB3aWR0aD0iMzczIiBoZWlnaHQ9IjM3MyIgdmlld0JveD0iMCAwIDM3MyAzNzMiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIzNzMiIGhlaWdodD0iMzczIiByeD0iMTg2LjUiIGZpbGw9IiNGN0U1QzYiLz4KPHJlY3QgeD0iMzgiIHk9IjM4IiB3aWR0aD0iMjk3IiBoZWlnaHQ9IjI5NyIgcng9IjE0OC41IiBmaWxsPSIjRkY2MjQyIi8+CjxjaXJjbGUgY3g9IjEyMC41IiBjeT0iMTUwLjUiIHI9IjQyLjUiIGZpbGw9IiNGRUZFRkUiLz4KPGNpcmNsZSBjeD0iOTkuNSIgY3k9IjE5OC41IiByPSIyMS41IiBmaWxsPSIjODkwMDAwIi8+CjxjaXJjbGUgY3g9IjE1NC41IiBjeT0iMTAxLjUiIHI9IjIxLjUiIGZpbGw9IiM4OTAwMDAiLz4KPGNpcmNsZSBjeD0iMTQ0LjUiIGN5PSIyNDYuNSIgcj0iNDIuNSIgZmlsbD0iI0ZFRkVGRSIvPgo8Y2lyY2xlIGN4PSIyNDIuNSIgY3k9IjIyMC41IiByPSI0Mi41IiBmaWxsPSIjRkVGRUZFIi8+CjxjaXJjbGUgY3g9IjIxOC41IiBjeT0iMTE3LjUiIHI9IjQyLjUiIGZpbGw9IiNGRUZFRkUiLz4KPGNpcmNsZSBjeD0iMjY5LjUiIGN5PSIxNjAuNSIgcj0iMjEuNSIgZmlsbD0iIzg5MDAwMCIvPgo8Y2lyY2xlIGN4PSIxOTUuNSIgY3k9IjI0Ni41IiByPSIyMS41IiBmaWxsPSIjODkwMDAwIi8+CjxjaXJjbGUgY3g9IjE4NC41IiBjeT0iMTcxLjUiIHI9IjIxLjUiIGZpbGw9IiM4OTAwMDAiLz4KPC9zdmc+Cg==",
                capricciosaUri: "data:application/json;base64,PHN2ZyB3aWR0aD0iMzczIiBoZWlnaHQ9IjM3MyIgdmlld0JveD0iMCAwIDM3MyAzNzMiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIzNzMiIGhlaWdodD0iMzczIiByeD0iMTg2LjUiIGZpbGw9IiNGN0U1QzYiLz4KPHJlY3QgeD0iMzgiIHk9IjM4IiB3aWR0aD0iMjk3IiBoZWlnaHQ9IjI5NyIgcng9IjE0OC41IiBmaWxsPSIjRkY2MjQyIi8+CjxjaXJjbGUgY3g9IjEyMC41IiBjeT0iMTUwLjUiIHI9IjQyLjUiIGZpbGw9IiNGRUZFRkUiLz4KPGNpcmNsZSBjeD0iMTQ0LjUiIGN5PSIyNDYuNSIgcj0iNDIuNSIgZmlsbD0iI0ZFRkVGRSIvPgo8Y2lyY2xlIGN4PSIyNDIuNSIgY3k9IjIyMC41IiByPSI0Mi41IiBmaWxsPSIjRkVGRUZFIi8+CjxjaXJjbGUgY3g9IjIxOC41IiBjeT0iMTE3LjUiIHI9IjQyLjUiIGZpbGw9IiNGRUZFRkUiLz4KPGNpcmNsZSBjeD0iMjI3LjUiIGN5PSI5NS41IiByPSIyMS41IiBmaWxsPSIjRThDQzk0Ii8+CjxjaXJjbGUgY3g9IjEzOS41IiBjeT0iMjMzLjUiIHI9IjIxLjUiIGZpbGw9IiNFOENDOTQiLz4KPGNpcmNsZSBjeD0iMTAxLjUiIGN5PSIxMzkuNSIgcj0iMjEuNSIgZmlsbD0iI0U4Q0M5NCIvPgo8Y2lyY2xlIGN4PSIyNjQuNSIgY3k9IjIxNC41IiByPSIyMS41IiBmaWxsPSIjRThDQzk0Ii8+CjxjaXJjbGUgY3g9IjE2MC41IiBjeT0iMTk5LjUiIHI9IjIxLjUiIGZpbGw9IiNGN0E5QTkiLz4KPGNpcmNsZSBjeD0iMjE5LjUiIGN5PSIxNTkuNSIgcj0iMjEuNSIgZmlsbD0iI0Y3QTlBOSIvPgo8Y2lyY2xlIGN4PSIxNjAuNSIgY3k9IjEzNy41IiByPSIyMS41IiBmaWxsPSIjRjdBOUE5Ii8+Cjwvc3ZnPgo=",
                sbagliataUri: "data:application/json;base64,"
            });
    }
}
