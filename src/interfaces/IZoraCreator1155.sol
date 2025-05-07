// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IMinter1155} from "./IMinter1155.sol";

interface IZoraCreator1155 {
    /// @notice Mint tokens and payout rewards given a minter contract, minter arguments, and rewards arguments
    /// @param minter The minter contract to use
    /// @param tokenId The token ID to mint
    /// @param quantity The quantity of tokens to mint
    /// @param rewardsRecipients The addresses of rewards arguments - rewardsRecipients[0] = mintReferral, rewardsRecipients[1] = platformReferral
    /// @param minterArguments The arguments to pass to the minter
    function mint(
        IMinter1155 minter,
        uint256 tokenId,
        uint256 quantity,
        address[] calldata rewardsRecipients,
        bytes calldata minterArguments
    ) external payable;
}
