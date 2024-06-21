// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {WallBlocks} from "../src/Wallblocks.sol";

contract WallBlocksInteractions is Script {
    function mintBlock(
        WallBlocks wallblocks,
        uint256 wallId,
        uint256 x,
        uint256 y,
        uint256 value
    ) external {
        wallblocks.mintBlock{value: value}(wallId, x, y);
    }

    function whitelistMint(
        WallBlocks wallblocks,
        bytes32[] calldata merkleProof,
        uint256 wallId,
        uint256 x,
        uint256 y,
        uint256 value
    ) external {
        wallblocks.whitelistMint{value: value}(merkleProof, wallId, x, y);
    }

    function stakeNFTsForWall(
        WallBlocks wallblocks,
        uint256 wallId,
        uint256[] calldata tokenIds
    ) external {
        wallblocks.stakeNFTsForWall(wallId, tokenIds);
    }

    function unstakeNFTsFromWall(
        WallBlocks wallblocks,
        uint256 wallId,
        uint256[] calldata tokenIds
    ) external {
        wallblocks.unstakeNFTsFromWall(wallId, tokenIds);
    }

    function mintSpecialNFT(WallBlocks wallblocks, uint256 wallId) external {
        wallblocks.mintSpecialNFT(wallId);
    }
}
