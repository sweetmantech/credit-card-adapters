// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "./interfaces/IERC20.sol";
import {IWETH9} from "./interfaces/IWETH9.sol";
import {ISTPV2} from "./interfaces/ISTPV2.sol";
import {ISwapRouter02} from "./interfaces/uniswap/ISwapRouter02.sol";
import {IQuoterV2} from "./interfaces/uniswap/IQuoterV2.sol";
import {IUniswapV3Factory} from "./interfaces/uniswap/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "./interfaces/uniswap/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {ContractView} from "./libraries/STPV2/Views.sol";
import {TierLib} from "./libraries/STPV2/TierLib.sol";

/// @title HypersubCrossmintAdapter
contract HypersubCrossmintAdapter is ERC721Holder {
    address private owner;

    struct SwapData {
        address swapFactory;
        address swapRouter;
        address quoterV2;
        address tokenIn;
        uint24 fee;
    }

    constructor() {
        owner = msg.sender;
    }

    function mint(SwapData memory swapData, address subscription, uint16 tierId, address to) public payable {
        uint256 balanceOf = ISTPV2(subscription).balanceOf(to);
        ContractView memory detail = ISTPV2(subscription).contractDetail();
        TierLib.State memory tier = ISTPV2(subscription).tierDetail(tierId);

        uint256 price = balanceOf > 0 ? tier.params.pricePerPeriod : tier.params.initialMintPrice;
        bool isErc20Token = detail.currency != address(0);
        
        if (isErc20Token) {
            uint256 amountIn = handleErc20Mint(swapData, detail.currency, price);
            IERC20(detail.currency).approve(subscription, price);
            require(msg.value > amountIn, "Insufficient ETH");
        } else {
            require(msg.value > price, "Insufficient ETH");
        }
        ISTPV2(subscription).mintFor{value: isErc20Token ? 0 : price}(to, price);
    }

    function handleErc20Mint(SwapData memory swapData, address tokenOut, uint256 amountOut)
        internal
        returns (uint256)
    {
        address pool = IUniswapV3Factory(swapData.swapFactory).getPool(swapData.tokenIn, tokenOut, swapData.fee);
        uint160 liquidity = IUniswapV3Pool(pool).liquidity();

        IQuoterV2.QuoteExactOutputSingleParams memory quoteExactOutputParams = IQuoterV2.QuoteExactOutputSingleParams({
            tokenIn: swapData.tokenIn,
            tokenOut: tokenOut,
            amount: amountOut,
            fee: swapData.fee,
            sqrtPriceLimitX96: liquidity
        });
        uint256 amountIn;
        uint160 sqrtPriceX96After;
        uint32 initializedTicksCrossed;
        uint256 gasEstimate;

        (amountIn, sqrtPriceX96After, initializedTicksCrossed, gasEstimate) =
            IQuoterV2(swapData.quoterV2).quoteExactOutputSingle(quoteExactOutputParams);

        require(msg.value >= amountIn, "Insufficient ETH");
        IWETH9(swapData.tokenIn).approve(swapData.swapRouter, amountIn);
        ISwapRouter02.ExactOutputSingleParams memory params = ISwapRouter02.ExactOutputSingleParams({
            tokenIn: swapData.tokenIn,
            tokenOut: tokenOut,
            fee: swapData.fee,
            recipient: address(this),
            amountOut: amountOut,
            amountInMaximum: amountIn,
            sqrtPriceLimitX96: liquidity
        });
        ISwapRouter02(swapData.swapRouter).exactOutputSingle{value: amountIn}(params);
        return amountIn;
    }

    /// @notice Fallback function to receive ETH
    receive() external payable {}

    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(address(msg.sender)).transfer(amount);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }
}
