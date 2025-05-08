// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ContractView, SubscriberView} from "../libraries/STPV2/Views.sol";
import {FeeParams, InitParams, MintParams, Subscription, Tier} from "../libraries/STPV2/Index.sol";
import {CurveParams, RewardParams} from "../libraries/STPV2/Rewards.sol";
import {ReferralLib} from "../libraries/STPV2/ReferralLib.sol";
import {TierLib} from "../libraries/STPV2/TierLib.sol";

/**
 * @title Subscription Token Protocol Version 2
 * @author Fabric Inc.
 * @notice An NFT contract which allows users to mint time and access token gated content while time remains.
 */
interface ISTPV2 is IERC721 {
    //////////////////
    // Errors
    //////////////////

    /// @notice Error when the owner is invalid
    error InvalidOwner();

    /// @notice Error when the token params are invalid
    error InvalidTokenParams();

    /// @notice Error when the fee params are invalid
    error InvalidFeeParams();

    /// @notice Error when a transfer fails due to the recipient having a subscription
    error TransferToExistingSubscriber();

    /// @notice Error when the balance is insufficient for a transfer
    error InsufficientBalance();

    /// @notice Error when slashing fails due to constraints
    error NotSlashable();

    //////////////////
    // Events
    //////////////////

    /// @dev Emitted when the owner withdraws available funds
    event Withdraw(address indexed account, uint256 tokensTransferred);

    /// @dev Emitted when the creator tops up the contract balance on refund
    event TopUp(uint256 tokensIn);

    /// @dev Emitted when the fees are transferred to the collector
    event FeeTransfer(address indexed to, uint256 tokensTransferred);

    /// @dev Emitted when the protocol fee recipient is updated
    event ProtocolFeeRecipientChange(address indexed account);

    /// @dev Emitted when the client fee recipient is updated
    event ClientFeeRecipientChange(address indexed account);

    /// @dev Emitted when a referral fee is paid out
    event ReferralPayout(
        uint256 indexed tokenId, address indexed referrer, uint256 indexed referralId, uint256 rewardAmount
    );

    /// @dev Emitted when the supply cap is updated
    event GlobalSupplyCapChange(uint256 supplyCap);

    /// @dev Emitted when the transfer recipient is updated
    event TransferRecipientChange(address indexed recipient);

    /// @dev Emitted when slashing and the reward transfer fails. The balance is reallocated to the creator
    event SlashTransferFallback(address indexed account, uint256 amount);

    //////////////////
    // Roles
    //////////////////

    /// @dev The manager role can do most things, except calls that involve money
    function ROLE_MANAGER() external pure returns (uint16);

    /// @dev The agent can only grant and revoke time
    function ROLE_AGENT() external pure returns (uint16);

    /// @dev The issuer role can issue shares
    function ROLE_ISSUER() external pure returns (uint16);

    //////////////////
    // Initialization
    //////////////////

    /**
     * @notice Initialize the contract with the core parameters
     */
    function initialize(
        InitParams memory params,
        Tier memory tier,
        RewardParams memory rewards,
        CurveParams memory curve,
        FeeParams memory fees
    ) external;

    /////////////////////////
    // Subscribing
    /////////////////////////

    /**
     * @notice Mint or renew a subscription for sender
     * @param numTokens the amount of ERC20 tokens or native tokens to transfer
     */
    function mint(uint256 numTokens) external payable;

    /**
     * @notice Mint or renew a subscription for a specific account
     * @param account the account to mint or renew time for
     * @param numTokens the amount of ERC20 tokens or native tokens to transfer
     */
    function mintFor(address account, uint256 numTokens) external payable;

    /**
     * @notice Mint a subscription with advanced settings
     * @param params the minting parameters
     */
    function mintAdvanced(MintParams calldata params) external payable;

    /////////////////////////
    // Subscriber Management
    /////////////////////////

    /**
     * @notice Refund an account, clearing the subscription and revoking any grants
     * @param account the account to refund
     * @param numTokens the amount of tokens to refund
     */
    function refund(address account, uint256 numTokens) external;

    /**
     * @notice Grant time to a given account
     * @param account the account to grant time to
     * @param numSeconds the number of seconds to grant
     * @param tierId the tier id to grant time to
     */
    function grantTime(address account, uint48 numSeconds, uint16 tierId) external;

    /**
     * @notice Revoke time from a given account
     * @param account the account to revoke time from
     */
    function revokeTime(address account) external;

    /**
     * @notice Deactivate a sub, kicking them out of their tier to the 0 tier
     * @param account the account to deactivate
     */
    function deactivateSubscription(address account) external;

    /////////////////////////
    // Creator Calls
    /////////////////////////

    /**
     * @notice Transfer funds from the contract
     * @param to the recipient address
     * @param amount the amount to transfer
     */
    function transferFunds(address to, uint256 amount) external;

    /**
     * @notice Top up the creator balance
     * @param numTokens the amount of tokens to transfer
     */
    function topUp(uint256 numTokens) external payable;

    /**
     * @notice Update the contract metadata
     * @param uri the collection metadata URI
     */
    function updateMetadata(string memory uri) external;

