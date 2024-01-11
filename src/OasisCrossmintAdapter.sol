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
import {IERC721Drop} from "./interfaces/IERC721Drop.sol";
import {IERC721A} from "@ERC721A/contracts/IERC721A.sol";
import {IZora1155} from "./interfaces/IZora1155.sol";

contract OasisCrossmintAdapter {
    /// @notice mint target ERC1155Drops
    /// @param _target ERC721Drop contract address
    /// @param _quantity number of tokens
    /// @param _to recipient of tokens
    function purchase(
        address _target,
        uint256 _quantity,
        address _to
    ) public payable {
        IERC721Drop erc721 = IERC721Drop(_target);
        uint256 start = erc721.purchase{value: msg.value}(_quantity) + 1;
        for (uint256 i = start; i < start + _quantity; i++) {
            IERC721A(_target).transferFrom(address(this), _to, i);
        }
    }
}
