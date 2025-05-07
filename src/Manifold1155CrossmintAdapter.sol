// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC1155LazyPayableClaim} from "./interfaces/IERC1155LazyPayableClaim.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IWETH9} from "./interfaces/IWETH9.sol";
import {ISwapRouter02} from "./interfaces/uniswap/ISwapRouter02.sol";
import {IQuoterV2} from "./interfaces/uniswap/IQuoterV2.sol";
import {IUniswapV3Factory} from "./interfaces/uniswap/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "./interfaces/uniswap/IUniswapV3Pool.sol";

/// @title Manifold1155CrossmintAdapter
contract Manifold1155CrossmintAdapter {
    event IncomingEthValue(uint256 price, uint256 fee, uint256 totalAmount);

    uint256 public constant MINT_FEE = 0.0005 ether;

    address private owner;

    constructor() {
        owner = msg.sender;
    }

    function mint(
        address swapFactory,
        address swapRouter,
        address quoterV2,
        address tokenIn,
        uint24 fee,
        address extensionContract,
        address creatorContractAddress,
        uint256 instanceId,
        uint16 mintCount,
        uint32[] calldata mintIndices,
        bytes32[][] calldata merkleProofs,
        address to
    ) public payable {
        IERC1155LazyPayableClaim.Claim memory claim =
            IERC1155LazyPayableClaim(extensionContract).getClaim(creatorContractAddress, instanceId);

        bool isErc20Token = claim.erc20 != address(0);

        uint256 totalMintFee = MINT_FEE * mintCount;
        uint256 totalClaimPrice = claim.cost * mintCount;

        if (isErc20Token) {
            address pool = IUniswapV3Factory(swapFactory).getPool(tokenIn, claim.erc20, fee);
            uint160 liquidity = IUniswapV3Pool(pool).liquidity();

            IQuoterV2.QuoteExactOutputSingleParams memory quoteExactOutputParams = IQuoterV2
                .QuoteExactOutputSingleParams({
                tokenIn: tokenIn,
                tokenOut: claim.erc20,
                amount: totalClaimPrice,
                fee: fee,
                sqrtPriceLimitX96: liquidity
            });
            uint256 amountIn;
            uint160 sqrtPriceX96After;
            uint32 initializedTicksCrossed;
            uint256 gasEstimate;

            (amountIn, sqrtPriceX96After, initializedTicksCrossed, gasEstimate) =
                IQuoterV2(quoterV2).quoteExactOutputSingle(quoteExactOutputParams);

            require(msg.value >= amountIn, "Insufficient ETH");
            IWETH9(tokenIn).approve(swapRouter, amountIn);
            ISwapRouter02.ExactOutputSingleParams memory params = ISwapRouter02.ExactOutputSingleParams({
                tokenIn: tokenIn,
                tokenOut: claim.erc20,
                fee: fee,
                recipient: address(this),
                amountOut: totalClaimPrice,
                amountInMaximum: amountIn,
                sqrtPriceLimitX96: liquidity
            });
            ISwapRouter02(swapRouter).exactOutputSingle{value: amountIn}(params);
            IERC20(claim.erc20).approve(extensionContract, totalClaimPrice);
            require(msg.value > amountIn + totalMintFee, "Insuffient ETH");
            emit IncomingEthValue(amountIn, totalMintFee, amountIn + totalMintFee);
        } else {
            require(msg.value > totalClaimPrice + totalMintFee, "Insufficient ETH");
            emit IncomingEthValue(totalClaimPrice, totalMintFee, totalClaimPrice + totalMintFee);
        }

        IERC1155LazyPayableClaim(extensionContract).mintBatch{value: 0.0005 ether}(
            creatorContractAddress, instanceId, mintCount, mintIndices, merkleProofs, to
        );
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
