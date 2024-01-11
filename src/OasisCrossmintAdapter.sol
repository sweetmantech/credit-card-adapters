// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/*
███████╗██╗    ██╗███████╗███████╗████████╗███╗   ███╗ █████╗ ███╗   ██╗   ███████╗████████╗██╗  ██╗
██╔════╝██║    ██║██╔════╝██╔════╝╚══██╔══╝████╗ ████║██╔══██╗████╗  ██║   ██╔════╝╚══██╔══╝██║  ██║
███████╗██║ █╗ ██║█████╗  █████╗     ██║   ██╔████╔██║███████║██╔██╗ ██║   █████╗     ██║   ███████║
╚════██║██║███╗██║██╔══╝  ██╔══╝     ██║   ██║╚██╔╝██║██╔══██║██║╚██╗██║   ██╔══╝     ██║   ██╔══██║
███████║╚███╔███╔╝███████╗███████╗   ██║   ██║ ╚═╝ ██║██║  ██║██║ ╚████║██╗███████╗   ██║   ██║  ██║
╚══════╝ ╚══╝╚══╝ ╚══════╝╚══════╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝                                                                                              
*/
import {Multicall3} from "@multicall/Multicall3.sol";

contract OasisCrossmintAdapter {
    Multicall3 public multicallContract;

    constructor(address _multicallAddress) {
        multicallContract = Multicall3(_multicallAddress);
    }

    function checkout(
        address _target,
        uint256 _quantity,
        address _to,
        Multicall3.Call3Value[] calldata cart
    ) public payable {
        multicallContract.aggregate3Value{value: msg.value}(cart);
    }
}
