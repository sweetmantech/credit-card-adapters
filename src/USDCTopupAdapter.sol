// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "./interfaces/IERC20.sol";

/// @title USDCTopupAdapter
contract USDCTopupAdapter {
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    /// @notice Transfers USDC from the caller to a recipient
    /// @dev `totalPrice` is treated as whole USDC units and scaled by 1e6 internally
    /// @param _to Recipient address that will receive the USDC
    /// @param _usdc USDC token contract address (6 decimals)
    /// @param totalPrice Amount of USDC to transfer in whole units (e.g. 1 == 1 USDC)
    function topup(
        address _to,
        address _usdc,
        uint256 totalPrice
    ) public {
        uint256 totalPriceUSDC = uint256(totalPrice) * 1000000;

        IERC20(_usdc).transferFrom(msg.sender, _to, totalPriceUSDC );
    }

    /// @notice Fallback function to receive ETH
    receive() external payable {}

    function withdraw(uint256 amount) external onlyOwner() {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(address(msg.sender)).transfer(amount);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }
}