    /**
     * @notice Set a transfer recipient for automated/sponsored transfers
     * @param recipient the recipient address
     */
    function setTransferRecipient(address recipient) external;

    /**
     * @notice Set the global supply cap for all tiers
     * @param supplyCap the new supply cap
     */
    function setGlobalSupplyCap(uint64 supplyCap) external;

    /////////////////////////
    // Tier Management
    /////////////////////////

    /**
     * @notice Create a new tier
     * @param params the tier parameters
     */
    function createTier(Tier memory params) external;

    /**
     * @notice Update an existing tier
     * @param tierId the id of the tier to update
     * @param params the new tier parameters
     */
    function updateTier(uint16 tierId, Tier memory params) external;

    /////////////////////////
    // Fee Management
    /////////////////////////

    /**
     * @notice Update the protocol fee collector address
     * @param recipient the new fee recipient address
     */
    function updateProtocolFeeRecipient(address recipient) external;

    /**
     * @notice Update the client fee collector address
     * @param recipient the new fee recipient address
     */
    function updateClientFeeRecipient(address recipient) external;

    /////////////////////////
    // Referral Rewards
    /////////////////////////

    /**
     * @notice Create or update a referral code
     * @param code the unique integer code for the referral
     * @param basisPoints the reward basis points
     * @param permanent whether the referral code is locked
     * @param account the specific account to reward
     */
    function setReferralCode(uint256 code, uint16 basisPoints, bool permanent, address account) external;

    /**
     * @notice Fetch the reward basis points for a given referral code
     * @param code the unique integer code for the referral
     * @return value the reward basis points and permanence
     */
    function referralDetail(uint256 code) external view returns (ReferralLib.Code memory value);

    ////////////////////////
    // Rewards
    ////////////////////////

    /**
     * @notice Mint tokens to an account without payment
     * @param account the account to mint to
     * @param numShares the number of shares to mint
     */
    function issueRewardShares(address account, uint256 numShares) external;

    /**
     * @notice Allocate rewards to the pool
     * @param amount the amount of tokens to allocate
     */
    function yieldRewards(uint256 amount) external payable;

    /**
     * @notice Create a new reward curve
     * @param curve the curve parameters
     */
    function createRewardCurve(CurveParams memory curve) external;

    /**
     * @notice Transfer rewards for a given account
     * @param account the account of the reward holder
     */
    function transferRewardsFor(address account) external;

    /**
     * @notice Slash the reward shares for a given account
     * @param account the account to slash
     */
    function slash(address account) external;

    ////////////////////////
    // Informational
    ////////////////////////

    /**
     * @notice Get details about a given reward curve
     * @param curveId the curve id to fetch
     * @return curve the curve details
     */
    function curveDetail(uint8 curveId) external view returns (CurveParams memory curve);

    /**
     * @notice Get details about a particular subscription
     * @param account the account to fetch the subscription for
     * @return subscription the relevant information for a subscription
     */
    function subscriptionOf(address account) external view returns (SubscriberView memory subscription);

    /**
     * @notice Get details about the contract state
     * @return detail the contract details
     */
    function contractDetail() external view returns (ContractView memory detail);

    /**
     * @notice Get details about the fee structure
     * @return fee the fee details
     */
    function feeDetail() external view returns (FeeParams memory fee);

    /**
     * @notice Get details about a given tier
     * @param tierId the tier id to fetch
     * @return tier the tier details
     */
    function tierDetail(uint16 tierId) external view returns (TierLib.State memory tier);

    /**
     * @notice Get the version of the protocol
     * @return version the protocol version
     */
    function stpVersion() external pure returns (uint8 version);

    /**
     * @notice Fetch the balance of a given account in a specific tier
     * @param tierId the tier id to fetch the balance for
     * @param account the account to fetch the balance of
     * @return numSeconds the number of seconds remaining in the subscription
     */
    function tierBalanceOf(uint16 tierId, address account) external view returns (uint256 numSeconds);

    //////////////////////
    // Overrides
    //////////////////////

    /**
     * @notice Fetch the name of the token
     * @return name the name of the token
     */
    function name() external view returns (string memory);

    /**
     * @notice Fetch the symbol of the token
     * @return symbol the symbol of the token
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Fetch the contract metadata URI
     * @return uri the URI for the contract
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice Fetch the metadata URI for a given token
     * @param tokenId the tokenId to fetch the metadata URI for
     * @return uri the URI for the token
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
     * @notice Override the default balanceOf behavior to account for time remaining
     * @param account the account to fetch the balance of
     * @return numSeconds the number of seconds remaining in the subscription
     */
    function balanceOf(address account) external view returns (uint256 numSeconds);

    //////////////////////
    // Recovery Functions
    //////////////////////

    /**
     * @notice Recover a token from the contract
     * @param tokenAddress the address of the token to recover
     * @param recipientAddress the address to send the tokens to
     * @param tokenAmount the amount of tokens to send
     */
    function recoverCurrency(address tokenAddress, address recipientAddress, uint256 tokenAmount) external;
}