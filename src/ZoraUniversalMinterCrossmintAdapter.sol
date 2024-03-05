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

contract ZoraUniversalMinterCrossmintAdapter {
    /// @notice mint using Zora's Universal Minter
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

        for(uint256 i = 0; i < _tokenCount; i++) {
            _targets[i] = _target;
            _values[i] = _value;
        }

        _calldatas = generateCalldatas(_tokenCount, _minter, _referral, _to, _target);

        IZoraUniversalMinter minter = IZoraUniversalMinter(_universalMinter);
        minter.mintBatchWithoutFees{value: msg.value}(
            _targets,
            generateCalldatas(_tokenCount, _minter, _referral, _to, _targets[0]),
            _values
        );
    }

    function generateCalldatas(
        uint256 count,
        address minter,
        address referral,
        address to,
        address dropContractAddress // Address of the Zora Drop contract
    ) public pure returns (bytes[] memory calldatas) {
        calldatas = new bytes[](count);
        IZoraCreator zoraDrop = IZoraCreator(dropContractAddress);
        bytes4 selector = zoraDrop.mintWithRewards.selector;
        // Example parameters, adjust based on actual function signature
        uint256 quantity = 1;
        string memory comment = "MAGIC"; // Comment used in the minterArguments
        bytes memory minterArguments = abi.encode(to, comment);  // Simplified, replace with actual encoding logic if necessary
        
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = i + 1;
            calldatas[i] = abi.encodeWithSelector(
                selector,
                minter,
                tokenId,
                quantity,
                minterArguments,
                referral
            );
        }
    }
}
