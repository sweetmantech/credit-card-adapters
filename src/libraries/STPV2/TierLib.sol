// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Subscription, Tier} from "./Index.sol";

/// @dev The initialization parameters for a subscription token
library TierLib {
    using TierLib for Tier;

    /// @dev scale factor for precision on tokens per second
    uint256 private constant SCALE_FACTOR = 2 ** 80;

    /// @dev The state of a tier
    struct State {
        /// @dev The number of subscriptions in this tier
        uint32 subCount;
        /// @dev The id of the tier
        uint16 id;
        /// @dev The parameters for the tier
        Tier params;
    }

    /////////////////////
    // ERRORS
    /////////////////////

    /// @dev A sponsored purchase attempts to switch tiers (not allowed)
    error TierInvalidSwitch();

    /// @dev The tier duration must be > 0
    error TierInvalidDuration();

    /// @dev The supply cap must be >= current count or 0
    error TierInvalidSupplyCap();

    /// @dev The tier id was not found
    error TierNotFound(uint16 tierId);

    /// @dev The tier has no supply
    error TierHasNoSupply(uint16 tierId);

    /// @dev The tier does not allow transferring tokens
    error TierTransferDisabled();

    /// @dev The tier price is invalid
    error TierInvalidMintPrice(uint256 mintPrice);

    /// @dev The tier renewals are paused
    error TierRenewalsPaused();

    /// @dev The tier renewal price is invalid (too low)
    error TierInvalidRenewalPrice(uint256 renewalPrice);

    /// @dev The max commitment has been exceeded (0 = unlimited)
    error MaxCommitmentExceeded();

    /// @dev The tier has not started yet
    error TierNotStarted();

    /// @dev The subscription length has exceeded the tier end time
    error TierEndExceeded();

    /// @dev The tier timing is invalid
    error TierTimingInvalid();
}