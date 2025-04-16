// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/ZoraERC20MinterCrossmintAdapter.sol";
import "../src/interfaces/IERC20Minter.sol";
import "../src/interfaces/IERC20.sol";

// Mock ERC20 Minter contract
contract MockERC20Minter {
    IERC20Minter.SalesConfig public saleConfig;
    bool public shouldRevert;

    function setSaleConfig(IERC20Minter.SalesConfig memory _config) external {
        saleConfig = _config;
    }

    function setShouldRevert(bool _shouldRevert) external {
        shouldRevert = _shouldRevert;
    }

    function sale(address, uint256) external view returns (IERC20Minter.SalesConfig memory) {
        require(!shouldRevert, "Mock: forced revert");
        return saleConfig;
    }

    function mint(
        address to,
        uint256 quantity,
        address tokenContract,
        uint256 tokenId,
        uint256 priceUSDC,
        address currency,
        address mintReferral,
        string memory comment
    ) external {
        require(!shouldRevert, "Mock: forced revert");
        require(priceUSDC == uint256(saleConfig.pricePerToken) * quantity, "Invalid price");
        // Minting logic would go here
    }
}

// Mock ERC20 token contract
contract MockERC20 is IERC20 {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    uint256 private _totalSupply;

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balances[from] >= amount, "Insufficient balance");
        require(allowances[from][msg.sender] >= amount, "Insufficient allowance");
        balances[from] -= amount;
        balances[to] += amount;
        allowances[from][msg.sender] -= amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }

    function mint(address to, uint256 amount) external {
        balances[to] += amount;
        _totalSupply += amount;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
}

contract ZoraERC20MinterCrossmintAdapterTest is Test {
    ZoraERC20MinterCrossmintAdapter public adapter;
    MockERC20Minter public mockMinter;
    MockERC20 public mockToken;

    address public constant RECIPIENT = address(0x123);
    uint256 public constant TOKEN_ID = 1;
    uint256 public constant QUANTITY = 1;
    uint256 public constant PRICE_PER_TOKEN = 100; // Example price in USDC
    uint256 public constant TOTAL_PRICE = PRICE_PER_TOKEN * QUANTITY;

    function setUp() public {
        adapter = new ZoraERC20MinterCrossmintAdapter();
        mockMinter = new MockERC20Minter();
        mockToken = new MockERC20();

        // Setup default sale config
        IERC20Minter.SalesConfig memory config = IERC20Minter.SalesConfig({
            saleStart: uint64(block.timestamp),
            saleEnd: uint64(block.timestamp + 1 hours),
            pricePerToken: uint96(PRICE_PER_TOKEN),
            currency: address(mockToken),
            maxTokensPerAddress: 10,
            fundsRecipient: address(this)
        });
        mockMinter.setSaleConfig(config);
        
        // Mint tokens to the test contract and approve adapter
        mockToken.mint(address(this), TOTAL_PRICE);
        mockToken.approve(address(adapter), TOTAL_PRICE);
    }

    function test_Mint() public {
        adapter.mint(
            address(mockMinter),
            RECIPIENT,
            QUANTITY,
            address(this),
            TOKEN_ID,
            address(0),
            "Test mint"
        );
    }

    function test_RevertOnInsufficientFunds() public {
        // First, reduce our token balance to simulate insufficient funds
        mockToken.transfer(address(0x1), TOTAL_PRICE - 1);
        
        vm.expectRevert("Insufficient balance");
        adapter.mint(
            address(mockMinter),
            RECIPIENT,
            QUANTITY,
            address(this),
            TOKEN_ID,
            address(0),
            "Test mint"
        );
    }

    function test_RevertOnSaleNotActive() public {
        // Set sale to inactive by configuring saleStart in the future
        IERC20Minter.SalesConfig memory config = IERC20Minter.SalesConfig({
            saleStart: uint64(block.timestamp + 1 hours), // Future start
            saleEnd: uint64(block.timestamp + 2 hours),
            pricePerToken: uint96(PRICE_PER_TOKEN),
            currency: address(mockToken),
            maxTokensPerAddress: 10,
            fundsRecipient: address(this)
        });
        mockMinter.setSaleConfig(config);

        vm.expectRevert(abi.encodeWithSelector(ZoraERC20MinterCrossmintAdapter.SaleNotActive.selector));
        adapter.mint(
            address(mockMinter),
            RECIPIENT,
            QUANTITY,
            address(this),
            TOKEN_ID,
            address(0),
            "Test mint"
        );
    }
}