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
import {Test} from "@forge-std/src/Test.sol";
import {LensCrossmintAdapter} from "../src/LensCrossmintAdapter.sol";
import {LensHubMock} from "./mocks/LensHubMock.sol";
import {WMATIC} from "../src/libraries/WMATIC.sol";

contract LensCrossmintAdapterTest is Test {
    LensCrossmintAdapter public adapter;
    LensHubMock public lensHub;
    WMATIC public wmatic;

    address public DEFAULT_MINTER = address(0x01);
    address public DEFAULT_MINTER_TWO = address(0x02);
    uint256 DEFAULT_PROFILE_ID = 0x123;
    uint256 DEFAULT_PUB_ID = 0x1;

    function setUp() public {
        lensHub = new LensHubMock();
        wmatic = new WMATIC();
        adapter = new LensCrossmintAdapter(address(lensHub), address(wmatic));
    }

    function testCollect() public {
        uint256 quantity = 1;
        vm.startPrank(DEFAULT_MINTER);
        vm.deal(DEFAULT_MINTER, 1 ether);
        bytes memory data = abi.encode(address(wmatic), 1);
        uint256 start = lensHub.collect(
            DEFAULT_PROFILE_ID,
            DEFAULT_PUB_ID,
            data
        );
        assertEq(lensHub.balanceOf(DEFAULT_MINTER), quantity);
        adapter.collect{value: 1 ether}(
            DEFAULT_PROFILE_ID,
            DEFAULT_PUB_ID,
            data,
            1,
            DEFAULT_MINTER
        );
        assertEq(lensHub.balanceOf(DEFAULT_MINTER), 2 * quantity);
    }

    // function testPurchaseMany() public {
    //     uint256 quantity = 100;
    //     vm.startPrank(DEFAULT_MINTER);
    //     uint256 start = drop.purchase(quantity);
    //     emit log_string("HELLO");
    //     emit log_uint(start);
    //     adapter.purchase(address(drop), quantity, DEFAULT_MINTER_TWO);
    //     assertEq(drop.balanceOf(DEFAULT_MINTER), quantity);
    //     assertEq(drop.ownerOf(1), DEFAULT_MINTER);
    //     assertEq(drop.balanceOf(DEFAULT_MINTER_TWO), quantity);
    //     assertEq(drop.ownerOf(101), DEFAULT_MINTER_TWO);
    // }
}
