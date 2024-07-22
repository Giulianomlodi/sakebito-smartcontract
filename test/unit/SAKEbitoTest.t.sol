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
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() public {
        vm.prank(OWNER);
        sakebito = new SAKEbito(DEV);
        vm.deal(MINTER, STARTING_USER_BALANCE);
        vm.deal(MINTER2, STARTING_USER_BALANCE);
    }

    function testInitialState() public {
        assertEq(sakebito.devAddress(), DEV);
        assertFalse(sakebito.activeMint());
        assertEq(sakebito.currentBatchId(), 0);
        assertEq(sakebito.owner(), OWNER);
    }

    function testSetActiveMint() public {
        vm.prank(OWNER);
        sakebito.setActiveMint(true);
        assertTrue(sakebito.activeMint());

        vm.prank(OWNER);
        sakebito.setActiveMint(false);
        assertFalse(sakebito.activeMint());
    }

    function testCreateBatch() public {
        vm.prank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 0.1 ether, 100);

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
        assertEq(cost, 0.1 ether);
        assertEq(limit, 100);
        assertFalse(active);
        assertFalse(ended);
        assertEq(minted, 0);
    }

    function testCreateBatchFailsPreviousBatchNotEnded() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 0.1 ether, 100);
        vm.expectRevert(SAKEbito.PreviousBatchNotEnded.selector);
        sakebito.createBatch("Batch2", "ipfs://batch2/", 0.1 ether, 100);
        vm.stopPrank();
    }

    function testActivateDeactivateBatch() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 0.1 ether, 100);
        sakebito.activateBatch();
        vm.stopPrank();

        (, , , , , bool active, , ) = sakebito.batches(1);
        assertTrue(active);

        vm.prank(OWNER);
        sakebito.deactivateBatch();

        (, , , , , active, , ) = sakebito.batches(1);
        assertFalse(active);
    }

    function testEndBatch() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 0.1 ether, 100);
        sakebito.endBatch();
        vm.stopPrank();

        (, , , , , , bool ended, ) = sakebito.batches(1);
        assertTrue(ended);
    }

    function testMint() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 0.1 ether, 100);
        sakebito.activateBatch();
        sakebito.setActiveMint(true);
        vm.stopPrank();

        vm.prank(MINTER);
        sakebito.mint{value: 0.1 ether}();

        assertEq(sakebito.balanceOf(MINTER), 1);
        assertEq(sakebito.ownerOf(1), MINTER);
    }

    function testMintFailsWhenInactive() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 0.1 ether, 100);
        sakebito.activateBatch();
        vm.stopPrank();

        vm.prank(MINTER);
        vm.expectRevert(SAKEbito.MintNotActive.selector);
        sakebito.mint{value: 0.1 ether}();
    }

    function testMintFailsWhenInsufficientPayment() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 0.1 ether, 100);
        sakebito.activateBatch();
        sakebito.setActiveMint(true);
        vm.stopPrank();

        vm.prank(MINTER);
        vm.expectRevert(SAKEbito.InsufficientPayment.selector);
        sakebito.mint{value: 0.05 ether}();
    }

    function testPaymentSplit() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 1 ether, 100);
        sakebito.activateBatch();
        sakebito.setActiveMint(true);
        vm.stopPrank();

        uint256 initialOwnerBalance = OWNER.balance;
        uint256 initialDevBalance = DEV.balance;

        vm.prank(MINTER);
        sakebito.mint{value: 1 ether}();

        assertEq(OWNER.balance - initialOwnerBalance, 0.9 ether);
        assertEq(DEV.balance - initialDevBalance, 0.1 ether);
    }

    function testTokenURI() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 0.1 ether, 100);
        sakebito.activateBatch();
        sakebito.setActiveMint(true);
        vm.stopPrank();

        vm.prank(MINTER);
        sakebito.mint{value: 0.1 ether}();

        string memory uri = sakebito.tokenURI(1);
        assertEq(uri, "ipfs://batch1/1.json");
    }

    function testActivateEndedBatch() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 0.1 ether, 100);
        sakebito.endBatch();
        vm.expectRevert(SAKEbito.BatchAlreadyEnded.selector);
        sakebito.activateBatch();
        vm.stopPrank();
    }

    function testDeactivateEndedBatch() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 0.1 ether, 100);
        sakebito.endBatch();
        vm.expectRevert(SAKEbito.BatchAlreadyEnded.selector);
        sakebito.deactivateBatch();
        vm.stopPrank();
    }

    function testEndEndedBatch() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 0.1 ether, 100);
        sakebito.endBatch();
        vm.expectRevert(SAKEbito.BatchAlreadyEnded.selector);
        sakebito.endBatch();
        vm.stopPrank();
    }

    function testMintFromInactiveBatch() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 0.1 ether, 100);
        sakebito.setActiveMint(true);
        vm.stopPrank();

        vm.prank(MINTER);
        vm.expectRevert(SAKEbito.BatchNotActive.selector);
        sakebito.mint{value: 0.1 ether}();
    }

    function testMintFromNonExistentBatch() public {
        vm.prank(OWNER);
        sakebito.setActiveMint(true);

        vm.prank(MINTER);
        vm.expectRevert(SAKEbito.NoBatchActive.selector);
        sakebito.mint{value: 0.1 ether}();
    }

    function testMintFailsWhenBatchEnded() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 0.1 ether, 1);
        sakebito.activateBatch();
        sakebito.setActiveMint(true);
        vm.stopPrank();

        vm.prank(MINTER);
        sakebito.mint{value: 0.1 ether}();

        vm.prank(MINTER2);
        vm.expectRevert(SAKEbito.BatchNotActive.selector);
        sakebito.mint{value: 0.1 ether}();
    }

    function testMintFailsWhenBatchLimitReached() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 0.1 ether, 1);
        sakebito.activateBatch();
        sakebito.setActiveMint(true);
        vm.stopPrank();

        vm.prank(MINTER);
        sakebito.mint{value: 0.1 ether}();

        vm.prank(MINTER2);
        vm.expectRevert(SAKEbito.BatchNotActive.selector);
        sakebito.mint{value: 0.1 ether}();
    }

    function testUpdateMerkleRoot() public {
        bytes32 newRoot = keccak256(abi.encodePacked("newRoot"));
        vm.prank(OWNER);
        sakebito.updateMerkleRoot(newRoot);
        assertEq(sakebito.merkleRoot(), newRoot);
    }

    function testUpdateBatchBaseURI() public {
        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 0.1 ether, 100);
        sakebito.updateBatchBaseURI(1, "ipfs://newuri/");
        vm.stopPrank();

        (, , string memory newUri, , , , , ) = sakebito.batches(1);
        assertEq(newUri, "ipfs://newuri/");
    }

    function testUpdateBatchBaseURIFailsForNonExistentBatch() public {
        vm.prank(OWNER);
        vm.expectRevert(SAKEbito.BatchDoesNotExist.selector);
        sakebito.updateBatchBaseURI(1, "ipfs://newuri/");
    }

    function testWhitelistMint() public {
        bytes32[] memory proof = new bytes32[](0);
        bytes32 root = keccak256(abi.encodePacked(MINTER));

        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 1 ether, 100);
        sakebito.activateBatch();
        sakebito.setActiveMint(true);
        sakebito.updateMerkleRoot(root);
        vm.stopPrank();

        vm.prank(MINTER);
        sakebito.whitelistMint{value: 0.9 ether}(proof);

        assertEq(sakebito.balanceOf(MINTER), 1);
        assertEq(sakebito.ownerOf(1), MINTER);
    }

    function testWhitelistMintFailsWithInvalidProof() public {
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = keccak256(abi.encodePacked(MINTER2));

        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 1 ether, 100);
        sakebito.activateBatch();
        sakebito.setActiveMint(true);
        sakebito.updateMerkleRoot(proof[0]);
        vm.stopPrank();

        vm.prank(MINTER);
        vm.expectRevert(SAKEbito.InvalidProof.selector);
        sakebito.whitelistMint{value: 0.9 ether}(proof);
    }

    function testWhitelistMintFailsWhenBatchNotActive() public {
        bytes32[] memory proof = new bytes32[](0);
        bytes32 root = keccak256(abi.encodePacked(MINTER));

        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 1 ether, 100);
        sakebito.setActiveMint(true);
        sakebito.updateMerkleRoot(root);
        vm.stopPrank();

        vm.prank(MINTER);
        vm.expectRevert(SAKEbito.BatchNotActive.selector);
        sakebito.whitelistMint{value: 0.9 ether}(proof);
    }

    function testWhitelistMintFailsWhenAlreadyClaimed() public {
        bytes32[] memory proof = new bytes32[](0);
        bytes32 root = keccak256(abi.encodePacked(MINTER));

        vm.startPrank(OWNER);
        sakebito.createBatch("Batch1", "ipfs://batch1/", 1 ether, 100);
        sakebito.activateBatch();
        sakebito.setActiveMint(true);
        sakebito.updateMerkleRoot(root);
        vm.stopPrank();

        // First whitelist mint should succeed
        vm.prank(MINTER);
        sakebito.whitelistMint{value: 0.9 ether}(proof);

        // Second whitelist mint should fail
        vm.prank(MINTER);
        vm.expectRevert(SAKEbito.WhitelistAlreadyClaimed.selector);
        sakebito.whitelistMint{value: 0.9 ether}(proof);
    }
}
