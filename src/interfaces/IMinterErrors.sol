// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMinterErrors {
    error SaleEnded();
    error SaleHasNotStarted();
    error WrongValueSent();
    error ExceedsMaxPerAddress();
    error InvalidMintQuantity();
} 