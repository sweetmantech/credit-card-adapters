// SPDX-License-Identifier: MIT
import {IMinter1155} from "./IMinter1155.sol";

/// @notice Main interface for the ZoraCreator1155 contract
/// @author @iainnash / @tbtstl
interface IZora1155 {
    /// @notice Mint tokens and payout rewards given a minter contract, minter arguments, and a mint referral
    /// @param minter The minter contract to use
    /// @param tokenId The token ID to mint
    /// @param quantity The quantity of tokens to mint
    /// @param minterArguments The arguments to pass to the minter
    /// @param mintReferral The referrer of the mint
    function mintWithRewards(
        IMinter1155 minter,
        uint256 tokenId,
        uint256 quantity,
        bytes calldata minterArguments,
        address mintReferral
    ) external payable;
}
