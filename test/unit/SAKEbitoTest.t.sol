// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {SAKEbito} from "../../src/SAKEbito.sol";

contract SAKEbitoTest is Test {
    SAKEbito public sakebito;

    address public OWNER = makeAddr("OWNER");
    address public MINTER = makeAddr("MINTER");
    address public MINTER2 = makeAddr("MINTER2");
    address public constant DEV = address(0x1234);
    address public constant ADMIN = address(0x5678);
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() public {
        vm.prank(OWNER);
        sakebito = new SAKEbito(DEV, ADMIN);
        vm.deal(MINTER, STARTING_USER_BALANCE);
        vm.deal(MINTER2, STARTING_USER_BALANCE);
    }

    function testInitialState() public {
        assertEq(sakebito.devAddress(), DEV);
        assertEq(sakebito.adminAddress(), ADMIN);
        assertFalse(sakebito.activeMint());
        assertEq(sakebito.currentBatchId(), 0);
        assertEq(sakebito.owner(), OWNER);
    }

    function testCreateBatch() public {
        vm.prank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 1 ether, 100);

        (
            uint256 id,
            string memory name,
            string memory baseUri,
            uint256 cost,
            uint256 limit,
            bool active,
            bool ended,
            uint256 minted
        ) = sakebito.batches(1);

        assertEq(id, 1);
        assertEq(name, "Batch1");
        assertEq(baseUri, "ipfs://batch1/");
        assertEq(cost, 1 ether);
        assertEq(limit, 100);
        assertFalse(active);
        assertFalse(ended);
        assertEq(minted, 0);
    }

    function testActivateBatch() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 1 ether, 100);
        sakebito.activateBatch();
        vm.stopPrank();

        (, , , , , bool active, , ) = sakebito.batches(1);
        assertTrue(active);
    }

    function testDeactivateBatch() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 1 ether, 100);
        sakebito.activateBatch();
        sakebito.deactivateBatch();
        vm.stopPrank();

        (, , , , , bool active, , ) = sakebito.batches(1);
        assertFalse(active);
    }

    function testEndBatch() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 1 ether, 100);
        sakebito.activateBatch();
        sakebito.endBatch();
        vm.stopPrank();

        (, , , , , , bool ended, ) = sakebito.batches(1);
        assertTrue(ended);
    }

    function testMint() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 1 ether, 100);
        sakebito.activateBatch();
        sakebito.setActiveMint(true);
        vm.stopPrank();

        vm.prank(MINTER);
        sakebito.mint{value: 1 ether}(1);

        assertEq(sakebito.balanceOf(MINTER), 1);
    }

    function testPaymentSplit() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 1 ether, 100);
        sakebito.activateBatch();
        sakebito.setActiveMint(true);
        vm.stopPrank();

        uint256 initialDevBalance = DEV.balance;
        uint256 initialAdminBalance = ADMIN.balance;

        vm.prank(MINTER);
        sakebito.mint{value: 1 ether}(1);

        assertEq(DEV.balance - initialDevBalance, 0.1 ether);
        assertEq(ADMIN.balance - initialAdminBalance, 0.9 ether);
    }

    function testPaymentSplitForMultipleMint() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 1 ether, 100);
        sakebito.activateBatch();
        sakebito.setActiveMint(true);
        vm.stopPrank();

        uint256 initialDevBalance = DEV.balance;
        uint256 initialAdminBalance = ADMIN.balance;

        vm.prank(MINTER);
        sakebito.mint{value: 3 ether}(3);

        assertEq(DEV.balance - initialDevBalance, 0.3 ether);
        assertEq(ADMIN.balance - initialAdminBalance, 2.7 ether);
    }

    function testPaymentDistributionEvent() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 1 ether, 100);
        sakebito.activateBatch();
        sakebito.setActiveMint(true);
        vm.stopPrank();

        vm.expectEmit(true, true, true, true);
        emit SAKEbito.PaymentDistributed(DEV, ADMIN, 0.1 ether, 0.9 ether);

        vm.prank(MINTER);
        sakebito.mint{value: 1 ether}(1);
    }

    function testWhitelistMintPaymentSplit() public {
        bytes32[] memory proof = new bytes32[](0);
        bytes32 root = keccak256(abi.encodePacked(MINTER));

        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 1 ether, 100);
        sakebito.activateBatch();
        sakebito.setActiveMint(true);
        sakebito.updateMerkleRoot(root);
        vm.stopPrank();

        uint256 initialDevBalance = DEV.balance;
        uint256 initialAdminBalance = ADMIN.balance;

        vm.prank(MINTER);
        sakebito.whitelistMint{value: 0.85 ether}(proof);

        assertEq(DEV.balance - initialDevBalance, 0.085 ether);
        assertEq(ADMIN.balance - initialAdminBalance, 0.765 ether);
    }

    function testMintToDoesNotTriggerPayment() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 0.1 ether, 100);
        sakebito.activateBatch();
        uint256 initialDevBalance = DEV.balance;
        uint256 initialAdminBalance = ADMIN.balance;
        sakebito.mintTo(MINTER);
        vm.stopPrank();

        assertEq(DEV.balance, initialDevBalance);
        assertEq(ADMIN.balance, initialAdminBalance);
        assertEq(sakebito.balanceOf(MINTER), 1);
    }

    function testPaymentFailure() public {
        // Create a malicious contract that rejects payments
        MaliciousContract maliciousAdmin = new MaliciousContract();

        vm.prank(OWNER);
        SAKEbito maliciousSakebito = new SAKEbito(DEV, address(maliciousAdmin));

        vm.startPrank(OWNER);
        maliciousSakebito.createBatch("Batch1", "ipfs://batch1/", 1 ether, 100);
        maliciousSakebito.activateBatch();
        maliciousSakebito.setActiveMint(true);
        vm.stopPrank();

        vm.prank(MINTER);
        vm.expectRevert(SAKEbito.TransferFailed.selector);
        maliciousSakebito.mint{value: 1 ether}(1);
    }

    function testWhitelistMintDiscount() public {
        bytes32[] memory proof = new bytes32[](0);
        bytes32 root = keccak256(abi.encodePacked(MINTER));

        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 1 ether, 100);
        sakebito.activateBatch();
        sakebito.setActiveMint(true);
        sakebito.updateMerkleRoot(root);
        vm.stopPrank();

        vm.prank(MINTER);
        sakebito.whitelistMint{value: 0.85 ether}(proof);

        assertEq(sakebito.balanceOf(MINTER), 1);
    }

    function testWhitelistMintInsufficientPayment() public {
        bytes32[] memory proof = new bytes32[](0);
        bytes32 root = keccak256(abi.encodePacked(MINTER));

        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 1 ether, 100);
        sakebito.activateBatch();
        sakebito.setActiveMint(true);
        sakebito.updateMerkleRoot(root);
        vm.stopPrank();

        vm.prank(MINTER);
        vm.expectRevert(SAKEbito.InsufficientPayment.selector);
        sakebito.whitelistMint{value: 0.84 ether}(proof);
    }

    function testWhitelistMintOnlyOnce() public {
        bytes32[] memory proof = new bytes32[](0);
        bytes32 root = keccak256(abi.encodePacked(MINTER));

        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 1 ether, 100);
        sakebito.activateBatch();
        sakebito.setActiveMint(true);
        sakebito.updateMerkleRoot(root);
        vm.stopPrank();

        vm.startPrank(MINTER);
        sakebito.whitelistMint{value: 0.85 ether}(proof);

        vm.expectRevert(SAKEbito.WhitelistAlreadyClaimed.selector);
        sakebito.whitelistMint{value: 0.85 ether}(proof);
        vm.stopPrank();
    }
}

// Helper contract for testing payment failure
contract MaliciousContract {
    receive() external payable {
        revert("Payment rejected");
    }
}
