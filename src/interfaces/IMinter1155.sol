// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @notice Minter standard interface
/// @dev Minters need to confirm to the ERC165 selector of type(IMinter1155).interfaceId
interface IMinter1155 {
    function requestMint(
        address sender,
        uint256 tokenId,
        uint256 quantity,
        uint256 ethValueSent,
        bytes calldata minterArguments
    ) external;
}
