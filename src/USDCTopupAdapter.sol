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
    /// @dev `totalPrice` is a base-10 string with up to 6 fractional digits, scaled by 1e6
    /// @param _to Recipient address that will receive the USDC
    /// @param _usdc USDC token contract address (6 decimals)
    /// @param totalPrice Amount of USDC to transfer, as a string (e.g. "1", "0.1", "0.000001")
    function topup(
        address _to,
        address _usdc,
        string memory totalPrice
    ) public {
        require(_to != address(0), "invalid to");
        require(_usdc != address(0), "invalid usdc");

        uint256 amount6 = _parseUSDCAmount(totalPrice); // already scaled to 1e6
        require(amount6 > 0, "amount zero");

        IERC20(_usdc).transferFrom(msg.sender, _to, amount6);
    }

    /// @notice Parses a base-10 unsigned decimal string into a uint256 scaled to 1e6
    /// @dev Supports up to 6 fractional digits. Reverts on invalid format or more than 6 decimals.
    function _parseUSDCAmount(string memory s) internal pure returns (uint256) {
        bytes memory b = bytes(s);
        require(b.length > 0, "empty amount");

        uint256 intPart = 0;
        uint256 fracPart = 0;
        uint256 fracLen = 0;
        bool seenDot = false;
        bool seenDigit = false;

        for (uint256 i = 0; i < b.length; i++) {
            uint8 c = uint8(b[i]);
            if (c == 46) { // '.'
                require(!seenDot, "multiple dots");
                seenDot = true;
                continue;
            }
            require(c >= 48 && c <= 57, "invalid char");
            seenDigit = true;
            if (!seenDot) {
                intPart = intPart * 10 + (c - 48);
            } else {
                if (fracLen < 6) {
                    fracPart = fracPart * 10 + (c - 48);
                    fracLen++;
                } else {
                    // more than 6 decimals not allowed to avoid implicit rounding
                    revert("too many decimals");
                }
            }
        }

        require(seenDigit, "no digits");

        // scale integer part by 1e6 and pad fractional part to 6 digits
        uint256 amount6 = intPart * 1_000_000;
        if (fracLen > 0) {
            amount6 += fracPart * (10 ** (6 - fracLen));
        }
        return amount6;
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