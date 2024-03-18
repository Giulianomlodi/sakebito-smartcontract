// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract WallBlocks is ERC721Enumerable, Ownable, ReentrancyGuard {
    // Errors
    error NotActiveMint();
    error ContractBalanceIsZero();
    error InsufficientBalance();
    error NotEnoughValue();
    error WallIssue__TheWallDoNotExist__OR__TheBlockDoNotExist();
    error BlockAlreadyMinted();
    error NotWhitelisted();
    error AddressAlreadyClaimed();
    error InvalidProof();
    error NotAllBlocksCollected();
    error WallAlreadyCompleted();
    error NotTheTokenOwner();
    error WallIdSequenceError();
    error WallIssue__TheWallDoesNotExist__OR__TheBlockDoesNotExist();
    error WallNotFullyCompleted();
    error NoNFTsProvided();
    error WallDoesNotExist();
    error NFTDoesNotBelongToTheSpecifiedWall();
    error NotEnoughNFTsStaked();
    error NFTNotStakedByUser();
    error TokenDoesNotExist();
    error BaseURINotSet();

    // Structs
    struct Wall {
        uint256 x;
        uint256 y;
        bool exists;
        uint256 price; // Price for each graffiti in this wall
    }

    struct WallBlock {
        uint256 wallId;
        uint256 x;
        uint256 y;
    }

    // Merkle Root
    bytes32 public merkleRoot;

    // Variables
    bool private activeMint = false;
    uint256 private totalWalls; // Track the total number of walls
    uint256 private lastMintedSpecialNFTId = 0; // Variable to track the last minted special NFT ID
    uint256 private constant SPECIAL_NFT_START_ID = 1_000_000_000; // Starting ID for special NFTs

    // Mappings
    mapping(uint256 => WallBlock) public wallBlocks;
    mapping(string => bool) public mintedBlocks;
    mapping(uint256 => Wall) public wallDetails;
    mapping(address => bool) public whitelist;
    mapping(uint256 => string) private categoryBaseURI;
    mapping(address => mapping(uint256 => uint256[])) private stakedNFTs; // Mapping to track staked NFTs for wall completion
    mapping(uint256 => uint256) private maxTokenIdPerWall; // Maximum possible token ID for each wall

    // Events
    event NFTsStaked(
        address indexed staker,
        uint256 wallId,
        uint256[] tokenIds
    );
    event SpecialNFTMinted(address indexed recipient, uint256 tokenId);
    event NFTsUnstaked(
        address indexed staker,
        uint256 wallId,
        uint256[] tokenIds
    );

    // Constructor
    constructor() ERC721("WallBlock", "WBLOCKS") Ownable(msg.sender) {}

    // Withdraw and Deposit Functions
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert ContractBalanceIsZero();
        }
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

    // Minting Functions
    function mintBlock(
        uint256 wallId,
        uint256 x,
        uint256 y
    ) public payable nonReentrant {
        if (!activeMint) {
            revert NotActiveMint();
        }
        Wall memory wall = wallDetails[wallId];
        if (!wall.exists || x > wall.x || y > wall.y) {
            revert WallIssue__TheWallDoNotExist__OR__TheBlockDoNotExist();
        }
        if (msg.value < wall.price) {
            revert NotEnoughValue();
        }

        string memory blockKey = generateBlockKey(wallId, x, y);
        if (mintedBlocks[blockKey]) {
            revert BlockAlreadyMinted();
        }

        // Adjusted token ID calculation
        uint256 tokenId;
        if (wallId > 1) {
            uint256 startIdForCurrentWall = maxTokenIdPerWall[wallId - 1] + 1;
            tokenId = startIdForCurrentWall + (x - 1) * wall.y + (y - 1);
        } else {
            // Adjusted for the first wall to ensure IDs start from 1
            tokenId = 1 + (x - 1) * wall.y + (y - 1); // Just added 1 to the original formula
        }

        // Ensure the tokenId is within the expected range for the current wall
        uint256 maxIdForCurrentWall = (
            wallId > 1 ? maxTokenIdPerWall[wallId - 1] : 0
        ) + (wall.x * wall.y);
        if (tokenId > maxIdForCurrentWall) {
            revert WallIssue__TheWallDoNotExist__OR__TheBlockDoNotExist(); // Consider creating a more specific error for this case
        }

        wallBlocks[tokenId] = WallBlock(wallId, x, y);
        mintedBlocks[blockKey] = true;

        _safeMint(msg.sender, tokenId);
    }

    function whitelistMint(
        bytes32[] calldata _merkleProof,
        uint256 wallId,
        uint256 x,
        uint256 y
    ) public payable nonReentrant {
        if (whitelist[msg.sender]) {
            revert AddressAlreadyClaimed();
        }
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
            revert InvalidProof();
        }
        whitelist[msg.sender] = true;

        Wall memory wall = wallDetails[wallId];
        if (!wall.exists || x > wall.x || y > wall.y) {
            revert WallIssue__TheWallDoNotExist__OR__TheBlockDoNotExist();
        }
        if (msg.value < wall.price) {
            revert NotEnoughValue();
        }

        string memory blockKey = generateBlockKey(wallId, x, y);
        if (mintedBlocks[blockKey]) {
            revert BlockAlreadyMinted();
        }

        // Adjusted token ID calculation to ensure IDs start from 1 for the first wall
        uint256 tokenId;
        if (wallId > 1) {
            uint256 startIdForCurrentWall = maxTokenIdPerWall[wallId - 1] + 1;
            tokenId = startIdForCurrentWall + (x - 1) * wall.y + (y - 1);
        } else {
            // Adjusted for the first wall to ensure IDs start from 1
            tokenId = 1 + (x - 1) * wall.y + (y - 1); // Just added 1 to the original formula
        }

        // Ensure the tokenId is within the expected range for the current wall
        uint256 maxIdForCurrentWall = (
            wallId > 1 ? maxTokenIdPerWall[wallId - 1] : 0
        ) + (wall.x * wall.y);
        if (tokenId > maxIdForCurrentWall) {
            revert WallIssue__TheWallDoNotExist__OR__TheBlockDoNotExist(); // Consider creating a more specific error for this case
        }

        wallBlocks[tokenId] = WallBlock(wallId, x, y);
        mintedBlocks[blockKey] = true;

        _safeMint(msg.sender, tokenId);
    }

    // Helper Function for Block Key Generation
    function generateBlockKey(
        uint256 wallId,
        uint256 x,
        uint256 y
    ) private pure returns (string memory) {
        return string(abi.encodePacked(wallId, "_", x, "_", y));
    }

    // Modified stakeNFTsForWall function
    function stakeNFTsForWall(
        uint256 wallId,
        uint256[] calldata tokenIds
    ) external nonReentrant {
        if (tokenIds.length == 0) {
            revert NoNFTsProvided();
        }
        Wall memory wall = wallDetails[wallId];
        if (!wall.exists) {
            revert WallDoesNotExist();
        }

        for (uint i = 0; i < tokenIds.length; i++) {
            if (ownerOf(tokenIds[i]) != msg.sender) {
                revert NotTheTokenOwner();
            }
            if (wallBlocks[tokenIds[i]].wallId != wallId) {
                revert NFTDoesNotBelongToTheSpecifiedWall();
            }

            _transfer(msg.sender, address(this), tokenIds[i]);
            stakedNFTs[msg.sender][wallId].push(tokenIds[i]);
        }

        emit NFTsStaked(msg.sender, wallId, tokenIds);
    }

    // Modified unstakeNFTsFromWall function
    function unstakeNFTsFromWall(
        uint256 wallId,
        uint256[] calldata tokenIds
    ) external nonReentrant {
        if (tokenIds.length == 0) {
            revert NoNFTsProvided();
        }
        if (stakedNFTs[msg.sender][wallId].length < tokenIds.length) {
            revert NotEnoughNFTsStaked();
        }

        for (uint i = 0; i < tokenIds.length; i++) {
            if (!_isStakedByUser(msg.sender, wallId, tokenIds[i])) {
                revert NFTNotStakedByUser();
            }

            _transfer(address(this), msg.sender, tokenIds[i]);
            _removeStakedNFT(msg.sender, wallId, tokenIds[i]);
        }

        emit NFTsUnstaked(msg.sender, wallId, tokenIds);
    }

    // Function to check if a wall is completed by a user
    function isWallCompletedByUser(
        uint256 wallId,
        address user
    ) public view returns (bool) {
        Wall memory wall = wallDetails[wallId];
        if (!wall.exists) {
            revert WallDoesNotExist();
        }

        uint256[] memory stakedTokens = stakedNFTs[user][wallId];
        // Check if the number of staked NFTs matches the total blocks for the wall
        return stakedTokens.length == wall.x * wall.y;
    }

    // Function to mint a special NFT after completing a wall and burn all staked NFTs
    function mintSpecialNFT(uint256 wallId) external nonReentrant {
        if (!isWallCompletedByUser(wallId, msg.sender)) {
            revert WallNotFullyCompleted();
        }

        // Burn all staked NFTs for the completed wall
        uint256[] storage stakedTokens = stakedNFTs[msg.sender][wallId];
        for (uint256 i = 0; i < stakedTokens.length; i++) {
            _burn(stakedTokens[i]); // Burn each staked NFT
        }
        delete stakedNFTs[msg.sender][wallId]; // Clear the record of staked NFTs for this wall

        // Mint the special NFT
        uint256 specialNFTId = SPECIAL_NFT_START_ID + lastMintedSpecialNFTId;
        lastMintedSpecialNFTId++; // Increment after minting a special NFT

        _safeMint(msg.sender, specialNFTId);

        emit SpecialNFTMinted(msg.sender, specialNFTId);
    }

    // Helper Functions for staking/unstaking logic
    function _isStakedByUser(
        address user,
        uint256 wallId,
        uint256 tokenId
    ) private view returns (bool) {
        uint256[] storage stakedTokens = stakedNFTs[user][wallId];
        for (uint i = 0; i < stakedTokens.length; i++) {
            if (stakedTokens[i] == tokenId) {
                return true;
            }
        }
        return false;
    }

    function _removeStakedNFT(
        address user,
        uint256 wallId,
        uint256 tokenId
    ) private {
        uint256[] storage stakedTokens = stakedNFTs[user][wallId];
        for (uint i = 0; i < stakedTokens.length; i++) {
            if (stakedTokens[i] == tokenId) {
                stakedTokens[i] = stakedTokens[stakedTokens.length - 1];
                stakedTokens.pop();
                break;
            }
        }
    }

    // Override tokenURI to use category-specific base URIs
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireOwned(tokenId);
        uint256 category = wallBlocks[tokenId].wallId;
        string memory base = categoryBaseURI[category];
        if (bytes(base).length == 0) {
            revert BaseURINotSet();
        }
        return
            string(abi.encodePacked(base, Strings.toString(tokenId), ".json"));
    }

    // Function to Set Base URI for a Category
    function setCategoryBaseURI(
        uint256 category,
        string memory baseURI
    ) public onlyOwner {
        categoryBaseURI[category] = baseURI;
    }

    // Setter Functions
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWall(
        uint256 wallId,
        uint256 x,
        uint256 y,
        uint256 price
    ) public onlyOwner {
        if (wallId != totalWalls + 1) {
            revert WallIdSequenceError();
        }
        wallDetails[wallId] = Wall(x, y, true, price);
        totalWalls++;

        // Calculate and store the max token ID for this wall
        if (wallId > 1) {
            maxTokenIdPerWall[wallId] = maxTokenIdPerWall[wallId - 1] + (x * y);
        } else {
            maxTokenIdPerWall[wallId] = x * y; // For the first wall
        }
    }

    function setActiveMint(bool _activeMint) public onlyOwner {
        activeMint = _activeMint;
    }

    //  Getter Functions

    function getActiveMint() external view returns (bool) {
        return activeMint;
    }

    function getWhitelist(address _address) external view returns (bool) {
        return whitelist[_address];
    }

    function getWallDetails(
        uint256 wallId
    ) external view returns (Wall memory) {
        return wallDetails[wallId];
    }

    function getBlockDetails(
        uint256 tokenId
    ) external view returns (WallBlock memory) {
        return wallBlocks[tokenId];
    }

    function getMintedNFTsForWall(
        uint256 wallId
    ) public view returns (uint256[] memory) {
        Wall memory wall = wallDetails[wallId];
        uint256[] memory mintedNFTs = new uint256[](wall.x * wall.y);
        uint256 mintedCount = 0;

        for (uint256 x = 1; x <= wall.x; x++) {
            for (uint256 y = 1; y <= wall.y; y++) {
                string memory blockKey = generateBlockKey(wallId, x, y);
                if (mintedBlocks[blockKey]) {
                    uint256 tokenId;
                    if (wallId > 1) {
                        uint256 startIdForCurrentWall = maxTokenIdPerWall[
                            wallId - 1
                        ] + 1;
                        tokenId =
                            startIdForCurrentWall +
                            (x - 1) *
                            wall.y +
                            (y - 1);
                    } else {
                        tokenId = 1 + (x - 1) * wall.y + (y - 1);
                    }
                    mintedNFTs[mintedCount] = tokenId;
                    mintedCount++;
                }
            }
        }

        // Resize the array to the actual minted count
        assembly {
            mstore(mintedNFTs, mintedCount)
        }

        return mintedNFTs;
    }
}
