// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {DeployLazyPizzeria} from "../../script/DeployLazyPizzeria.s.sol";
import {LazyPizzeria} from "../../src/LazyPizzeria.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";

contract LazyPizzeriaTest is Test {
    event AirMint(address indexed client, uint256 indexed tokenId); // TEST EVENT TO BE DELETED
    event PizzaSbagliata(address indexed client, bool indexed isPizzaSbagliata);

    bool public isPizzaSbagliata = false;

    LazyPizzeria lazyPizzeria;
    HelperConfig helperConfig;

    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address linkToken;
    DeployLazyPizzeria deployer;

    uint256 internal ownerPrivateKey;

    address public MINTER = makeAddr("MINTER");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        deployer = new DeployLazyPizzeria();
        (lazyPizzeria, helperConfig) = deployer.run();
        (
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            linkToken
        ) = helperConfig.activeNewtorkConfig();
        vm.deal(MINTER, STARTING_USER_BALANCE);
    }

    function testMintState() external view {
        assert(lazyPizzeria.getActiveMint() == true);
    }

    function testOpenCloseMint() external {
        lazyPizzeria.setActiveMint(true);
        assert(lazyPizzeria.getActiveMint() == true);
        lazyPizzeria.setActiveMint(false);
        assert(lazyPizzeria.getActiveMint() == false);
        lazyPizzeria.setActiveMint(true);
        assert(lazyPizzeria.getActiveMint() == true);
    }

    function testLastId() external view {
        assert(lazyPizzeria.getLastId() == 0);
    }
}
