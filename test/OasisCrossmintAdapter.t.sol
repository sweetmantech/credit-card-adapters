// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Test} from "@forge-std/src/Test.sol";
import {OasisCrossmintAdapter} from "../src/OasisCrossmintAdapter.sol";
import {ZoraDropMock} from "./mocks/ZoraDropMock.sol";

contract OasisCrossmintAdapterTest is Test {
    OasisCrossmintAdapter public adapter;
    address payable MULTICALL_3 =
        payable(0xcA11bde05977b3631167028862bE2a173976CA11);

    function setUp() public {
        adapter = new OasisCrossmintAdapter(MULTICALL_3);
    }
}
