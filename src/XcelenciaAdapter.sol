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
import {Multicall3} from "@multicall//Multicall3.sol";
import {IZora721} from "./interfaces/IZora721.sol";

/// @title Xcelencia Adapter
/// @notice Adapter contract for interacting with El Niño Estrella to purchase the smart album.
/// @author sweetman.eth
contract XcelenciaAdapter {
    Multicall3 public immutable multicall =
        Multicall3(0xcA11bde05977b3631167028862bE2a173976CA11);
    IZora721 public immutable ene =
        IZora721(0x0B93A56DB47797142076e24c520C846c9Bd0D6fA);

    /// @notice Purchase El Niño Estrella.
    function purchase() public payable {
        bytes memory callData = getCallData();

        Multicall3.Call3Value memory smartAlbumMint = Multicall3.Call3Value({
            allowFailure: false,
            callData: callData,
            target: address(ene),
            value: 777000000000000
        });

        Multicall3.Call3Value[] memory calls = new Multicall3.Call3Value[](1);
        calls[0] = smartAlbumMint;

        multicall.aggregate3Value{value: msg.value}(calls);
    }

    function getCallData() public view returns (bytes memory zoraCalldata) {
        uint256 mintQuantity = 1;
        string memory COMMENT = "XCELENCIA - ERC6551 smart album";
        zoraCalldata = abi.encodeWithSelector(
            IZora721.purchaseWithComment.selector,
            mintQuantity,
            COMMENT
        );
    }
}
