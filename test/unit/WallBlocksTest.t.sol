// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {WallBlocks} from "../../src/Wallblocks.sol";
import {DeployWallblocks} from "../../script/DeployWallBlocks.s.sol";
import {Vm} from "forge-std/Vm.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WallBlocksTest is Test {
    WallBlocks public wallblocks;
    DeployWallblocks deployer;

    address public MINTER = makeAddr("MINTER");
    address public MINTER2 = makeAddr("MINTER2");
    uint256 public constant STARTING_USER_BALANCE = 1 ether;

    function setUp() public {
        deployer = new DeployWallblocks();
        vm.deal(MINTER, STARTING_USER_BALANCE);
        vm.deal(MINTER2, STARTING_USER_BALANCE);
        wallblocks = deployer.run();
    }

    function testMintState() public view {
        assert(wallblocks.getActiveMint() == false);
    }

    function testActivatingMintingState() public {
        vm.prank(wallblocks.owner());
        wallblocks.setActiveMint(true);
        assert(wallblocks.getActiveMint() == true);
    }

    function testDeactivatingMintingState() public {
        vm.prank(wallblocks.owner());
        wallblocks.setActiveMint(false);
        assert(wallblocks.getActiveMint() == false);
    }

    function testNormalUserCanNotMintIfMintStateIsFalse() public {
        uint256 wallId = 1;
        uint256 x = 1;
        uint256 y = 1;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);

        vm.expectRevert(WallBlocks.NotActiveMint.selector);
        vm.prank(MINTER);
        wallblocks.mintBlock{value: price}(wallId, x, y);
    }

    function testNormalUserCanNotMintIfNotEnoughValueIsSent() public {
        uint256 wallId = 1;
        uint256 x = 1;
        uint256 y = 1;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);
        vm.prank(wallblocks.owner());
        wallblocks.setActiveMint(true);

        vm.prank(MINTER);
        vm.expectRevert(WallBlocks.NotEnoughValue.selector);
        wallblocks.mintBlock{value: 0}(wallId, x, y);
    }

    function testSuccessfulMinting() public {
        uint256 wallId = 1;
        uint256 x = 1;
        uint256 y = 1;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);
        vm.prank(wallblocks.owner());
        wallblocks.setActiveMint(true);

        uint256 initialBalance = address(wallblocks).balance;

        vm.prank(MINTER);
        wallblocks.mintBlock{value: price}(wallId, x, y);

        assertTrue(wallblocks.balanceOf(MINTER) == 1);
        assertEq(address(wallblocks).balance, initialBalance + price);
    }

    function testCreateMultipleWalls() public {
        uint256 numWalls = 500;
        uint256 x = 9;
        uint256 y = 11;
        uint256 price = 1 ether;

        vm.startPrank(wallblocks.owner());
        for (uint256 i = 1; i <= numWalls; i++) {
            wallblocks.setWall(i, x, y, price);
        }
        vm.stopPrank();

        for (uint256 i = 1; i <= numWalls; i++) {
            WallBlocks.Wall memory wall = wallblocks.getWallDetails(i);
            assertEq(wall.x, x);
            assertEq(wall.y, y);
            assertEq(wall.price, price);
            assertTrue(wall.exists);
        }
    }

    function testWhitelistMint() public {
        uint256 wallId = 1;
        uint256 x = 1;
        uint256 y = 1;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);

        bytes32[] memory proof = new bytes32[](1);
        proof[0] = keccak256(abi.encodePacked(MINTER));
        vm.prank(wallblocks.owner());
        wallblocks.setMerkleRoot(proof[0]);

        vm.prank(MINTER);
        wallblocks.whitelistMint{value: price}(proof, wallId, x, y);

        assertTrue(wallblocks.balanceOf(MINTER) == 1);
    }

    function testWhitelistMintWithInvalidProof() public {
        uint256 wallId = 1;
        uint256 x = 1;
        uint256 y = 1;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);

        bytes32[] memory proof = new bytes32[](1);
        proof[0] = keccak256(abi.encodePacked(MINTER2));
        vm.prank(wallblocks.owner());
        wallblocks.setMerkleRoot(proof[0]);

        vm.prank(MINTER);
        vm.expectRevert(WallBlocks.InvalidProof.selector);
        wallblocks.whitelistMint{value: price}(proof, wallId, x, y);
    }

    function testWhitelistMintWithInsufficientValue() public {
        uint256 wallId = 1;
        uint256 x = 1;
        uint256 y = 1;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);

        bytes32[] memory proof = new bytes32[](1);
        proof[0] = keccak256(abi.encodePacked(MINTER));
        vm.prank(wallblocks.owner());
        wallblocks.setMerkleRoot(proof[0]);

        vm.prank(MINTER);
        vm.expectRevert(
            abi.encodeWithSelector(WallBlocks.NotEnoughValue.selector)
        );
        wallblocks.whitelistMint{value: price - 1}(proof, wallId, x, y);
    }

    function testWhitelistMintWithAlreadyClaimedAddress() public {
        uint256 wallId = 1;
        uint256 x = 1;
        uint256 y = 1;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);

        bytes32[] memory proof = new bytes32[](1);
        proof[0] = keccak256(abi.encodePacked(MINTER));
        vm.prank(wallblocks.owner());
        wallblocks.setMerkleRoot(proof[0]);

        vm.prank(MINTER);
        wallblocks.whitelistMint{value: price}(proof, wallId, x, y);

        vm.prank(MINTER);
        vm.expectRevert(WallBlocks.AddressAlreadyClaimed.selector);
        wallblocks.whitelistMint{value: price}(proof, wallId, x, y);
    }

    function testStakeNFTsForWall() public {
        uint256 wallId = 1;
        uint256 x = 1;
        uint256 y = 1;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);
        vm.prank(wallblocks.owner());
        wallblocks.setActiveMint(true);

        vm.prank(MINTER);
        wallblocks.mintBlock{value: price}(wallId, x, y);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.prank(MINTER);
        wallblocks.stakeNFTsForWall(wallId, tokenIds);

        assertTrue(wallblocks.balanceOf(MINTER) == 0);
        assertTrue(wallblocks.balanceOf(address(wallblocks)) == 1);
    }

    function testUnstakeNFTsFromWall() public {
        uint256 wallId = 1;
        uint256 x = 1;
        uint256 y = 1;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);
        vm.prank(wallblocks.owner());
        wallblocks.setActiveMint(true);

        vm.prank(MINTER);
        wallblocks.mintBlock{value: price}(wallId, x, y);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.prank(MINTER);
        wallblocks.stakeNFTsForWall(wallId, tokenIds);

        vm.prank(MINTER);
        wallblocks.unstakeNFTsFromWall(wallId, tokenIds);

        assertTrue(wallblocks.balanceOf(MINTER) == 1);
        assertTrue(wallblocks.balanceOf(address(wallblocks)) == 0);
    }

    function testMintSpecialNFT() public {
        uint256 wallId = 1;
        uint256 x = 1;
        uint256 y = 1;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 1, 1, price);
        vm.prank(wallblocks.owner());
        wallblocks.setActiveMint(true);

        vm.prank(MINTER);
        wallblocks.mintBlock{value: price}(wallId, x, y);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.prank(MINTER);
        wallblocks.stakeNFTsForWall(wallId, tokenIds);

        vm.prank(MINTER);
        wallblocks.mintSpecialNFT(wallId);

        assertTrue(wallblocks.balanceOf(MINTER) == 1);
        assertTrue(wallblocks.ownerOf(1000000000) == MINTER);
    }

    function testWithdrawAndDeposit() public {
        uint256 initialBalance = address(wallblocks).balance;
        uint256 depositAmount = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.deposit{value: depositAmount}();

        assertEq(address(wallblocks).balance, initialBalance + depositAmount);

        vm.prank(wallblocks.owner());
        wallblocks.withdraw();

        assertEq(address(wallblocks).balance, 0);
    }

    function testWithdrawTo() public {
        uint256 depositAmount = 1 ether;
        uint256 withdrawAmount = 0.5 ether;

        vm.prank(wallblocks.owner());
        wallblocks.deposit{value: depositAmount}();

        vm.prank(wallblocks.owner());
        wallblocks.withdrawTo(MINTER, withdrawAmount);

        assertEq(address(wallblocks).balance, depositAmount - withdrawAmount);
    }

    function testSetCategoryBaseURI() public {
        uint256 category = 1;
        string memory baseURI = "https://example.com/";

        vm.prank(wallblocks.owner());
        wallblocks.setCategoryBaseURI(category, baseURI);

        uint256 wallId = 1;
        uint256 x = 1;
        uint256 y = 1;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);
        vm.prank(wallblocks.owner());
        wallblocks.setActiveMint(true);

        vm.prank(MINTER);
        wallblocks.mintBlock{value: price}(wallId, x, y);

        string memory tokenURI = wallblocks.tokenURI(1);
        assertTrue(
            keccak256(bytes(tokenURI)) ==
                keccak256(bytes(string(abi.encodePacked(baseURI, "1.json"))))
        );
    }

    function testGetMintedNFTsForWall() public {
        uint256 wallId = 1;
        uint256 x = 1;
        uint256 y = 1;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);
        vm.prank(wallblocks.owner());
        wallblocks.setActiveMint(true);

        vm.prank(MINTER);
        wallblocks.mintBlock{value: price}(wallId, x, y);

        uint256[] memory mintedNFTs = wallblocks.getMintedNFTsForWall(wallId);
        assertTrue(mintedNFTs.length == 1);
        assertTrue(mintedNFTs[0] == 1);
    }

    function testStakeNFTsForNonExistentWall() public {
        uint256 wallId = 1;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.prank(MINTER);
        vm.expectRevert(WallBlocks.WallDoesNotExist.selector);
        wallblocks.stakeNFTsForWall(wallId, tokenIds);
    }

    function testStakeNFTsWithEmptyArray() public {
        uint256 wallId = 1;
        uint256 x = 1;
        uint256 y = 1;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);
        vm.prank(wallblocks.owner());
        wallblocks.setActiveMint(true);

        vm.prank(MINTER);
        wallblocks.mintBlock{value: price}(wallId, x, y);

        uint256[] memory tokenIds = new uint256[](0);

        vm.prank(MINTER);
        vm.expectRevert(WallBlocks.NoNFTsProvided.selector);
        wallblocks.stakeNFTsForWall(wallId, tokenIds);
    }

    function testUnstakeNFTsWithEmptyArray() public {
        uint256 wallId = 1;
        uint256 x = 1;
        uint256 y = 1;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);
        vm.prank(wallblocks.owner());
        wallblocks.setActiveMint(true);

        vm.prank(MINTER);
        wallblocks.mintBlock{value: price}(wallId, x, y);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.prank(MINTER);
        wallblocks.stakeNFTsForWall(wallId, tokenIds);

        uint256[] memory emptyTokenIds = new uint256[](0);

        vm.prank(MINTER);
        vm.expectRevert(WallBlocks.NoNFTsProvided.selector);
        wallblocks.unstakeNFTsFromWall(wallId, emptyTokenIds);
    }

    function testUnstakeNFTsWithInsufficientStake() public {
        uint256 wallId = 1;
        uint256 x = 1;
        uint256 y = 1;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);
        vm.prank(wallblocks.owner());
        wallblocks.setActiveMint(true);

        vm.prank(MINTER);
        wallblocks.mintBlock{value: price}(wallId, x, y);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.prank(MINTER);
        wallblocks.stakeNFTsForWall(wallId, tokenIds);

        uint256[] memory excessTokenIds = new uint256[](2);
        excessTokenIds[0] = 1;
        excessTokenIds[1] = 2;

        vm.prank(MINTER);
        vm.expectRevert(WallBlocks.NotEnoughNFTsStaked.selector);
        wallblocks.unstakeNFTsFromWall(wallId, excessTokenIds);
    }

    function testMintSpecialNFTWithoutFullyCompletedWall() public {
        uint256 wallId = 1;
        uint256 x = 1;
        uint256 y = 1;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);
        vm.prank(wallblocks.owner());
        wallblocks.setActiveMint(true);

        vm.prank(MINTER);
        wallblocks.mintBlock{value: price}(wallId, x, y);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.prank(MINTER);
        wallblocks.stakeNFTsForWall(wallId, tokenIds);

        vm.prank(MINTER);
        vm.expectRevert(WallBlocks.WallNotFullyCompleted.selector);
        wallblocks.mintSpecialNFT(wallId);
    }

    function testTokenURIWithNonExistentToken() public {
        uint256 nonExistentTokenId = 1;

        vm.expectRevert(
            abi.encodeWithSelector(WallBlocks.TokenDoesNotExist.selector)
        );
        wallblocks.tokenURI(nonExistentTokenId);
    }

    function testTokenURIWithoutBaseURI() public {
        uint256 wallId = 1;
        uint256 x = 1;
        uint256 y = 1;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);
        vm.prank(wallblocks.owner());
        wallblocks.setActiveMint(true);

        vm.prank(MINTER);
        wallblocks.mintBlock{value: price}(wallId, x, y);

        vm.expectRevert(WallBlocks.BaseURINotSet.selector);
        wallblocks.tokenURI(1);
    }

    function testWithdrawWhenContractBalanceIsZero() public {
        vm.prank(wallblocks.owner());
        vm.expectRevert(
            abi.encodeWithSelector(WallBlocks.ContractBalanceIsZero.selector)
        );
        wallblocks.withdraw();
    }

    function testWithdrawToWhenInsufficientBalance() public {
        uint256 withdrawAmount = 1 ether;

        vm.prank(wallblocks.owner());
        vm.expectRevert(
            abi.encodeWithSelector(WallBlocks.InsufficientBalance.selector)
        );
        wallblocks.withdrawTo(MINTER, withdrawAmount);
    }

    function testMintBlockWhenWallOrBlockDoesNotExist() public {
        uint256 wallId = 1;
        uint256 x = 4;
        uint256 y = 4;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);
        vm.prank(wallblocks.owner());
        wallblocks.setActiveMint(true);

        vm.prank(MINTER);
        vm.expectRevert(
            abi.encodeWithSelector(
                WallBlocks
                    .WallIssue__TheWallDoNotExist__OR__TheBlockDoNotExist
                    .selector
            )
        );
        wallblocks.mintBlock{value: price}(wallId, x, y);
    }

    function testMintBlockWhenBlockAlreadyMinted() public {
        uint256 wallId = 1;
        uint256 x = 1;
        uint256 y = 1;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);
        vm.prank(wallblocks.owner());
        wallblocks.setActiveMint(true);

        vm.prank(MINTER);
        wallblocks.mintBlock{value: price}(wallId, x, y);

        vm.prank(MINTER);
        vm.expectRevert(
            abi.encodeWithSelector(WallBlocks.BlockAlreadyMinted.selector)
        );
        wallblocks.mintBlock{value: price}(wallId, x, y);
    }

    function testSetWallWithInvalidWallIdSequence() public {
        uint256 wallId = 2;
        uint256 x = 3;
        uint256 y = 3;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        vm.expectRevert(
            abi.encodeWithSelector(WallBlocks.WallIdSequenceError.selector)
        );
        wallblocks.setWall(wallId, x, y, price);
    }

    function testGetBlockDetailsOfNonExistentToken() public {
        uint256 nonExistentTokenId = 1;

        vm.expectRevert(
            abi.encodeWithSelector(WallBlocks.TokenDoesNotExist.selector)
        );
        wallblocks.getBlockDetails(nonExistentTokenId);
    }

    function testWhitelistMintWhenWallOrBlockDoesNotExist() public {
        uint256 wallId = 1;
        uint256 x = 4;
        uint256 y = 4;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);

        bytes32[] memory proof = new bytes32[](1);
        proof[0] = keccak256(abi.encodePacked(MINTER));
        vm.prank(wallblocks.owner());
        wallblocks.setMerkleRoot(proof[0]);

        vm.prank(MINTER);
        vm.expectRevert(
            abi.encodeWithSelector(
                WallBlocks
                    .WallIssue__TheWallDoNotExist__OR__TheBlockDoNotExist
                    .selector
            )
        );
        wallblocks.whitelistMint{value: price}(proof, wallId, x, y);
    }

    function testWhitelistMintWhenBlockAlreadyMinted() public {
        uint256 wallId = 1;
        uint256 x = 1;
        uint256 y = 1;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);

        bytes32[] memory proof = new bytes32[](1);
        proof[0] = keccak256(abi.encodePacked(MINTER));
        vm.prank(wallblocks.owner());
        wallblocks.setMerkleRoot(proof[0]);

        vm.prank(MINTER);
        wallblocks.whitelistMint{value: price}(proof, wallId, x, y);

        vm.prank(MINTER);
        vm.expectRevert(
            abi.encodeWithSelector(WallBlocks.BlockAlreadyMinted.selector)
        );
        wallblocks.whitelistMint{value: price}(proof, wallId, x, y);
    }

    function testStakeNFTsWhenTokenDoesNotBelongToWall() public {
        uint256 wallId1 = 1;
        uint256 wallId2 = 2;
        uint256 x = 1;
        uint256 y = 1;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId1, 3, 3, price);
        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId2, 3, 3, price);
        vm.prank(wallblocks.owner());
        wallblocks.setActiveMint(true);

        vm.prank(MINTER);
        wallblocks.mintBlock{value: price}(wallId1, x, y);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.prank(MINTER);
        vm.expectRevert(
            abi.encodeWithSelector(
                WallBlocks.NFTDoesNotBelongToTheSpecifiedWall.selector
            )
        );
        wallblocks.stakeNFTsForWall(wallId2, tokenIds);
    }

    function testUnstakeNFTsWhenTokenNotStakedByUser() public {
        uint256 wallId = 1;
        uint256 x = 1;
        uint256 y = 1;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);
        vm.prank(wallblocks.owner());
        wallblocks.setActiveMint(true);

        vm.prank(MINTER);
        wallblocks.mintBlock{value: price}(wallId, x, y);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.prank(MINTER2);
        vm.expectRevert(
            abi.encodeWithSelector(WallBlocks.NFTNotStakedByUser.selector)
        );
        wallblocks.unstakeNFTsFromWall(wallId, tokenIds);
    }

    function testIsWallCompletedByUserWhenWallDoesNotExist() public {
        uint256 nonExistentWallId = 1;

        vm.expectRevert(
            abi.encodeWithSelector(WallBlocks.WallDoesNotExist.selector)
        );
        wallblocks.isWallCompletedByUser(nonExistentWallId, MINTER);
    }

    function testMintBlockWhenTokenIdExceedsMaxIdForCurrentWall() public {
        uint256 wallId = 1;
        uint256 x = 3;
        uint256 y = 3;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);
        vm.prank(wallblocks.owner());
        wallblocks.setActiveMint(true);

        vm.prank(MINTER);
        vm.expectRevert(
            abi.encodeWithSelector(
                WallBlocks
                    .WallIssue__TheWallDoNotExist__OR__TheBlockDoNotExist
                    .selector
            )
        );
        wallblocks.mintBlock{value: price}(wallId, x, y);
    }

    function testWhitelistMintWhenTokenIdExceedsMaxIdForCurrentWall() public {
        uint256 wallId = 1;
        uint256 x = 3;
        uint256 y = 3;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, 3, 3, price);

        bytes32[] memory proof = new bytes32[](1);
        proof[0] = keccak256(abi.encodePacked(MINTER));
        vm.prank(wallblocks.owner());
        wallblocks.setMerkleRoot(proof[0]);

        vm.prank(MINTER);
        vm.expectRevert(
            abi.encodeWithSelector(
                WallBlocks
                    .WallIssue__TheWallDoNotExist__OR__TheBlockDoNotExist
                    .selector
            )
        );
        wallblocks.whitelistMint{value: price}(proof, wallId, x, y);
    }

    function testSetWallAndCheckMaxTokenIdPerWall() public {
        uint256 wallId = 1;
        uint256 x = 3;
        uint256 y = 3;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, x, y, price);

        uint256 expectedMaxTokenId = x * y;
        uint256 actualMaxTokenId = wallblocks.getMaxTokenIdPerWall(wallId);
        assertEq(actualMaxTokenId, expectedMaxTokenId);
    }

    function testGetMintedNFTsForWallWhenNoBlocksMinted() public {
        uint256 wallId = 1;
        uint256 x = 3;
        uint256 y = 3;
        uint256 price = 1 ether;

        vm.prank(wallblocks.owner());
        wallblocks.setWall(wallId, x, y, price);

        uint256[] memory mintedNFTs = wallblocks.getMintedNFTsForWall(wallId);
        assertEq(mintedNFTs.length, 0);
    }
}
