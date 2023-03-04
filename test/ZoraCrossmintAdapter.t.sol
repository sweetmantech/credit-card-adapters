// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Test} from "@forge-std/src/Test.sol";
import {ZoraCrossmintAdapter} from "../src/ZoraCrossmintAdapter.sol";
import {ZoraDropMock} from "./mocks/ZoraDropMock.sol";

contract ZoraCrossmintAdapterTest is Test {
    ZoraCrossmintAdapter public adapter;
    ZoraDropMock public drop;
    address public DEFAULT_MINTER = address(0x01);
    address public DEFAULT_MINTER_TWO = address(0x02);

    function setUp() public {
        adapter = new ZoraCrossmintAdapter();
        drop = new ZoraDropMock();
    }

    function testPurchase() public {
        uint256 quantity = 1;
        vm.startPrank(DEFAULT_MINTER);
        uint256 start = drop.purchase(quantity);
        assertEq(drop.balanceOf(DEFAULT_MINTER), quantity);
        adapter.purchase(address(drop), quantity, DEFAULT_MINTER);
        assertEq(drop.balanceOf(DEFAULT_MINTER), 2 * quantity);
    }

    function testPurchaseMany() public {
        uint256 quantity = 100;
        vm.startPrank(DEFAULT_MINTER);
        uint256 start = drop.purchase(quantity);
        emit log_string("HELLO");
        emit log_uint(start);
        adapter.purchase(address(drop), quantity, DEFAULT_MINTER_TWO);
        assertEq(drop.balanceOf(DEFAULT_MINTER), quantity);
        assertEq(drop.ownerOf(1), DEFAULT_MINTER);
        assertEq(drop.balanceOf(DEFAULT_MINTER_TWO), quantity);
        assertEq(drop.ownerOf(101), DEFAULT_MINTER_TWO);
    }
}
