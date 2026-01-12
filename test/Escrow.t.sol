// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.2 <0.9.0;

import "forge-std/Test.sol";
import "../src/Escrow.sol";

contract EscrowTest is Test {
    EscrowManager escrow;

    address buyer = address(1);
    address seller = address(2);
    address arbiter = address(3);

    function setUp() public {
        escrow = new EscrowManager();
        vm.deal(buyer, 10 ether);
        vm.deal(seller, 10 ether);
        vm.deal(arbiter, 10 ether);
    }

    function testPass_EscrowCreation_With_No_Balance() public {
        vm.startPrank(buyer);
        uint256 id = escrow.createEscrow(seller, arbiter, 5 ether);
        vm.stopPrank();
        (
            address _buyer,
            address _seller,
            address _arbiter,
            uint256 _amount,
            EscrowManager.EscrowState _state,
            uint256 _balance
        ) = escrow.escrows(id);

        vm.assertEq(_buyer, buyer);
        vm.assertEq(_seller, seller);
        vm.assertEq(_arbiter, arbiter);
        vm.assertEq(_amount, 5 ether);
        vm.assertTrue(_state == EscrowManager.EscrowState.AWAITING_PAYMENT);
        vm.assertEq(_balance, 0);
    }

    function testPass_EscrowCreation_With_Balance() public {
        vm.startPrank(buyer);
        uint256 id = escrow.createEscrow{value: 5 ether}(
            seller,
            arbiter,
            5 ether
        );
        vm.stopPrank();
        (
            address _buyer,
            address _seller,
            address _arbiter,
            uint256 _amount,
            EscrowManager.EscrowState _state,
            uint256 _balance
        ) = escrow.escrows(id);

        vm.assertEq(_buyer, buyer);
        vm.assertEq(_seller, seller);
        vm.assertEq(_arbiter, arbiter);
        vm.assertEq(_amount, 5 ether);
        vm.assertTrue(_state == EscrowManager.EscrowState.AWAITING_DELIVERY);
        vm.assertEq(_balance, 5 ether);
    }

    function testRevert_EscrowCreation_Where_Buyer_And_Seller_Same() public {
        vm.startPrank(buyer);
        vm.expectRevert("Seller = buyer");
        escrow.createEscrow(buyer, arbiter, 5 ether);
        vm.stopPrank();
    }

    function testRevert_EscrowCreation_Where_Balance_Neq_Amount() public {
        vm.startPrank(buyer);
        vm.expectRevert("Invalid eth sent");
        escrow.createEscrow{value: 2 ether}(seller, arbiter, 5 ether);
        vm.stopPrank();
    }

    function testPass_Deposit_Balance_Due() public {
        vm.startPrank(buyer);

        uint256 id = escrow.createEscrow(seller, arbiter, 5 ether);

        (, , , , , uint256 balanceBefore) = escrow.escrows(id);
        assertEq(balanceBefore, 0);

        escrow.deposit{value: 5 ether}(id);

        (, , , , , uint256 balanceAfter) = escrow.escrows(id);
        assertEq(balanceAfter, 5 ether);

        vm.stopPrank();
    }
    function testRevert_Deposit_Balance_Already_Paid() public {
        vm.startPrank(buyer);

        uint256 id = escrow.createEscrow{value: 5 ether}(
            seller,
            arbiter,
            5 ether
        );

        vm.expectRevert("Invalid state");
        escrow.deposit{value: 5 ether}(id);
        vm.stopPrank();
    }

    function testPass_Release_Buyer_When_Balance_Paid() public {
        vm.startPrank(buyer);

        uint256 id = escrow.createEscrow{value: 5 ether}(
            seller,
            arbiter,
            5 ether
        );
        escrow.release(id);

        (, , , , EscrowManager.EscrowState _state, ) = escrow.escrows(id);
        vm.assertTrue(_state == EscrowManager.EscrowState.COMPLETED);
        vm.stopPrank();
    }

    function testRevert_Release_Buyer_When_Balance_Unpaid() public {
        vm.startPrank(buyer);

        uint256 id = escrow.createEscrow(seller, arbiter, 5 ether);
        vm.expectRevert("Invalid state");
        escrow.release(id);
        vm.stopPrank();
    }

    function testRevert_Release_Buyer_When_Invalid_Id() public {
        vm.startPrank(buyer);

        uint256 id = escrow.createEscrow(seller, arbiter, 5 ether);
        vm.expectRevert("No escrow found");
        escrow.release(100);
        vm.stopPrank();
    }

    function testRevert_Release_Seller_Accessing() public {
        vm.startPrank(buyer);
        uint256 id = escrow.createEscrow{value: 5 ether}(
            seller,
            arbiter,
            5 ether
        );
        vm.stopPrank();
        vm.startPrank(seller);
        vm.expectRevert("Not buyer");
        escrow.release(id);
        vm.stopPrank();
    }

    function testPass_Dispute_By_Buyer() public {
        vm.startPrank(buyer);
        uint256 id = escrow.createEscrow{value: 5 ether}(
            seller,
            arbiter,
            5 ether
        );

        escrow.dispute(id);

        (, , , , EscrowManager.EscrowState state, ) = escrow.escrows(id);
        assertTrue(state == EscrowManager.EscrowState.DISPUTED);

        vm.stopPrank();
    }

    function testRevert_Dispute_When_Not_Buyer() public {
        vm.startPrank(buyer);
        uint256 id = escrow.createEscrow{value: 5 ether}(
            seller,
            arbiter,
            5 ether
        );
        vm.stopPrank();

        vm.startPrank(seller);
        vm.expectRevert("Not buyer");
        escrow.dispute(id);
        vm.stopPrank();
    }

    function testRevert_Dispute_When_Invalid_State() public {
        vm.startPrank(buyer);
        uint256 id = escrow.createEscrow(seller, arbiter, 5 ether);

        vm.expectRevert("Invalid state");
        escrow.dispute(id);

        vm.stopPrank();
    }

    function testPass_Resolve_To_Seller() public {
        vm.startPrank(buyer);
        uint256 id = escrow.createEscrow{value: 5 ether}(
            seller,
            arbiter,
            5 ether
        );
        escrow.dispute(id);
        vm.stopPrank();

        vm.startPrank(arbiter);
        escrow.resolve(id, true);
        vm.stopPrank();

        (, , , , EscrowManager.EscrowState state, ) = escrow.escrows(id);
        assertTrue(state == EscrowManager.EscrowState.COMPLETED);
    }

    function testPass_Resolve_To_Buyer() public {
        vm.startPrank(buyer);
        uint256 id = escrow.createEscrow{value: 5 ether}(
            seller,
            arbiter,
            5 ether
        );
        escrow.dispute(id);
        vm.stopPrank();

        vm.startPrank(arbiter);
        escrow.resolve(id, false);
        vm.stopPrank();

        (, , , , EscrowManager.EscrowState state, ) = escrow.escrows(id);
        assertTrue(state == EscrowManager.EscrowState.REFUNDED);
    }

    function testRevert_Resolve_When_Not_Arbiter() public {
        vm.startPrank(buyer);
        uint256 id = escrow.createEscrow{value: 5 ether}(
            seller,
            arbiter,
            5 ether
        );
        escrow.dispute(id);
        vm.stopPrank();

        vm.startPrank(seller);
        vm.expectRevert("Not arbiter");
        escrow.resolve(id, true);
        vm.stopPrank();
    }

    function testPass_Withdraw_By_Seller() public {
        vm.startPrank(buyer);
        uint256 id = escrow.createEscrow{value: 5 ether}(
            seller,
            arbiter,
            5 ether
        );
        escrow.release(id);
        vm.stopPrank();

        uint256 sellerBalanceBefore = seller.balance;

        vm.startPrank(seller);
        escrow.withdraw(id);
        vm.stopPrank();

        assertEq(seller.balance, sellerBalanceBefore + 5 ether);

        (, , , , , uint256 balance) = escrow.escrows(id);
        assertEq(balance, 0);
    }

    function testPass_Withdraw_By_Buyer_After_Refund() public {
        vm.startPrank(buyer);
        uint256 id = escrow.createEscrow{value: 5 ether}(
            seller,
            arbiter,
            5 ether
        );
        escrow.dispute(id);
        vm.stopPrank();

        vm.startPrank(arbiter);
        escrow.resolve(id, false);
        vm.stopPrank();

        uint256 buyerBalanceBefore = buyer.balance;

        vm.startPrank(buyer);
        escrow.withdraw(id);
        vm.stopPrank();

        assertEq(buyer.balance, buyerBalanceBefore + 5 ether);
    }
    function testRevert_Withdraw_When_Not_Settled() public {
        vm.startPrank(buyer);
        uint256 id = escrow.createEscrow{value: 5 ether}(
            seller,
            arbiter,
            5 ether
        );

        vm.expectRevert("Escrow not settled");
        escrow.withdraw(id);

        vm.stopPrank();
    }

    function testRevert_Withdraw_When_Wrong_User() public {
        vm.startPrank(buyer);
        uint256 id = escrow.createEscrow{value: 5 ether}(
            seller,
            arbiter,
            5 ether
        );
        escrow.release(id);
        vm.stopPrank();

        vm.startPrank(buyer);
        vm.expectRevert("Not seller");
        escrow.withdraw(id);
        vm.stopPrank();
    }

    function testRevert_Withdraw_Twice() public {
        vm.startPrank(buyer);
        uint256 id = escrow.createEscrow{value: 5 ether}(
            seller,
            arbiter,
            5 ether
        );
        escrow.release(id);
        vm.stopPrank();

        vm.startPrank(seller);
        escrow.withdraw(id);
        vm.expectRevert("Nothing to withdraw");
        escrow.withdraw(id);
        vm.stopPrank();
    }
}
