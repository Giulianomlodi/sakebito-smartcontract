// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract WallBlocks is ERC721Enumerable, Ownable, ReentrancyGuard {
    // Errors
    error NotActiveMint(); // Mint is not active
    error ContractBalanceIsZero(); // Contract is empty
    error InsufficientBalance(); // Insufficient balance error
    error NotEnoughtValue(); // Not enough ETH sent error
    error YouCantSelectPizzaSbagliata(); // User can't select pizza sbagliata
    error TokenUriNotFound(); // Token URI not found
    error WallIssue__TheWallDoNotExist__OR__TheBlockDoNotExist(); // Il muro ha un problema o non essite o il blocco che cerchi non esiste
    error BlockAlreadyMinted(); // Il blocco è già stato mintato

    // Structs

    struct Wall {
        uint256 x;
        uint256 y;
        bool exists;
    }

    struct WallBlock {
        uint256 wallId;
        uint256 x;
        uint256 y;
    }

    // Variables
    string public baseURI;
    uint256 public publicPrice = 100000000000000; //0,0001 ETH TEST VALUE
    uint256 private lastId = 0;
    bool private activeMint = false;

    // Mappings

    mapping(uint256 => WallBlock) public wallBlocks; // Mapping of tokenId => WallBlock
    mapping(string => bool) public mintedBlocks; // Mapping of blockKey => bool if the block already is minted
    mapping(uint256 => Wall) public wallDetails; // Mapping of Wall Block Ids => Wall

    //Events
    //
    //

    // Constructor

    constructor() ERC721("WallBlock", "WBLOCKS") Ownable(msg.sender) {}

    // Withdraw Contract functions
    function withdraw() public onlyOwner {
        if (address(this).balance == 0) {
            revert ContractBalanceIsZero();
        }
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTo(address _receiver, uint256 _amount) public onlyOwner {
        uint256 balance = address(this).balance;

        if (balance < _amount) {
            revert InsufficientBalance();
        }
        payable(_receiver).transfer(_amount);
    }

    // Deposit ETH to the contract address

    function deposit() public payable onlyOwner {}

    // Setters Functions

    function setLastId(uint256 _newLastId) public onlyOwner {
        lastId = _newLastId;
    }

    function setWall(uint256 wallId, uint256 x, uint256 y) public onlyOwner {
        wallDetails[wallId] = Wall(x, y, true);
    }

    // Minting Functions

    function setActiveMint(bool _activeMint) public onlyOwner {
        activeMint = _activeMint;
    }

    function mintBlock(
        uint256 wallId,
        uint256 x,
        uint256 y
    ) public payable nonReentrant {
        if (!activeMint) {
            revert NotActiveMint();
        }
        if (msg.value < publicPrice) {
            revert NotEnoughtValue();
        }

        Wall memory details = wallDetails[wallId];
        if (!details.exists || x > details.x || y > details.y) {
            revert WallIssue__TheWallDoNotExist__OR__TheBlockDoNotExist();
        }

        string memory blockKey = generateBlockKey(wallId, x, y);
        if (mintedBlocks[blockKey]) {
            revert BlockAlreadyMinted();
        }

        uint256 tokenId = lastId + 1;
        wallBlocks[tokenId] = WallBlock(wallId, x, y);
        mintedBlocks[blockKey] = true;

        _safeMint(msg.sender, tokenId);
        lastId++;
    }

    // Funzione helper per generare la chiave del blocco
    function generateBlockKey(
        uint256 wallId,
        uint256 x,
        uint256 y
    ) private pure returns (string memory) {
        return string(abi.encodePacked(wallId, "_", x, "_", y));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    //  Getter Functions

    function getLastId() external view returns (uint256) {
        return lastId;
    }

    function getActiveMint() external view returns (bool) {
        return activeMint;
    }
}
