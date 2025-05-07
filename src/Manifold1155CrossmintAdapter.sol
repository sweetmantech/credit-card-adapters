// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC1155LazyPayableClaim} from "./interfaces/IERC1155LazyPayableClaim.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IERC1155} from "./interfaces/IERC1155.sol";
import {IWETH9} from "./interfaces/IWETH9.sol";
import {ISwapRouter02} from "./interfaces/uniswap/ISwapRouter02.sol";
import {IQuoterV2} from "./interfaces/uniswap/IQuoterV2.sol";
import {IUniswapV3Factory} from "./interfaces/uniswap/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "./interfaces/uniswap/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/// @title Manifold1155CrossmintAdapter
contract Manifold1155CrossmintAdapter is ERC1155Holder {
    event IncomingEthValue(uint256 price, uint256 fee, uint256 totalAmount);

    uint256 public constant MINT_FEE = 0.0005 ether;
    address private owner;

    struct SwapData {
        address swapFactory;
        address swapRouter;
        address quoterV2;
        address tokenIn;
        uint24 fee;
    }

    struct MintData {
        address extensionContract;
        address creatorContractAddress;
        uint256 instanceId;
        uint16 mintCount;
        uint32[] mintIndices;
        bytes32[][] merkleProofs;
    }

    constructor() {
        owner = msg.sender;
    }

    function mint(SwapData memory swapData, MintData memory mintData, address to) public payable {
        IERC1155LazyPayableClaim.Claim memory claim = IERC1155LazyPayableClaim(mintData.extensionContract).getClaim(
            mintData.creatorContractAddress, mintData.instanceId
        );

        bool isErc20Token = claim.erc20 != address(0);

        uint256 totalMintFee = MINT_FEE * mintData.mintCount;
        uint256 totalClaimPrice = claim.cost * mintData.mintCount;

        if (isErc20Token) {
            uint256 amountIn = handleErc20Mint(swapData, claim.erc20, totalClaimPrice);
            IERC20(claim.erc20).approve(mintData.extensionContract, totalClaimPrice);
            require(msg.value > amountIn + totalMintFee, "Insufficient ETH");
            emit IncomingEthValue(amountIn, totalMintFee, amountIn + totalMintFee);
        } else {
            require(msg.value > totalClaimPrice + totalMintFee, "Insufficient ETH");
            emit IncomingEthValue(totalClaimPrice, totalMintFee, totalClaimPrice + totalMintFee);
        }

        mintBatch(mintData, claim.tokenId, to, totalMintFee);
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
        return msg.value - amountIn;
    }

    function mintBatch(MintData memory mintData, uint256 tokenId, address to, uint256 totalMintFee) internal {
        IERC1155LazyPayableClaim(mintData.extensionContract).mintBatch{value: totalMintFee}(
            mintData.creatorContractAddress,
            mintData.instanceId,
            mintData.mintCount,
            mintData.mintIndices,
            mintData.merkleProofs,
            address(this)
        );
        IERC1155(mintData.creatorContractAddress).safeTransferFrom(address(this), to, tokenId, mintData.mintCount, "");
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
