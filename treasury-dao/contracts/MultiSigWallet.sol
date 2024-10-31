// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MultiSigWallet {
    address[] public signers;
    uint256 public threshold;
    mapping(uint256 => mapping(address => bool)) public approvals;
    uint256 public transactionCount;

    struct Transaction {
        address to;
        uint256 value;
        bool executed;
    }

    mapping(uint256 => Transaction) public transactions;

    event TransactionCreated(uint256 indexed txIndex, address indexed to, uint256 value);
    event TransactionApproved(uint256 indexed txIndex, address indexed signer);
    event TransactionExecuted(uint256 indexed txIndex);

    modifier onlySigner() {
        require(isSigner(msg.sender), "Not a signer");
        _;
    }

    constructor(address[] memory _signers, uint256 _threshold) {
        require(_signers.length >= _threshold, "Invalid threshold");
        signers = _signers;
        threshold = _threshold;
    }

    function submitTransaction(address to, uint256 value) public onlySigner returns (uint256) {
        uint256 txIndex = transactionCount++;
        transactions[txIndex] = Transaction({
            to: to,
            value: value,
            executed: false
        });
        emit TransactionCreated(txIndex, to, value);
        return txIndex;
    }

    function approveTransaction(uint256 txIndex) public onlySigner {
        require(!approvals[txIndex][msg.sender], "Already approved");
        require(!transactions[txIndex].executed, "Already executed");

        approvals[txIndex][msg.sender] = true;
        emit TransactionApproved(txIndex, msg.sender);
    }

    function executeTransaction(uint256 txIndex) public onlySigner {
        require(countApprovals(txIndex) >= threshold, "Insufficient approvals");
        Transaction storage txn = transactions[txIndex];
        require(!txn.executed, "Transaction already executed");

        txn.executed = true;
        payable(txn.to).transfer(txn.value);
        emit TransactionExecuted(txIndex);
    }

    function isSigner(address addr) internal view returns (bool) {
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == addr) return true;
        }
        return false;
    }

    function countApprovals(uint256 txIndex) internal view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < signers.length; i++) {
            if (approvals[txIndex][signers[i]]) count++;
        }
        return count;
    }
}
