// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {USDCTopupAdapter} from "../src/USDCTopupAdapter.sol";

contract MockUSDC {
    string public name = "Mock USDC";
    string public symbol = "mUSDC";
    uint8 public constant decimals = 6;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= amount, "ERC20: insufficient allowance");
        require(balanceOf[from] >= amount, "ERC20: transfer amount exceeds balance");
        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - amount;
            emit Approval(from, msg.sender, allowance[from][msg.sender]);
        }
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}

contract USDCTopupAdapterTest is Test {
    USDCTopupAdapter public adapter;
    MockUSDC public usdc;

    address public constant USER = address(0x1);
    address public constant RECIPIENT = address(0xBEEF);

    function setUp() public {
        adapter = new USDCTopupAdapter();
        usdc = new MockUSDC();

        // Seed USER with 100 USDC (scaled to 6 decimals)
        usdc.mint(USER, 100 * 1_000_000);
    }

    function test_ReceiveEth() public {
        payable(address(adapter)).transfer(1 ether);
        assertEq(address(adapter).balance, 1 ether);
    }

    function test_RevertWhen_WithdrawNotOwner() public {
        vm.deal(address(adapter), 1 ether);
        vm.prank(USER);
        vm.expectRevert("Not the contract owner");
        adapter.withdraw(0.5 ether);
    }

    function test_Topup_TransfersScaledUSDC() public {
        // USER approves adapter to pull USDC
        vm.prank(USER);
        usdc.approve(address(adapter), type(uint256).max);

        uint256 userBefore = usdc.balanceOf(USER);

        // USER calls topup to send 2 USDC to RECIPIENT
        vm.prank(USER);
        adapter.topup(RECIPIENT, address(usdc), "2");

        // Amount scaled to 6 decimals => 2_000_000
        assertEq(usdc.balanceOf(RECIPIENT), 2_000_000);
        assertEq(usdc.balanceOf(USER), userBefore - 2_000_000);
    }

    function test_RevertWhen_InsufficientAllowance() public {
        // USER does not approve or approves less than required
        vm.prank(USER);
        usdc.approve(address(adapter), 1_000_000); // allow 1 USDC

        vm.prank(USER);
        vm.expectRevert("ERC20: insufficient allowance");
        adapter.topup(RECIPIENT, address(usdc), "2"); // needs 2 USDC
    }

    function test_Topup_TransfersDecimalUSDC() public {
        // USER approves adapter to pull USDC
        vm.prank(USER);
        usdc.approve(address(adapter), type(uint256).max);

        uint256 userBefore = usdc.balanceOf(USER);

        // 0.111 USDC => 111_000 units
        vm.prank(USER);
        adapter.topup(RECIPIENT, address(usdc), "0.111");

        assertEq(usdc.balanceOf(RECIPIENT), 111_000);
        assertEq(usdc.balanceOf(USER), userBefore - 111_000);
    }
}


