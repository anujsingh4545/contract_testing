// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.2 <0.9.0;

import "forge-std/Test.sol";
import "../src/Wallet.sol";

contract TestWallet is Test {
    Wallet wallet;

    address owner = address(1);
    address user = address(2);

    function setUp() public {
        vm.prank(owner);
        wallet = new Wallet();
    }

    function test_Deposit() public {
        vm.deal(user, 100 ether);
        vm.startPrank(user);
        wallet.deposit{value: 1 ether}();
        vm.stopPrank();
        assertEq(address(wallet).balance, 1 ether);
    }

    function test_Recieve_Deposit() public {
        vm.deal(user, 10 ether);
        vm.startPrank(user);
        (bool success, ) = address(wallet).call{value: 1 ether}("");
        vm.stopPrank();
        vm.assertTrue(success);
        assertEq(address(wallet).balance, 1 ether);
    }

    function test_Deposit_Reverts() public {
        vm.deal(user, 10 ether);
        vm.startPrank(user);
        vm.expectRevert("No ETH sent");
        wallet.deposit{value: 0 ether}();
        vm.stopPrank();
    }

    function test_Fuzz_Deposit(uint256 amount) public {
        amount = bound(amount, 1, 100);
        uint256 value = amount * 1 ether;
        vm.deal(user, value);
        vm.startPrank(user);
        wallet.deposit{value: value}();
        vm.stopPrank();
        vm.assertEq(address(wallet).balance, value);
    }

    function test_Withdraw() public {
        vm.deal(user, 10 ether);
        vm.startPrank(user);
        wallet.deposit{value: 10 ether}();
        vm.stopPrank();
        uint ownerBalanceBefore = owner.balance;
        vm.startPrank(owner);
        wallet.withdraw(9 ether);
        vm.stopPrank();
        vm.assertEq(owner.balance, ownerBalanceBefore + 9 ether);
        vm.assertEq(address(wallet).balance, 1 ether);
    }

    function test_Withdraw_Reverts() public {
        vm.deal(user, 10 ether);
        vm.startPrank(user);
        wallet.deposit{value: 10 ether}();
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectRevert("Insufficient funds");
        wallet.withdraw(100 ether);
        vm.stopPrank();
    }

    function test_Withdraw_Reverts_WhenCallerIsNotOwner() public {
        vm.deal(user, 5 ether);
        vm.startPrank(user);
        wallet.deposit{value: 3 ether}();
        vm.expectRevert("Not owner");
        wallet.withdraw(2 ether);
        vm.stopPrank();
    }
}
