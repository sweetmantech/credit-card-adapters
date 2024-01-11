// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Test} from "@forge-std/src/Test.sol";
import {OasisCrossmintAdapter} from "../src/OasisCrossmintAdapter.sol";
import {ZoraDropMock} from "./mocks/ZoraDropMock.sol";

contract OasisCrossmintAdapterTest is Test {
    OasisCrossmintAdapter public adapter;

    function setUp() public {
        adapter = new OasisCrossmintAdapter();
    }
}
