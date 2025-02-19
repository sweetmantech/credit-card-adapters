// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ICreatorCommands} from "./interfaces/ICreatorCommands.sol";
import {IZoraCreator1155} from "./interfaces/IZoraCreator1155.sol";
import {IMinter1155} from "./interfaces/IMinter1155.sol";
import {IFixedPriceSaleStrategy} from "./interfaces/IFixedPriceSaleStrategy.sol";

/// @title ZoraFixedPriceSaleStrategyCrossmintAdapter
/// @notice Adapter contract for interacting with ZoraFixedPriceSaleStrategy
contract ZoraFixedPriceSaleStrategyCrossmintAdapter {
    /// @notice Error thrown when insufficient funds are sent
    error InsufficientFunds();
    /// @notice Error thrown when sale is not active
    error SaleNotActive();

    /// @notice Mint tokens using the Fixed Price Sale Strategy
    /// @param tokenContract Target Zora1155Creator contract address
    /// @param tokenId Token ID to mint
    /// @param quantity Number of tokens to mint
    /// @param priceFixedSaleStrategy Address of the Fixed Price Sale Strategy contract
    /// @param to Recipient address for the minted tokens
    /// @param comment The comment to pass to the minter
    function mint(
        address tokenContract,
        uint256 tokenId,
        uint256 quantity,
        address priceFixedSaleStrategy,
        address to,
        string memory comment
    ) public payable {
        IFixedPriceSaleStrategy.SaleConfig memory config =
            IFixedPriceSaleStrategy(priceFixedSaleStrategy).sale(tokenContract, tokenId);
        
        // Validate sale is active
        if (block.timestamp < config.saleStart || block.timestamp > config.saleEnd) {
            revert SaleNotActive();
        }

        // Calculate total price
        uint256 totalPrice = uint256(config.pricePerToken) * quantity;
        if (msg.value < totalPrice) {
            revert InsufficientFunds();
        }

        // Prepare mint arguments
        bytes memory mintArgs = abi.encode(to, comment);

        IZoraCreator1155(tokenContract).mint{value: msg.value}(
            IMinter1155(priceFixedSaleStrategy),
            tokenId,
            quantity,
            new address[](0),
            mintArgs
        );
    }

    /// @notice Fallback function to receive ETH
    receive() external payable {}
} 