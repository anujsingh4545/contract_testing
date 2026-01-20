// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.2 <0.9.0;

import "forge-std/Test.sol";
import "../src/Multi-sig.sol";

contract MuliSigTest is Test {
    TxScopedMultiSig multiSig;

    address userA = address(1);
    address userB = address(2);
    address userC = address(3);
    address userD = address(4);
    address userE = address(5);

    function setUp() public {
        multiSig = new TxScopedMultiSig();

        vm.deal(userA, 10 ether);
        vm.deal(userB, 10 ether);
        vm.deal(userC, 10 ether);
        vm.deal(userD, 10 ether);
        vm.deal(userE, 10 ether);
    }

    // SUBMIT TRANSACTION

    function test_SubmitTransaction_Success() public {
        address[] memory signers = new address[](2);
        signers[0] = userA;
        signers[1] = userB;

        uint256 txId = multiSig.submitTransaction(userC, 0, "", signers, 2);

        assertEq(txId, 0);
    }

    function test_Revert_SubmitTransaction_EmptySigners() public {
        address[] memory signers = new address[](0);

        vm.expectRevert();
        multiSig.submitTransaction(userC, 0, "", signers, 1);
    }

    function test_Revert_SubmitTransaction_InvalidThreshold() public {
        address[] memory signers = new address[](1);
        signers[0] = userA;

        vm.expectRevert();
        multiSig.submitTransaction(userC, 0, "", signers, 2);
    }

    // APPROVE TRANSACTION

    function test_ApproveTransaction_Success() public {
        address[] memory signers = new address[](2);
        signers[0] = userA;
        signers[1] = userB;

        uint256 txId = multiSig.submitTransaction(userC, 0, "", signers, 2);

        vm.prank(userA);
        multiSig.approveTransaction(txId);

        TxScopedMultiSig.Transaction memory txn = multiSig.getTransaction(txId);
        assertEq(txn.confirmations, 1);
    }

    function test_Revert_ApproveTransaction_NotAllowedSigner() public {
        address[] memory signers = new address[](1);
        signers[0] = userA;

        uint256 txId = multiSig.submitTransaction(userC, 0, "", signers, 1);

        vm.prank(userB);
        vm.expectRevert();
        multiSig.approveTransaction(txId);
    }

    function test_Revert_DoubleApprove() public {
        address[] memory signers = new address[](1);
        signers[0] = userA;

        uint256 txId = multiSig.submitTransaction(userC, 0, "", signers, 1);

        vm.startPrank(userA);
        multiSig.approveTransaction(txId);
        vm.expectRevert();
        multiSig.approveTransaction(txId);
        vm.stopPrank();
    }

    // REVOKE APPROVAL

    function test_RevokeApproval_Success() public {
        address[] memory signers = new address[](1);
        signers[0] = userA;

        uint256 txId = multiSig.submitTransaction(userC, 0, "", signers, 1);

        vm.startPrank(userA);
        multiSig.approveTransaction(txId);
        multiSig.revokeTransaction(txId);
        vm.stopPrank();

        TxScopedMultiSig.Transaction memory txn = multiSig.getTransaction(txId);
        assertEq(txn.confirmations, 0);
    }

    function test_Revert_RevokeWithoutApproval() public {
        address[] memory signers = new address[](1);
        signers[0] = userA;

        uint256 txId = multiSig.submitTransaction(userC, 0, "", signers, 1);

        vm.prank(userA);
        vm.expectRevert();
        multiSig.revokeTransaction(txId);
    }

    // EXECUTION

    function test_ExecuteTransaction_ETHTransfer() public {
        address[] memory signers = new address[](2);
        signers[0] = userA;
        signers[1] = userB;

        uint256 txId = multiSig.submitTransaction(
            userD,
            1 ether,
            "",
            signers,
            2
        );

        vm.prank(userA);
        multiSig.approveTransaction(txId);

        vm.prank(userB);
        multiSig.approveTransaction(txId);
        
        vm.deal(address(multiSig), 10 ether);

        uint256 balanceBefore = userD.balance;
        multiSig.executeTransaction(txId);

        assertEq(userD.balance, balanceBefore + 1 ether);
    }

    function test_Revert_Execute_NotEnoughConfirmations() public {
        address[] memory signers = new address[](2);
        signers[0] = userA;
        signers[1] = userB;

        uint256 txId = multiSig.submitTransaction(userD, 0, "", signers, 2);

        vm.prank(userA);
        multiSig.approveTransaction(txId);

        vm.expectRevert();
        multiSig.executeTransaction(txId);
    }

    function test_Revert_ExecuteTwice() public {
        address[] memory signers = new address[](1);
        signers[0] = userA;

        uint256 txId = multiSig.submitTransaction(userD, 0, "", signers, 1);

        vm.prank(userA);
        multiSig.approveTransaction(txId);

        multiSig.executeTransaction(txId);

        vm.expectRevert();
        multiSig.executeTransaction(txId);
    }

    // PARALLEL TRANSACTIONS

    function test_ParallelTransactions_Isolated() public {
        address[] memory signers1=  new address[](1);
        signers1[0] = userA;

        address[] memory signers2 =  new address[](1);
        signers2[0] = userB;

        uint256 tx1 = multiSig.submitTransaction(userC, 0, "", signers1, 1);

        uint256 tx2 = multiSig.submitTransaction(userD, 0, "", signers2, 1);

        vm.prank(userA);
        multiSig.approveTransaction(tx1);

        vm.prank(userB);
        multiSig.approveTransaction(tx2);

        TxScopedMultiSig.Transaction memory txn1 = multiSig.getTransaction(tx1);
        TxScopedMultiSig.Transaction memory txn2 = multiSig.getTransaction(tx2);

        assertEq(txn1.confirmations, 1);
        assertEq(txn2.confirmations, 1);
    }
}
