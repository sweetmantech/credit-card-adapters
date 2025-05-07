// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/*
███████╗██╗    ██╗███████╗███████╗████████╗███╗   ███╗ █████╗ ███╗   ██╗   ███████╗████████╗██╗  ██╗
██╔════╝██║    ██║██╔════╝██╔════╝╚══██╔══╝████╗ ████║██╔══██╗████╗  ██║   ██╔════╝╚══██╔══╝██║  ██║
███████╗██║ █╗ ██║█████╗  █████╗     ██║   ██╔████╔██║███████║██╔██╗ ██║   █████╗     ██║   ███████║
╚════██║██║███╗██║██╔══╝  ██╔══╝     ██║   ██║╚██╔╝██║██╔══██║██║╚██╗██║   ██╔══╝     ██║   ██╔══██║
███████║╚███╔███╔╝███████╗███████╗   ██║   ██║ ╚═╝ ██║██║  ██║██║ ╚████║██╗███████╗   ██║   ██║  ██║
╚══════╝ ╚══╝╚══╝ ╚══════╝╚══════╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝                                                                                              
*/
import {IZoraUniversalMinter} from "./interfaces/IZoraUniversalMinter.sol";
import {IZoraCreator} from "./interfaces/IZoraCreator.sol";

/// @title Zora Universal Minter Crossmint Adapter
/// @notice Adapter contract for interacting with Zora's Universal Minter to mint tokens in a batch without fees.
/// @author sweetman.eth
contract ZoraUniversalMinterCrossmintAdapter {
    /// @notice Mints tokens in batch without fees using Zora's Universal Minter.
    /// @param _universalMinter Address of the Zora Universal Minter contract.
    /// @param _target Target contract address where tokens will be minted.
    /// @param _value Ether value to send with each mint function call.
    /// @param _tokenCount Number of tokens in the collection.
    /// @param _referral Address to be used as referral in minting process.
    /// @param _minter Address initiating the mint, usually the minter's address.
    /// @param _to Address where the minted tokens should be sent.
    function purchase(
        address _universalMinter,
        address _target,
        uint256 _value,
        uint256 _tokenCount,
        address _referral,
        address _minter,
        address _to
    ) public payable {
        require(msg.value >= _value * _tokenCount, "Insufficient funds sent");

        address[] memory _targets = new address[](_tokenCount);
        bytes[] memory _calldatas = new bytes[](_tokenCount);
        uint256[] memory _values = new uint256[](_tokenCount);

        for (uint256 i = 0; i < _tokenCount; i++) {
            _targets[i] = _target;
            _values[i] = _value;
        }

        _calldatas = generateCalldatas(_tokenCount, _minter, _referral, _to, _target);

        IZoraUniversalMinter minter = IZoraUniversalMinter(_universalMinter);
        minter.mintBatchWithoutFees{value: msg.value}(
            _targets, generateCalldatas(_tokenCount, _minter, _referral, _to, _targets[0]), _values
        );
    }

    /// @notice Generates the calldata for each token to be minted.
    /// @param count Number of tokens in the ERC1155 collection.
    /// @param minter Address initiating the mint.
    /// @param referral Address to be used as referral in the minting process.
    /// @param to Address where the minted tokens should be sent.
    /// @param dropContractAddress Target contract address for minting.
    /// @return calldatas The array of calldata for minting each token.
    function generateCalldatas(uint256 count, address minter, address referral, address to, address dropContractAddress)
        public
        pure
        returns (bytes[] memory calldatas)
    {
        calldatas = new bytes[](count);
        IZoraCreator zoraDrop = IZoraCreator(dropContractAddress);
        bytes4 selector = zoraDrop.mintWithRewards.selector;

        uint256 quantity = 1;
        string memory comment = "MAGIC";
        bytes memory minterArguments = abi.encode(to, comment);

        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = i + 1;
            calldatas[i] = abi.encodeWithSelector(selector, minter, tokenId, quantity, minterArguments, referral);
        }
    }
}
