// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.2 <0.9.0;

import "forge-std/Test.sol";
import "../src/Token.sol";

contract TestToken is Test {
    Token token;

    address owner = address(1);
    address user1 = address(2);
    address user2 = address(3);

    function setUp() public {
        vm.startPrank(owner);
        token = new Token("Alpha", "!", 2, 1000);
        token.transfer(user1, 100);
        vm.stopPrank();
    }

    function test_Transfer() public {
        vm.prank(user1);
        token.transfer(user2, 10);

        assertEq(token.balanceOf(user1), 90);
        assertEq(token.balanceOf(user2), 10);
    }

    function test_Transfer_Reverts_WhenInsufficientBalance() public {
        vm.prank(user1);
        vm.expectRevert("Insufficient balance!");
        token.transfer(user2, 200);
    }

    function test_Approve() public {
        vm.prank(user1);
        token.approve(user2, 200);

        assertEq(token.allowance(user1, user2), 200);
    }

    function test_TransferFrom() public {
        vm.prank(user1);
        token.approve(user2, 100);

        vm.prank(user2);
        token.transferFrom(user1, owner, 100);

        assertEq(token.balanceOf(user1), 0);
        assertEq(token.balanceOf(owner), 1000);
        assertEq(token.allowance(user1, user2), 0);
    }

    function test_TransferFrom_Reverts_WhenNoAllowance() public {
        vm.prank(user2);
        vm.expectRevert("Allowance exceeded");
        token.transferFrom(user1, owner, 10);
    }

    function test_TransferFrom_Reverts_WhenBalanceTooLow() public {
        vm.prank(user1);
        token.approve(user2, 200);

        vm.prank(user2);
        vm.expectRevert("Insufficient balance");
        token.transferFrom(user1, owner, 200);
    }
}
