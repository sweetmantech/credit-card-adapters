// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/*
██████╗ ██╗███████╗███████╗
██╔══██╗██║██╔════╝██╔════╝
██████╔╝██║█████╗  █████╗  
██╔══██╗██║██╔══╝  ██╔══╝  
██║  ██║██║██║     ██║     
╚═╝  ╚═╝╚═╝╚═╝     ╚═╝                                                                                                  
*/
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/ILensHub.sol";
import {IWmatic} from "./interfaces/IWmatic.sol";

contract LensCrossmintAdapter {
    address public immutable lensHubAddress;
    address public immutable wMaticAddress;

    constructor(address _lensHubAddress, address _wMaticAddress) {
        lensHubAddress = _lensHubAddress;
        wMaticAddress = _wMaticAddress;
    }

    /// @notice convert MATIC to WMATIC
    function wrapMatic() internal {
        IWmatic(wMaticAddress).deposit{value: msg.value}();
    }

    /// @notice mint target ERC721Drop
    /// @param _vars Lens collect with sig data
    /// @param _to recipient of tokens
    function collectWithSig(
        DataTypes.CollectWithSigData calldata _vars,
        address _to
    ) external payable {
        // Wrap MATIC to WMATIC
        wrapMatic();

        // Transfer the WMATIC to the user's wallet
        IERC20 wMaticToken = IERC20(wMaticAddress);
        uint256 wMaticBalance = wMaticToken.balanceOf(address(this));
        wMaticToken.transfer(_to, wMaticBalance);

        ILensHub(lensHubAddress).collectWithSig(_vars);
    }

    /// @notice mint target ERC721Drop
    /// @param profileId profile id of seller
    /// @param pubId publication id to collect
    /// @param data encoded collect data
    /// @param quantity number of tokens to mint
    /// @param to recipient of tokens
    function collect(
        uint256 profileId,
        uint256 pubId,
        bytes memory data,
        uint256 quantity,
        address to
    ) external payable returns (uint256) {
        // Wrap MATIC to WMATIC
        wrapMatic();

        // Transfer the WMATIC to the user's wallet
        address nftAddress = ILensHub(lensHubAddress).getCollectNFT(
            profileId,
            pubId
        );

        uint256 firstMintedTokenId = ILensHub(lensHubAddress).collect(
            profileId,
            pubId,
            data
        );
        IERC721(nftAddress).safeTransferFrom(
            address(this),
            to,
            firstMintedTokenId,
            bytes("")
        );
        for (uint256 i = 1; i < quantity; i++) {
            ILensHub(lensHubAddress).collect(profileId, pubId, data);
            IERC721(nftAddress).safeTransferFrom(
                address(this),
                to,
                firstMintedTokenId + i,
                bytes("")
            );
        }

        return firstMintedTokenId;
    }
}
