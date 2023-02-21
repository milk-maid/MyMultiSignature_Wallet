// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

interface IMyMultiSignature {


  struct Transaction {
    address to;
    uint value;
    bytes data;
    bool executed;
  }

  function submit(address _to, uint _value, bytes calldata _data) external;

  function approve(uint _txId) external;

  function _getApprovalCount(uint _txId) external view returns (uint);

  function execute(uint _txId) external;

  function revoke(uint _txId) external;
}