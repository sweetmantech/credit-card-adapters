// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {Manifold1155CrossmintAdapter} from "../src/Manifold1155CrossmintAdapter.sol";
import {MockERC1155, MockERC1155LazyPayableClaim} from "./mocks/MockManifold.sol";
import {MockSwapFactory, MockQuoterV2, MockToken, MockSwapRouter} from "./mocks/MockSwapFactory.sol";

contract Manifold1155CrossmintAdapterTest is Test {
    Manifold1155CrossmintAdapter public adapter;
    MockERC1155 public mockERC1155;
    MockERC1155LazyPayableClaim public mockLazyPayableClaim;
    MockSwapFactory public mockSwapFactory;
    MockQuoterV2 public mockQuoterV2;
    MockToken public mockTokenIn;
    MockToken public mockTokenOut;
    MockSwapRouter public mockSwapRouter;

    address public constant USER = address(0x1);
    uint256 public constant INSTANCE_ID = 1;
    uint256 public constant TOKEN_ID = 1;
    uint16 public constant MINT_COUNT = 1;
    uint256 public constant MINT_FEE = 0.0005 ether;

    Manifold1155CrossmintAdapter.SwapData public defaultSwapData;
    Manifold1155CrossmintAdapter.MintData public defaultMintData;

    function setUp() public {
        adapter = new Manifold1155CrossmintAdapter();
        mockERC1155 = new MockERC1155();
        mockLazyPayableClaim = new MockERC1155LazyPayableClaim();
        mockSwapFactory = new MockSwapFactory();
        mockQuoterV2 = new MockQuoterV2();
        mockTokenIn = new MockToken();
        mockTokenOut = new MockToken();
        mockSwapRouter = new MockSwapRouter();

        MockERC1155LazyPayableClaim.Claim memory claim = MockERC1155LazyPayableClaim.Claim({
            total: 0,
            totalMax: 1000,
            walletMax: 10,
            startDate: uint48(block.timestamp),
            endDate: uint48(block.timestamp + 1 days),
            tokenId: TOKEN_ID,
            cost: 0.1 ether,
            erc20: address(mockTokenOut)
        });
        
        mockLazyPayableClaim.setClaim(address(mockERC1155), INSTANCE_ID, claim);

        mockERC1155.setBalance(address(adapter), TOKEN_ID, MINT_COUNT);

        defaultSwapData = Manifold1155CrossmintAdapter.SwapData({
            swapFactory: address(mockSwapFactory),
            swapRouter: address(mockSwapRouter),
            quoterV2: address(mockQuoterV2),
            tokenIn: address(mockTokenIn),
            fee: 3000
        });

        defaultMintData = Manifold1155CrossmintAdapter.MintData({
            extensionContract: address(mockLazyPayableClaim),
            creatorContractAddress: address(mockERC1155),
            instanceId: INSTANCE_ID,
            mintCount: MINT_COUNT,
            mintIndices: new uint32[](0),
            merkleProofs: new bytes32[][](0)
        });
    }

    function test_ReceiveEth() public {
        payable(address(adapter)).transfer(1 ether);
        assertEq(address(adapter).balance, 1 ether);
    }

    function test_MintWithERC20() public {
        vm.deal(USER, 1 ether);
        vm.startPrank(USER);

        mockTokenIn.approve(address(adapter), type(uint256).max);
        mockTokenOut.approve(address(adapter), type(uint256).max);

        adapter.mint{value: 1 ether}(defaultSwapData, defaultMintData, USER);
        vm.stopPrank();
    }

    function test_MintWithETH() public {
        vm.deal(USER, 1 ether);
        vm.startPrank(USER);

        MockERC1155LazyPayableClaim.Claim memory claim = MockERC1155LazyPayableClaim.Claim({
            total: 0,
            totalMax: 1000,
            walletMax: 10,
            startDate: uint48(block.timestamp),
            endDate: uint48(block.timestamp + 1 days),
            tokenId: TOKEN_ID,
            cost: 0.1 ether,
            erc20: address(0)
        });
        mockLazyPayableClaim.setClaim(address(mockERC1155), INSTANCE_ID, claim);

        adapter.mint{value: 1 ether}(defaultSwapData, defaultMintData, USER);
        vm.stopPrank();
    }

    function test_RevertWhen_WithdrawNotOwner() public {
        vm.deal(address(adapter), 1 ether);
        vm.prank(USER);
        vm.expectRevert("Not the contract owner");
        adapter.withdraw(0.5 ether);
    }

    function test_RevertWhen_MintInsufficientETH() public {
        vm.deal(USER, 0.05 ether);
        vm.startPrank(USER);

        vm.expectRevert("Insufficient ETH");
        adapter.mint{value: 0.05 ether}(defaultSwapData, defaultMintData, USER);
        vm.stopPrank();
    }
} 