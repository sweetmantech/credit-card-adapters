// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20Minter} from "./interfaces/IERC20Minter.sol";
import {IERC20} from "./interfaces/IERC20.sol";

/// @title ZoraERC20MinterCrossmintAdapter
/// @notice Adapter contract for interacting with ZoraERC20Minter
contract ZoraERC20MinterCrossmintAdapter {
    /// @notice Error thrown when insufficient funds are sent
    error InsufficientFunds();
    /// @notice Error thrown when sale is not active
    error SaleNotActive();

    /// @notice Mints tokens using the Erc20 Minter.
    /// @param erc20Minter The address of the Erc20 Minter contract responsible for minting tokens.
    /// @param to The recipient address for the minted tokens.
    /// @param quantity The number of tokens to mint.
    /// @param tokenContract The address of the Zora1155Creator contract.
    /// @param tokenId The ID of the token to mint.
    /// @param mintReferral An optional referral address for the minting process.
    /// @param comment A comment to pass to the minter for additional context.
    function mint(
        address erc20Minter,
        address to,
        uint256 quantity,
        address tokenContract,
        uint256 tokenId,
        address mintReferral,
        string memory comment
    ) public {
        IERC20Minter.SalesConfig memory config = IERC20Minter(erc20Minter).sale(tokenContract, tokenId);

        // Validate sale is active
        if (block.timestamp < config.saleStart || block.timestamp > config.saleEnd) {
            revert SaleNotActive();
        }

        // Calculate USDC price
        uint256 totalPriceUSDC = uint256(config.pricePerToken) * quantity;

        // Transfer tokens from user to this contract
        require(IERC20(config.currency).transferFrom(msg.sender, address(this), totalPriceUSDC), "Transfer failed");

        // Approve minter to spend tokens
        require(IERC20(config.currency).approve(erc20Minter, totalPriceUSDC), "Approval failed");

        // Call mint on the minter contract
        IERC20Minter(erc20Minter).mint(
            to,
            quantity,
            tokenContract,
            tokenId,
            totalPriceUSDC, // Use calculated total price instead of total price USDC
            config.currency,
            mintReferral,
            comment
        );
    }
}
