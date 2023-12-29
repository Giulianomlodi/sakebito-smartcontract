// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract LazyPizzeria is
    ERC721Enumerable,
    Ownable,
    ReentrancyGuard,
    VRFConsumerBaseV2
{
    // Errors
    error NotActiveMint(); // Mint is not active
    error ContractBalanceIsZero(); // Contract is empty
    error InsufficientBalance(); // Insufficient balance error
    error NotEnoughtValue(); // Not enough ETH sent error
    error YouCantSelectPizzaSbagliata(); // User can't select pizza sbagliata
    error TokenUriNotFound(); // Token URI not found

    // Variables
    string public baseURI;

    bool public isPizzaSbagliata = false;

    uint256 public publicPrice = 100000000000000; //0,0001 ETH TEST VALUE

    uint256 public numeroRandom; // Per test da eliminare

    uint256 private lastId = 0;
    bool private activeMint = false;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    // Pizza URI
    string private s_MargheritaURI;
    string private s_MarinaraURI;
    string private s_DiavolaURI;
    string private s_CapricciosaURI;
    string private s_SbagliataURI;

    enum pizzaType {
        Margherita,
        Marinara,
        Diavola,
        Capricciosa,
        Sbagliata
    }

    uint256 private s_randomnessInterval = uint(type(pizzaType).max) + 1;

    //UNISWAP ROUTER ADDRESS
    address private constant UNISWAP_ROUTER_ADDRESS =
        0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008; // SEPOLIA TEST

    //UNISWAP V2 ROUTER
    IUniswapV2Router02 private constant UNISWAP_V2_ROUTER =
        IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);

    // Address of the LINK token
    address private constant LINK_TOKEN =
        0x779877A7B0D9E8603169DdbD7836e478b4624789;

    // Create a mapping between the tokenId and the pizzaType
    mapping(uint256 => pizzaType) public pizzaTypes;

    // Create a mapping between the requestId and the user address
    mapping(uint256 => address) private requestIdToSender;

    // Create a mapping between the tokenId and the pizzaType chosen by the user
    mapping(uint256 => pizzaType) private userPizzaTokenId;

    //Events
    event AirMint(address indexed client, uint256 indexed tokenId); // TEST EVENT TO BE DELETED
    event WrongPizza(address indexed client);
    event PizzaSbagliata(address indexed client, bool indexed isPizzaSbagliata);

    // Constructor

    constructor(
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        string memory margheritaUri,
        string memory marinaraUri,
        string memory diavolaUri,
        string memory capricciosaUri,
        string memory sbagliataUri
    )
        ERC721("LazyPizza", "LZPZ")
        Ownable(msg.sender)
        VRFConsumerBaseV2(vrfCoordinator)
    {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_MargheritaURI = margheritaUri;
        s_MarinaraURI = marinaraUri;
        s_DiavolaURI = diavolaUri;
        s_CapricciosaURI = capricciosaUri;
        s_SbagliataURI = sbagliataUri;
    }

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

    // Minting Functions

    function setActiveMint(bool _activeMint) public onlyOwner {
        activeMint = _activeMint;
    }

    function mintPizza(pizzaType _pizzaType) public payable nonReentrant {
        if (!activeMint) {
            revert NotActiveMint();
        }

        if (msg.value < publicPrice) {
            revert NotEnoughtValue();
        }

        if (_pizzaType == pizzaType.Sbagliata) {
            revert YouCantSelectPizzaSbagliata();
        }

        // Execute the swap before minting to avoid reentrancy concerns
        _swapEthForLink((msg.value * 40) / 100);

        // Check if the swap operation was successful
        uint256 linkBalance = IERC20(LINK_TOKEN).balanceOf(address(this));
        if (linkBalance == 0) {
            revert InsufficientBalance();
        }

        // Fund the VRF subscription with the LINK tokens
        LinkTokenInterface linkToken = LinkTokenInterface(LINK_TOKEN);
        linkToken.transferAndCall(
            address(i_vrfCoordinator),
            linkBalance,
            abi.encode(i_subscriptionId)
        );

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //gas lane
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        requestIdToSender[requestId] = msg.sender;

        uint256 tokenId = lastId + 1;

        _safeMint(msg.sender, tokenId);
        lastId++;
        userPizzaTokenId[tokenId] = _pizzaType; // Mapping of token ID to pizza type chosen by user
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        isPizzaSbagliata = randomWords[0] % s_randomnessInterval == 0;
        numeroRandom = randomWords[0];
        emit PizzaSbagliata(msg.sender, isPizzaSbagliata);

        // If the pizza is sbagliata update the mapping of the token id as a pizza sbagliata type

        pizzaTypes[lastId] = isPizzaSbagliata
            ? pizzaType.Sbagliata
            : userPizzaTokenId[lastId];

        isPizzaSbagliata = false;
    }

    // A function to fund the subscription with LINK tokens

    function _swapEthForLink(uint256 _ethAmount) private {
        // Create a path for ETH to LINK swap
        address[] memory path = new address[](2);
        path[0] = UNISWAP_V2_ROUTER.WETH();
        path[1] = LINK_TOKEN;

        // Make the swap
        UNISWAP_V2_ROUTER.swapExactETHForTokens{value: _ethAmount}(
            0, // Accept any amount of LINK
            path,
            address(this), // Contract address to receive LINK
            block.timestamp + 15 minutes // Set a deadline for the swap to prevent miner manipulation
        );
    }

    // URI functions

    function getPizzaTypeAsString(
        pizzaType _type
    ) internal pure returns (string memory) {
        if (_type == pizzaType.Margherita) {
            return "Margherita";
        } else if (_type == pizzaType.Marinara) {
            return "Marinara";
        } else if (_type == pizzaType.Diavola) {
            return "Diavola";
        } else if (_type == pizzaType.Capricciosa) {
            return "Capricciosa";
        } else {
            // pizzaType.Sbagliata
            return "Sbagliata";
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireOwned(tokenId);

        // if userPizzaTokenId is 0 it means that the pizza is margherita and the image URI is the margherita URI
        string memory imageURI = userPizzaTokenId[tokenId] ==
            pizzaType.Margherita
            ? s_MargheritaURI
            : userPizzaTokenId[tokenId] == pizzaType.Marinara
            ? s_MarinaraURI
            : userPizzaTokenId[tokenId] == pizzaType.Diavola
            ? s_DiavolaURI
            : userPizzaTokenId[tokenId] == pizzaType.Capricciosa
            ? s_CapricciosaURI
            : s_SbagliataURI;

        string memory attributes = string(
            abi.encodePacked(
                '"attributes": [{"value": "',
                getPizzaTypeAsString(userPizzaTokenId[tokenId]),
                '"}]'
            )
        );

        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name(), // Original NFT name
                                " #", // Separator
                                Strings.toString(tokenId), // Convert tokenId to string and append
                                '", "description":"A Pizza made by GENny! Sometimes you get what you ask, sometimes not! 100% on Chain!", ',
                                attributes,
                                ', "image":"',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function setSbagliataUri(string memory _newSbagliataUri) public onlyOwner {
        s_SbagliataURI = _newSbagliataUri;
    }

    //  Getter Functions

    function getLastId() external view returns (uint256) {
        return lastId;
    }

    function getActiveMint() external view returns (bool) {
        return activeMint;
    }

    function getMenuLenght() external view returns (uint256) {
        return s_randomnessInterval;
    }

    function getPizzaTypeFromTokenId(
        uint256 _tokenId
    ) external view returns (pizzaType) {
        return pizzaTypes[_tokenId];
    }
}
