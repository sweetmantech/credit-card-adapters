// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Main interface for the ZoraCreator1155 contract
interface IZora721 {
    /// @notice Purchase a quantity of tokens with a comment
    /// @param quantity quantity to purchase
    /// @param comment comment to include in the IERC721Drop.Sale event
    /// @return tokenId of the first token minted
    function purchaseWithComment(
        uint256 quantity,
        string calldata comment
    ) external payable returns (uint256);
}
