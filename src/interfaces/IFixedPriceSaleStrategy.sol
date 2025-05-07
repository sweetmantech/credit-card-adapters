// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title IFixedPriceSaleStrategy
/// @notice Interface for Zora's fixed price sale strategy
interface IFixedPriceSaleStrategy {
    /// @notice Sale configuration parameters
    struct SaleConfig {
        uint64 saleStart; // Start time of the sale
        uint64 saleEnd; // End time of the sale
        uint64 maxTokensPerAddress; // Max tokens that can be minted per address
        uint96 pricePerToken; // Price per token in ETH
        address fundsRecipient; // Address to receive the funds
    }

    /// @notice Get the sale configuration for a token
    /// @param target The target contract address
    /// @param tokenId The token ID
    /// @return The sale configuration
    function sale(address target, uint256 tokenId) external view returns (SaleConfig memory);
}
