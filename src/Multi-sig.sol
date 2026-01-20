// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract TxScopedMultiSig {
    
    error InvalidAddress();
    error InvalidSigners();
    error InvalidThreshold();
    error TransactionNotExist();
    error AlreadyApproved();
    error NotApproved();
    error AlreadyExecuted();
    error NotEnoughConfirmations();
    error ExecutionFailed();

    event TransactionCreated(
        uint256 txnId,
        address indexed owner,
        address indexed to,
        uint256 value
    );

    event TransactionApproved(
        uint256 txnId,
        address indexed approver,
        uint256 confirmations
    );

    event TransactionRevoke(
        uint256 txnId,
        address indexed revoker,
        uint256 confirmations
    );

    event TransactionExecuted(uint256 txnId, address indexed executor);

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
        uint256 requiredConfirmations;
    }

    Transaction[] public transactions;

    // txId => signer => allowed?
    mapping(uint256 => mapping(address => bool)) public isAllowedSigner;
    // txId => signer => approved?
    mapping(uint256 => mapping(address => bool)) public approved;

    modifier validAddress(address user) {
        if (user == address(0)) revert InvalidAddress();
        _;
    }

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data,
        address[] calldata _signers,
        uint256 _requiredConfirmations
    ) external validAddress(_to) returns(uint256 txnId) {
        if (_signers.length == 0) revert InvalidSigners();
        if (
            _requiredConfirmations == 0 ||
            _requiredConfirmations > _signers.length
        ) revert InvalidThreshold();

        txnId = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                confirmations: 0,
                requiredConfirmations: _requiredConfirmations
            })
        );

        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            if (signer == address(0)) revert InvalidAddress();
            if (isAllowedSigner[txnId][signer]) revert InvalidSigners();
            isAllowedSigner[txnId][signer] = true;
        }

        emit TransactionCreated(txnId, msg.sender, _to, _value);
    }

    function approveTransaction(uint256 txnId) external {
        if (txnId >= transactions.length) revert TransactionNotExist();

        Transaction storage txn = transactions[txnId];

        if (txn.executed) revert AlreadyExecuted();
        if (!isAllowedSigner[txnId][msg.sender]) revert InvalidSigners();
        if (approved[txnId][msg.sender]) revert AlreadyApproved();

        approved[txnId][msg.sender] = true;
        txn.confirmations += 1;

        emit TransactionApproved(txnId, msg.sender, txn.confirmations);
    }

    function revokeTransaction(uint256 txnId) external {
        if (txnId >= transactions.length) revert TransactionNotExist();

        Transaction storage txn = transactions[txnId];

        if (txn.executed) revert AlreadyExecuted();
        if (!isAllowedSigner[txnId][msg.sender]) revert InvalidSigners();
        if (!approved[txnId][msg.sender]) revert NotApproved();

        approved[txnId][msg.sender] = false;
        txn.confirmations -= 1;

        emit TransactionRevoke(txnId, msg.sender, txn.confirmations);
    }

    function executeTransaction(uint256 txnId) external {
        if (txnId >= transactions.length) revert TransactionNotExist();

        Transaction storage txn = transactions[txnId];

        if (txn.executed) revert AlreadyExecuted();
        if (txn.confirmations < txn.requiredConfirmations)
            revert NotEnoughConfirmations();

        txn.executed = true;

        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        if (!success) revert ExecutionFailed();

        emit TransactionExecuted(txnId, msg.sender);
    }

    function getTransaction(
        uint256 txnId
    ) external view returns (Transaction memory txn) {
        if (txnId >= transactions.length) revert TransactionNotExist();
        txn = transactions[txnId];
    }
}
