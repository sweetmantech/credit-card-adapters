// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {HypersubCrossmintAdapter} from "../src/HypersubCrossmintAdapter.sol";
import {MockSTPV2} from "./mocks/MockSTPV2.sol";
import {MockSwapFactory, MockQuoterV2, MockToken, MockSwapRouter} from "./mocks/MockSwapFactory.sol";

contract HypersubCrossmintAdapterTest is Test {
    HypersubCrossmintAdapter public adapter;
    MockSTPV2 public mockSTPV2;
    MockSwapFactory public mockSwapFactory;
    MockQuoterV2 public mockQuoterV2;
    MockToken public mockTokenIn;
    MockToken public mockTokenOut;
    MockSwapRouter public mockSwapRouter;

    address public constant USER = address(0x1);
    uint256 public constant TOKEN_ID = 1;
    uint256 public constant SUBSCRIPTION_AMOUNT = 1;
    uint256 public constant SUBSCRIPTION_PRICE = 0.1 ether;
    uint256 public constant MINT_FEE = 0.0005 ether;

    HypersubCrossmintAdapter.SwapData public defaultSwapData;

    function setUp() public {
        adapter = new HypersubCrossmintAdapter();
        mockSTPV2 = new MockSTPV2();
        mockSwapFactory = new MockSwapFactory();
        mockQuoterV2 = new MockQuoterV2();
        mockTokenIn = new MockToken();
        mockTokenOut = new MockToken();
        mockSwapRouter = new MockSwapRouter();

        defaultSwapData = HypersubCrossmintAdapter.SwapData({
            swapFactory: address(mockSwapFactory),
            swapRouter: address(mockSwapRouter),
            quoterV2: address(mockQuoterV2),
            tokenIn: address(mockTokenIn),
            fee: 3000
        });
    }

    function test_ReceiveEth() public {
        payable(address(adapter)).transfer(1 ether);
        assertEq(address(adapter).balance, 1 ether);
    }

    function test_PurchaseWithERC20() public {
        vm.deal(USER, 1 ether);
        vm.startPrank(USER);

        mockTokenIn.approve(address(adapter), type(uint256).max);
        mockTokenOut.approve(address(adapter), type(uint256).max);

        adapter.mint{value: 1 ether}(defaultSwapData, address(mockSTPV2), 1, address(USER));
        
        vm.stopPrank();
    }

    function test_PurchaseWithInsufficientETH() public {
        vm.deal(USER, 0.0001 ether);
        vm.startPrank(USER);

        vm.expectRevert("Insufficient ETH");
        adapter.mint{value: 0.0001 ether}(defaultSwapData, address(mockSTPV2), 1, address(USER));
        
        vm.stopPrank();
    }
} 