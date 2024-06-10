// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {DeployLazyPizzeria} from "../../script/DeployLazyPizzeria.s.sol";
import {LazyPizzeria} from "../../src/LazyPizzeria.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

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
    address public MINTER2 = makeAddr("MINTER2");
    uint256 public constant STARTING_USER_BALANCE = 0.5 ether;

    // Pizza URIs
    string margheritaUri;
    string marinaraUri;
    string diavolaUri;
    string capricciosaUri;
    string sbagliataUri;

    address[] public users;

    function setUp() external {
        deployer = new DeployLazyPizzeria();
        vm.deal(MINTER, STARTING_USER_BALANCE);
        for (uint i = 0; i < 10; i++) {
            users.push(
                makeAddr(string(abi.encodePacked("User", Strings.toString(i))))
            );
            vm.deal(users[i], STARTING_USER_BALANCE);
        }
        (lazyPizzeria, helperConfig) = deployer.run();
        (
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            linkToken,
            margheritaUri,
            marinaraUri,
            diavolaUri,
            capricciosaUri,
            sbagliataUri
        ) = helperConfig.activeNewtorkConfig();
    }

    function testMintState() external view {
        assert(lazyPizzeria.getActiveMint() == false);
    }

    function testActivatingMintingState() external {
        vm.prank(lazyPizzeria.owner());
        lazyPizzeria.setActiveMint(true);
        assert(lazyPizzeria.getActiveMint() == true);
    }

    function testDeactivatingMintingState() external {
        vm.prank(lazyPizzeria.owner());
        lazyPizzeria.setActiveMint(false);
        assert(lazyPizzeria.getActiveMint() == false);
    }

    function testNormalUserCanNotMintIFMintStateIsFalse() external {
        uint256 mintPrice = lazyPizzeria.publicPrice();
        vm.expectRevert(LazyPizzeria.NotActiveMint.selector);
        vm.prank(MINTER);
        lazyPizzeria.mintPizza{value: mintPrice}(
            LazyPizzeria.pizzaType.Margherita
        );
    }

    function testNormalUserCanNotMintIFNotEnoughValueIsSent() external {
        vm.prank(lazyPizzeria.owner());
        lazyPizzeria.setActiveMint(true);
        vm.prank(MINTER);
        vm.expectRevert(LazyPizzeria.NotEnoughtValue.selector);
        lazyPizzeria.mintPizza{value: 0}(LazyPizzeria.pizzaType.Margherita);
    }

    function testSuccessfulMinting() external {
        vm.prank(lazyPizzeria.owner());
        lazyPizzeria.setActiveMint(true);

        uint256 initialBalance = address(lazyPizzeria).balance;
        uint256 mintPrice = lazyPizzeria.publicPrice();

        vm.prank(MINTER);
        lazyPizzeria.mintPizza{value: mintPrice}(
            LazyPizzeria.pizzaType.Margherita
        );

        assertTrue(lazyPizzeria.balanceOf(MINTER) == 1);
        assertEq(address(lazyPizzeria).balance, initialBalance + mintPrice);
    }

    function testSuccessfulDeposit() external {
        uint256 depositAmount = 1 ether;
        vm.prank(lazyPizzeria.owner());
        lazyPizzeria.deposit{value: depositAmount}();

        assertEq(depositAmount, address(lazyPizzeria).balance);
    }

    function testSuccessfulWithdrawal() external {
        uint256 depositAmount = 1 ether;
        address ownerAddress = lazyPizzeria.owner();
        console.log(
            "CONTRACT BALANCE BEFORE DEPOSIT: %s ",
            address(lazyPizzeria).balance
        );
        vm.prank(lazyPizzeria.owner());
        lazyPizzeria.deposit{value: depositAmount}();
        console.log(
            "CONTRACT BALANCE BEFORE WITHDRAWAL: %s ",
            address(lazyPizzeria).balance
        );
        uint256 initialOwnerBalance = ownerAddress.balance;
        console.log(
            "OWNER BALANCE BEFORE WITHDRAWAL: %s ",
            initialOwnerBalance
        );
        uint256 withdrawalAmount = 0.5 ether;

        vm.prank(lazyPizzeria.owner());
        lazyPizzeria.withdraw();

        console.log(
            "CONTRACT BALANCE AFTER WITHDRAWAL: %s ",
            address(lazyPizzeria).balance
        );
        console.log(
            "OWNER BALANCE AFTER WITHDRAWAL: %s ",
            ownerAddress.balance
        );
        console.log(
            "WHAT OWNER BALANCE SHOULD BE: %s ",
            initialOwnerBalance + withdrawalAmount
        );
        uint256 gasUsed = tx.gasprice * gasleft();

        assertEq(
            ownerAddress.balance,
            initialOwnerBalance + depositAmount - gasUsed
        );
    }

    function testWithdrawalFailureDueToContractIsEmpty() external {
        console.log("CONTRACT BALANCE: %s ", address(lazyPizzeria).balance);
        vm.prank(lazyPizzeria.owner());
        vm.expectRevert(LazyPizzeria.ContractBalanceIsZero.selector);
        lazyPizzeria.withdraw();
    }

    function testWithdrawalToFailureDueToInsufficientBalance() external {
        uint256 depositAmount = 1 ether;
        vm.prank(lazyPizzeria.owner());
        lazyPizzeria.deposit{value: depositAmount}();
        uint256 withdrawalAmount = address(lazyPizzeria).balance + 1 ether;
        console.log(
            "CONTRACT BALANCE AFTER DEPOSIT: %s ",
            address(lazyPizzeria).balance
        );
        console.log("WITHDRAWAL AMOUNT: %s ", withdrawalAmount);
        console.log("MINTER BALANCE PRE WITHDRAWAL: %s ", MINTER.balance);
        vm.prank(lazyPizzeria.owner());
        vm.expectRevert(LazyPizzeria.InsufficientBalance.selector);

        lazyPizzeria.withdrawTo(MINTER, withdrawalAmount);
    }

    function testBaseURIFunctionality() external {
        string memory newBaseURI = "https://api.lazypizzeria.com/";
        vm.prank(lazyPizzeria.owner());
        lazyPizzeria.setBaseURI(newBaseURI);

        assertEq(lazyPizzeria.baseURI(), newBaseURI);
    }

    function testPizzaTypeAssignment() external {
        vm.prank(lazyPizzeria.owner());
        lazyPizzeria.setActiveMint(true);
        uint256 mintPrice = lazyPizzeria.publicPrice();

        vm.prank(MINTER);
        lazyPizzeria.mintPizza{value: mintPrice}(
            LazyPizzeria.pizzaType.Margherita
        );

        uint256 tokenId = lazyPizzeria.getLastId();
        assertEq(
            uint(lazyPizzeria.getPizzaTypeFromTokenId(tokenId)),
            uint(LazyPizzeria.pizzaType.Margherita)
        );
    }

    function testIsNotPossibleToSelectPizzaSbagliata() external {
        uint256 mintPrice = lazyPizzeria.publicPrice();
        vm.prank(lazyPizzeria.owner());
        lazyPizzeria.setActiveMint(true);
        console.log("MINTER", MINTER);
        console.log("IS MINT ACTIVE?", lazyPizzeria.getActiveMint());
        vm.prank(MINTER);
        vm.expectRevert(LazyPizzeria.YouCantSelectPizzaSbagliata.selector);

        lazyPizzeria.mintPizza{value: mintPrice}(
            LazyPizzeria.pizzaType.Sbagliata
        );
    }

    function testLastId() external view {
        assert(lazyPizzeria.getLastId() == 0);
    }

    function testLastIdAfterMinting() external {
        uint256 mintPrice = lazyPizzeria.publicPrice();
        vm.prank(lazyPizzeria.owner());
        lazyPizzeria.setActiveMint(true);
        vm.prank(MINTER);
        lazyPizzeria.mintPizza{value: mintPrice}(
            LazyPizzeria.pizzaType.Diavola
        );

        assert(lazyPizzeria.getLastId() == 1);
    }

    // Function that test with multiple minting and multiple users if at least one pizza is sbagliata

    function testMintingAtLeastOnePizzaSbagliata() external {
        vm.prank(lazyPizzeria.owner());
        lazyPizzeria.setActiveMint(true);

        uint256 mintPrice = lazyPizzeria.publicPrice();
        bool sbagliataMinted = false;

        for (uint i = 0; i < users.length; i++) {
            vm.prank(users[i]);
            lazyPizzeria.mintPizza{value: mintPrice}(
                LazyPizzeria.pizzaType.Margherita
            );

            uint256 tokenId = lazyPizzeria.getLastId();
            if (
                uint(lazyPizzeria.getPizzaTypeFromTokenId(tokenId)) ==
                uint(LazyPizzeria.pizzaType.Sbagliata)
            ) {
                sbagliataMinted = true;
                break;
            }
        }

        console.log("IS SBAGLIATA MINTED: ", sbagliataMinted);

        assertTrue(sbagliataMinted, "A Pizza Sbagliata was minted");
    }

    function testProbabilityOfPizzaSbagliata() external {
        vm.prank(lazyPizzeria.owner());
        lazyPizzeria.setActiveMint(true);

        uint256 mintPrice = lazyPizzeria.publicPrice();
        uint256 sbagliataCount = 0;

        // Simulate 100 mints
        for (uint i = 0; i < 100; i++) {
            address user = users[i];

            // Simulate random number generation
            uint256 simulatedRandomNumber = i; // Replace this with your method of simulating randomness

            // Mock the callback from Chainlink VRF with the simulated random number
            vm.mockCall(
                address(lazyPizzeria),
                abi.encodeWithSignature(
                    "fulfillRandomWords(uint256,uint256[])",
                    new uint256[](1)
                ),
                abi.encode(simulatedRandomNumber)
            );

            // User mints a pizza
            vm.prank(user);
            lazyPizzeria.mintPizza{value: mintPrice}(
                LazyPizzeria.pizzaType.Margherita
            );

            // Check if the minted pizza is Sbagliata
            uint256 tokenId = lazyPizzeria.getLastId();
            if (
                uint(lazyPizzeria.getPizzaTypeFromTokenId(tokenId)) ==
                uint(LazyPizzeria.pizzaType.Sbagliata)
            ) {
                sbagliataCount++;
            }
        }

        // Log the sbagliataCount
        console.log("Total number of Pizza Sbagliata minted: ", sbagliataCount);

        // Calculate the probability
        uint256 probability = (sbagliataCount * 100) / 100;
        console.log(
            "Probability of getting a Pizza Sbagliata: ",
            probability,
            "%"
        );
    }
}
