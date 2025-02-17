// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/ZoraFixedPriceSaleStrategyCrossmintAdapter.sol";
import "../src/interfaces/IZoraCreator1155.sol";

// Mock Fixed Price Sale Strategy contract
contract MockFixedPriceSaleStrategy {
    IFixedPriceSaleStrategy.SaleConfig public saleConfig;
    bool public shouldRevert;

    function setSaleConfig(IFixedPriceSaleStrategy.SaleConfig memory _config) external {
        saleConfig = _config;
    }

    function setShouldRevert(bool _shouldRevert) external {
        shouldRevert = _shouldRevert;
    }

    function sale(address, uint256) external view returns (IFixedPriceSaleStrategy.SaleConfig memory) {
        require(!shouldRevert, "Mock: forced revert");
        return saleConfig;
    }

    function requestMint(
        address,
        uint256,
        uint256,
        uint256,
        bytes memory
    ) external view returns (bool) {
        require(!shouldRevert, "Mock: forced revert");
        return true;
    }
}

// Mock Zora Creator 1155 contract
contract MockZoraCreator1155 {
    bool public shouldRevert;
    uint256 public lastTokenId;
    uint256 public lastQuantity;
    address public lastMinter;
    bytes public lastMintArgs;

    function setShouldRevert(bool _shouldRevert) external {
        shouldRevert = _shouldRevert;
    }

    function mint(
        address minter,
        uint256 tokenId,
        uint256 quantity,
        address[] calldata,
        bytes calldata mintArgs
    ) external payable returns (uint256) {
        require(!shouldRevert, "Mock: forced revert");
        lastMinter = minter;
        lastTokenId = tokenId;
        lastQuantity = quantity;
        lastMintArgs = mintArgs;
        return quantity;
    }
}

contract ZoraFixedPriceSaleStrategyCrossmintAdapterTest is Test {
    ZoraFixedPriceSaleStrategyCrossmintAdapter public adapter;
    MockFixedPriceSaleStrategy public mockStrategy;
    MockZoraCreator1155 public mockZora;

    address public constant RECIPIENT = address(0x123);
    uint256 public constant TOKEN_ID = 1;
    uint256 public constant QUANTITY = 1;
    uint96 public constant PRICE_PER_TOKEN = 0.1 ether;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        adapter = new ZoraFixedPriceSaleStrategyCrossmintAdapter();
        mockStrategy = new MockFixedPriceSaleStrategy();
        mockZora = new MockZoraCreator1155();

        // Get current block timestamp
        uint256 currentTime = block.timestamp;
        
        // Setup default sale config with safe timestamp values
        IFixedPriceSaleStrategy.SaleConfig memory config = IFixedPriceSaleStrategy.SaleConfig({
            saleStart: uint64(currentTime),  // Current time
            saleEnd: uint64(currentTime + 1 hours),  // 1 hour from now
            maxTokensPerAddress: 10,
            pricePerToken: PRICE_PER_TOKEN,
            fundsRecipient: address(this)
        });
        mockStrategy.setSaleConfig(config);
    }

    function test_Mint() public {
        uint256 totalPrice = PRICE_PER_TOKEN * QUANTITY;
        
        adapter.mint{value: totalPrice}(
            address(mockStrategy),
            address(mockZora),
            TOKEN_ID,
            QUANTITY,
            RECIPIENT,
            "commented!"
        );

        assertEq(mockZora.lastTokenId(), TOKEN_ID);
        assertEq(mockZora.lastQuantity(), QUANTITY);
        assertEq(mockZora.lastMinter(), address(mockStrategy));
        
        // Verify encoded recipient in mintArgs
        address decodedRecipient = abi.decode(mockZora.lastMintArgs(), (address));
        assertEq(decodedRecipient, RECIPIENT);
    }

    function test_RevertOnMintFailure() public {
        uint256 totalPrice = PRICE_PER_TOKEN * QUANTITY;
        mockZora.setShouldRevert(true);
        
        vm.expectRevert("Mock: forced revert");
        adapter.mint{value: totalPrice}(
            address(mockStrategy),
            address(mockZora),
            TOKEN_ID,
            QUANTITY,
            RECIPIENT,
            "commented!"
        );
    }

    function test_RevertOnStrategyMintRequestFailure() public {
        uint256 totalPrice = PRICE_PER_TOKEN * QUANTITY;
        mockStrategy.setShouldRevert(true);
        
        vm.expectRevert("Mock: forced revert");
        adapter.mint{value: totalPrice}(
            address(mockStrategy),
            address(mockZora),
            TOKEN_ID,
            QUANTITY,
            RECIPIENT,
            "commented!"
        );
    }

    function test_ReceiveEth() public {
        payable(address(adapter)).transfer(1 ether);
        assertEq(address(adapter).balance, 1 ether);
    }
} 