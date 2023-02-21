// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import {IMyMultiSignature} from "./IMyMultiSignature.sol";

contract MyMultiSignature is IMyMultiSignature {

    address[] public owners;
    mapping (address => bool) public isOwner; 
    uint public required;

    Transaction[] public transactions;
    mapping (uint => mapping (address => bool)) public approved;

    constructor(address[] memory _owners, uint _required ) {
        require(_owners.length > 0, "OWNERS REQUIRED");
        require(_required > 0 && _required <= _owners.length, "Invalid Required Number Of Owners");

        for (uint i; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "INVALID OWNER");
            require(!isOwner[owner], "A NEW OWNER REQIURED");

            isOwner[owner] = true;
            owners.push(owner);
        } 
        required = _required;
    }
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(address _to, uint _value, bytes calldata _data) external onlyOwner {
        transactions.push(Transaction({ to: _to, value: _value, data: _data, executed: false}));
        emit Submit(transactions.length - 1);
    }

    function approve(uint _txId) external onlyOwner txExist(_txId) notApproved(_txId) notExecuted(_txId) {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function _getApprovalCount(uint _txId) private view returns (uint count) {
        for (uint i; i < owners.length; i++) 
        {
            if (approved[_txId][owners[i]]) {
                count += 1;
            }   
        }
    }

    function execute(uint _txId) external txExist(_txId) notExecuted(_txId) {
        require(_getApprovalCount(_txId) >= required, "Approvals < Required");

        Transaction storage transaction = transactions[_txId];
        transaction.executed = true; 
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);

        require(success, "tx FAILED");

        emit Execute(_txId);
    }

    function revoke(uint _txId) external onlyOwner txExist(_txId) notExecuted(_txId) {
        require(approved[_txId][msg.sender], "tx NOT APPROVED");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "ONLY OWNER CAN DO THIS");
        _;
    }

    modifier txExist(uint _txId) {
        require(_txId < transactions.length, "tx DOES NOT EXIST");
        _;
    }

    modifier notApproved(uint _txId) {
        require(!approved[_txId][msg.sender], "tx ALREADY APPROVED");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "tx ALREADY EXECUTED");
        _;
    }
}