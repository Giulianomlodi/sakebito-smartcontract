// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LazyPizzeria is ERC721Enumerable, Ownable, ReentrancyGuard {
    constructor() ERC721("LazyPizza", "LZPZ") Ownable(msg.sender) {}

    // Errors
    error TokenUriNotFound(); // Token URI not found
}
