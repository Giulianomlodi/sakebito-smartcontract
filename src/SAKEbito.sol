// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title SAKEbito second implementation
 * @author otakun_0x
 * @notice This contract manages the SAKEbito NFT collection, representing membership to an exclusive Sake discovery community.
 * @dev Implements ERC721 token standard with batched minting functionality and whitelist support.
 * @custom:website https://www.sakebito.xyz/
 *
 * SAKEbito unveils the finest Sake hidden in Japan's little villages to the world.
 * It redefines the pathway to hidden Japanese Sake, unveiling centuries-old craftsmanship of Sake brewing.
 * The project connects curious minds in real life beyond borders, enabled by web3 digital innovation.
 *
 * Features:
 * - Lifetime Membership
 * - Exclusive offerings for members
 * - Members-only premium Sake tasting
 * - Priority prices for members
 * - Discovery of finest Sake hidden in Japan's villages
 */
contract SAKEbito is ERC721, Ownable, ReentrancyGuard {
    // Custom errors
    error MintNotActive();
    error NoBatchActive();
    error BatchNotActive();
    error BatchAlreadyCompleted();
    error InsufficientPayment();
    error BatchLimitReached();
    error BatchAlreadyEnded();
    error InvalidProof();
    error PreviousBatchNotEnded();
    error BatchDoesNotExist();
    error WhitelistAlreadyClaimed();
    error InvalidMintAmount();
    error NoActiveBatch();
    error TransferFailed();

    /**
     * @dev Struct to store batch information
     */
    struct Batch {
        uint256 id;
        string name;
        string baseUri;
        uint256 cost;
        uint256 limit;
        bool active;
        bool ended;
        uint256 minted;
    }

    // State variables
    bool public activeMint;
    uint256 public currentBatchId;
    address public immutable devAddress;
    address public immutable adminAddress;
    mapping(uint256 => Batch) public batches;
    bytes32 public merkleRoot;

    // Mappings
    mapping(address => bool) public whitelistClaimed;

    // Constants
    uint256 public constant MAX_MINT_PER_TX = 3;
    uint256 public constant DEV_SHARE_PERCENTAGE = 10;
    uint256 public constant ADMIN_SHARE_PERCENTAGE = 90;

    // Events
    event BatchCreated(uint256 indexed batchId, string name, uint256 limit);
    event BatchActivated(uint256 indexed batchId);
    event BatchDeactivated(uint256 indexed batchId);
    event BatchEnded(uint256 indexed batchId);
    event NFTMinted(
        address indexed to,
        uint256 indexed tokenId,
        uint256 indexed batchId
    );
    event MerkleRootUpdated(bytes32 newMerkleRoot);
    event BatchBaseURIUpdated(uint256 indexed batchId, string newBaseURI);
    event PaymentDistributed(
        address indexed devAddress,
        address indexed adminAddress,
        uint256 devAmount,
        uint256 adminAmount
    );

    /**
     * @dev Constructor to initialize the SAKEbito contract
     * @param _devAddress The address to receive development funds - 10% of minting fees
     * @param _adminAddress The address to receive admin funds - 90% of minting fees
     */
    constructor(
        address _devAddress,
        address _adminAddress
    ) ERC721("SAKEbito", "SAKEBito") Ownable(msg.sender) {
        devAddress = _devAddress;
        adminAddress = _adminAddress;
    }

    /**
     * @dev Enables or disables minting
     * @param _activeMint Boolean to set minting state
     */
    function setActiveMint(bool _activeMint) external onlyOwner {
        activeMint = _activeMint;
    }

    /**
     * @dev Creates a new batch of NFTs
     * @param _name Name of the batch
     * @param _baseUri Base URI for the batch's metadata
     * @param _cost Cost per NFT in the batch
     * @param _limit Maximum number of NFTs in the batch
     */
    function createBatch(
        string memory _name,
        string memory _baseUri,
        uint256 _cost,
        uint256 _limit
    ) external onlyOwner {
        if (currentBatchId > 0 && !batches[currentBatchId].ended) {
            revert PreviousBatchNotEnded();
        }
        currentBatchId++;
        batches[currentBatchId] = Batch({
            id: currentBatchId,
            name: _name,
            baseUri: _baseUri,
            cost: _cost,
            limit: _limit,
            active: false,
            ended: false,
            minted: 0
        });
        emit BatchCreated(currentBatchId, _name, _limit);
    }

    /**
     * @dev Activates the current batch for minting
     */
    function activateBatch() external onlyOwner {
        Batch storage batch = batches[currentBatchId];
        if (batch.ended) revert BatchAlreadyEnded();
        batch.active = true;
        emit BatchActivated(currentBatchId);
    }

    /**
     * @dev Deactivates the current batch, pausing minting
     */
    function deactivateBatch() external onlyOwner {
        Batch storage batch = batches[currentBatchId];
        if (batch.ended) revert BatchAlreadyEnded();
        batch.active = false;
        emit BatchDeactivated(currentBatchId);
    }

    /**
     * @dev Ends the current batch, preventing further minting
     */
    function endBatch() external onlyOwner {
        Batch storage batch = batches[currentBatchId];
        if (batch.ended) revert BatchAlreadyEnded();
        batch.ended = true;
        batch.active = false;
        emit BatchEnded(currentBatchId);
    }

    /**
     * @dev Allows public minting of multiple NFTs (1 to 3)
     * @param amount The number of NFTs to mint (1 to 3)
     */
    function mint(uint256 amount) external payable nonReentrant {
        if (amount == 0 || amount > MAX_MINT_PER_TX) revert InvalidMintAmount();
        if (!activeMint) revert MintNotActive();
        if (currentBatchId == 0) revert NoBatchActive();

        Batch storage batch = batches[currentBatchId];
        if (!batch.active) revert BatchNotActive();
        if (batch.ended) revert BatchAlreadyCompleted();
        if (msg.value < batch.cost * amount) revert InsufficientPayment();
        if (batch.minted + amount > batch.limit) revert BatchLimitReached();

        _mintLogic(amount, msg.value);
    }

    /**
     * @dev Allows whitelisted addresses to mint a single NFT at a discount
     * @param _merkleProof Merkle proof to verify whitelist status
     */
    function whitelistMint(
        bytes32[] calldata _merkleProof
    ) external payable nonReentrant {
        if (!activeMint) revert MintNotActive();
        if (currentBatchId == 0) revert NoBatchActive();
        if (whitelistClaimed[msg.sender]) revert WhitelistAlreadyClaimed();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf))
            revert InvalidProof();

        Batch storage batch = batches[currentBatchId];
        if (!batch.active) revert BatchNotActive();
        if (batch.ended) revert BatchAlreadyCompleted();

        uint256 discountedCost = (batch.cost * 85) / 100; // 15% discount
        if (msg.value < discountedCost) revert InsufficientPayment();
        if (batch.minted >= batch.limit) revert BatchLimitReached();

        whitelistClaimed[msg.sender] = true;
        _mintLogic(1, msg.value);
    }

    /**
     * @dev Internal function to handle minting logic
     * @param amount The number of NFTs to mint
     * @param totalPayment The total amount of Ether received for this mint
     */
    function _mintLogic(uint256 amount, uint256 totalPayment) internal {
        Batch storage batch = batches[currentBatchId];
        uint256 startTokenId = batch.minted + 1;

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, startTokenId + i);
            emit NFTMinted(msg.sender, startTokenId + i, currentBatchId);
        }

        batch.minted += amount;

        if (batch.minted == batch.limit) {
            batch.ended = true;
            batch.active = false;
            emit BatchEnded(currentBatchId);
        }

        uint256 devShare = (totalPayment * DEV_SHARE_PERCENTAGE) / 100;
        uint256 adminShare = totalPayment - devShare;

        _distributePayment(devShare, adminShare);
    }

    /**
     * @dev Internal function to distribute payment between dev and admin
     * @param devShare Amount to be sent to the dev address
     * @param adminShare Amount to be sent to the admin address
     */
    function _distributePayment(uint256 devShare, uint256 adminShare) internal {
        (bool devSuccess, ) = payable(devAddress).call{value: devShare}("");
        (bool adminSuccess, ) = payable(adminAddress).call{value: adminShare}(
            ""
        );
        if (!devSuccess || !adminSuccess) revert TransferFailed();

        emit PaymentDistributed(devAddress, adminAddress, devShare, adminShare);
    }

    /**
     * @dev Allows the owner to mint a free NFT to a specific address
     * @param to The address to receive the free NFT
     */
    function mintTo(address to) external onlyOwner nonReentrant {
        if (currentBatchId == 0) revert NoActiveBatch();

        Batch storage batch = batches[currentBatchId];
        if (batch.ended) revert BatchAlreadyCompleted();
        if (batch.minted >= batch.limit) revert BatchLimitReached();

        uint256 tokenId = batch.minted + 1;
        _safeMint(to, tokenId);

        batch.minted += 1;

        emit NFTMinted(to, tokenId, currentBatchId);

        if (batch.minted == batch.limit) {
            batch.ended = true;
            batch.active = false;
            emit BatchEnded(currentBatchId);
        }
    }

    /**
     * @dev Returns the base URI for the current edition batch
     */
    function _baseURI() internal view override returns (string memory) {
        return batches[currentBatchId].baseUri;
    }

    /**
     * @dev Returns the URI for a given token ID
     * @param tokenId The ID of the token to query
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireOwned(tokenId);
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    /**
     * @dev Updates the Merkle root for whitelist verification
     * @param _newMerkleRoot New Merkle root to set
     */
    function updateMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
        emit MerkleRootUpdated(_newMerkleRoot);
    }

    /**
     * @dev Updates the base URI for a specific batch
     * @param _batchId ID of the batch to update
     * @param _newBaseUri New base URI to set for the batch
     */
    function updateBatchBaseURI(
        uint256 _batchId,
        string memory _newBaseUri
    ) external onlyOwner {
        if (_batchId == 0 || _batchId > currentBatchId)
            revert BatchDoesNotExist();
        batches[_batchId].baseUri = _newBaseUri;
        emit BatchBaseURIUpdated(_batchId, _newBaseUri);
    }
}
