// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract MockToken {
    mapping(address => uint256) public allowance;
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[spender] = amount;
        return true;
    }
}

contract MockSwapPool {
    uint128 private liquidityValue = 1000;

    function liquidity() external view returns (uint128) {
        return liquidityValue;
    }
}

contract MockSwapRouter {
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactOutputSingle(ExactOutputSingleParams calldata) external payable returns (uint256 amountIn) {
        return 0.1 ether;
    }
}
contract MockQuoterV2 {
    struct QuoteExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    function quoteExactOutputSingle(
        QuoteExactOutputSingleParams memory
    )   external
        returns (
            uint256 amountIn,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        ) {
            amountIn = 0.1 ether; 
            sqrtPriceX96After = 0;
            initializedTicksCrossed = 0;
            gasEstimate = 21000;
    }
}

contract MockSwapFactory {
    MockSwapPool public pool;
    event POOL(address tokenIn, address tokenOut, uint24 factoryFee);

    constructor () {
        pool = new MockSwapPool();
    }

    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address) {
        return address(pool);
    }
}

contract MockERC20Minter {
    event Minted();

    function mint(
        address mintTo,
        uint256 quantity,
        address tokenAddress,
        uint256 tokenId,
        uint256 totalValue,
        address currency,
        address,
        string calldata
    ) external payable {
        emit Minted();
    }
}