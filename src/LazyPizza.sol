// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract LazyPizza is ERC721Enumerable, Ownable, ReentrancyGuard {
    // Errors
    error NotActiveMint(); // Mint is not active
    error InsufficientBalance(); // Insufficient balance error
    error NotEnoughEth(); // Not enough ETH sent error

    // Variables
    string public baseURI;
    uint256 public publicPrice = 5000000000000000; //0,005 ETH
    uint256 private lastId = 0;
    bool private activeMint = false;

    //Events
    event WrongPizza(address indexed client);
    event PizzaSbagliata(address indexed client, bool indexed isPizzaSbagliata);

    // Constructor

    constructor() ERC721("LazyPizza", "LZPZ") Ownable(msg.sender) {}

    // Withdraw Contract functions
    function withdraw() public onlyOwner {
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

    // Base URI functions

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    // Minting Functions

    function setActiveMint(bool _activeMint) public onlyOwner {
        activeMint = _activeMint;
    }

    function mintPizza() public payable nonReentrant {
        if (!activeMint) {
            revert NotActiveMint();
        }

        if (msg.value < publicPrice) {
            revert NotEnoughEth();
        }

        _safeMint(msg.sender, lastId + 1);
        lastId++;
    }

    //  Getter Functions

    function getLastId() external view returns (uint256) {
        return lastId;
    }

    function getActiveMint() external view returns (bool) {
        return activeMint;
    }
}
