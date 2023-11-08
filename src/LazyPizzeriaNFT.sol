// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LazyPizzeriaNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    // Errors
    error NotActiveMint(); // Mint is not active
    error InsufficientBalance(); // Insufficient balance error
    error NotEnoughtValue(); // Not enough value error

    // Variables
    string public baseURI;
    bool public activeMint = false;
    uint256 public lastId = 0;
    uint256 public publicPrice = 90000000000000000; //0.09 ETH

    constructor() ERC721("LazyPizza", "LZPZ") Ownable(msg.sender) {}

    // Contract functions
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

    function deposit() public payable onlyOwner {}

    function setPublicPrice(uint256 _newPrice) public onlyOwner {
        publicPrice = _newPrice;
    }

    function setLastId(uint256 _newLastId) public onlyOwner {
        lastId = _newLastId;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setActiveMint(bool _activeMint) public onlyOwner {
        activeMint = _activeMint;
    }

    function mintPublic() public payable nonReentrant {
        require(activeMint == true);

        if (msg.value < publicPrice) {
            revert NotEnoughtValue();
        }
        _safeMint(msg.sender, lastId + 1);

        lastId++;
    }

    function multiMint(uint256 _amount) public payable nonReentrant {
        require(activeMint == true);

        if (msg.value < (publicPrice * _amount)) {
            revert NotEnoughtValue();
        }

        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(msg.sender, lastId + 1 + i);
        }

        lastId += _amount;
    }

    function mintTo(address _receiver, uint256 _tokenId) public onlyOwner {
        _safeMint(_receiver, _tokenId);
    }
}
