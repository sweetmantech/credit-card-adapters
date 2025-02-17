// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
    /// @param _priceFixedSaleStrategy Address of the Fixed Price Sale Strategy contract
    /// @param _target Target Zora1155Creator contract address
    /// @param _tokenId Token ID to mint
    /// @param _quantity Number of tokens to mint
    /// @param _to Recipient address for the minted tokens
    /// @param _comment The comment to pass to the minter
    function mint(
        address _priceFixedSaleStrategy,
        address _target,
        uint256 _tokenId,
        uint256 _quantity,
        address _to,
        string memory _comment
    ) public payable {
        IFixedPriceSaleStrategy.SaleConfig memory config =
            IFixedPriceSaleStrategy(_priceFixedSaleStrategy).sale(_target, _tokenId);
        
        // Validate sale is active
        if (block.timestamp < config.saleStart || block.timestamp > config.saleEnd) {
            revert SaleNotActive();
        }

        // Calculate total price
        uint256 totalPrice = uint256(config.pricePerToken) * _quantity;
        if (msg.value < totalPrice) {
            revert InsufficientFunds();
        }

        // Prepare mint arguments
        bytes memory mintArgs = abi.encode(_to, _comment);

        IZoraCreator1155(_target).mint{value: msg.value}(
            IMinter1155(_priceFixedSaleStrategy),
            _tokenId,
            _quantity,
            new address[](0),
            mintArgs
        );
    }

    /// @notice Fallback function to receive ETH
    receive() external payable {}
} 