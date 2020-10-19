// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";

contract SafeTransfer {
    using SafeMath for uint256;
    
    struct Transfer {
        address payable to;
        uint256 value;
        uint256 fee;
        bytes32 secretHash;
    }

    struct TransfersInfo {
        uint64 first;
        uint64 next;
        uint64 size;
    }

    uint256 s_fees;

    mapping(uint256 => Transfer) s_transfers;
    mapping(bytes32 => uint256) s_transfers2;
    mapping(address => TransfersInfo) s_transfersInfo;

    event Prepared(address indexed from, address indexed to, uint256 value, uint256 fee, bytes32 secretHash);
    event Retrieved(address indexed from, uint256 value);
    event Collected(address indexed from, address indexed to, uint256 value, uint256 fee);

    constructor () public {
    }

    receive () external payable {
        require(false, "SafeTransfer: not accepting ether");
    }

    function transfers(address user) external view returns (uint64 first, uint64 next, uint64 size) {
        TransfersInfo storage trInfo = s_transfersInfo[user];
        return (trInfo.first, trInfo.next, trInfo.size);
    }

   function transferRequest(address from, uint64 index) external view returns (address to, uint256 value, uint256 fee, bytes32 secretHash) {
        uint256 transferId = uint256(from)<<64 + uint256(index);
        Transfer storage tr = s_transfers[transferId];
        return (tr.to, tr.value, tr.fee, tr.secretHash);
    }

    function transfer(address payable to, uint256 value, uint256 fee, bytes32 secretHash) payable external {
        require(msg.value == value.add(fee), "SafeTransfer: value mismatch");
        require(value > 0, "SafeTransfer: no value");
        TransfersInfo storage transfersInfo = s_transfersInfo[msg.sender];
        uint256 transferId = uint256(msg.sender)<<64 + uint256(transfersInfo.next);
        s_transfers[transferId] = Transfer({ to:to, value:value, fee: fee, secretHash:secretHash });
        transfersInfo.size += 1;
        transfersInfo.next += 1;
        s_fees = s_fees.add(fee);
        emit Prepared(msg.sender, to, value, fee, secretHash);
    }

    function transfer2(address payable to, uint256 value, uint256 fee, bytes32 secretHash) payable external {
        require(msg.value == value.add(fee), "SafeTransfer: value mismatch");
        require(value > 0, "SafeTransfer: no value");
        bytes32 id = keccak256(abi.encode(msg.sender, to, value, fee, secretHash));
        require(s_transfers2[id] != 1, "SafeTransfer: request exist"); 
        s_transfers2[id] = 1;
        emit Prepared(msg.sender, to, value, fee, secretHash);
    }

    function retrieve2(address payable to, uint256 value, uint256 fees, bytes32 secretHash) external {
        bytes32 id = keccak256(abi.encode(msg.sender, to, value, fees, secretHash));
        require(s_transfers2[id] == 1, "SafeTransfer: request not exist");
        delete  s_transfers2[id];
        msg.sender.transfer(value.add(fees));
        emit Retrieved(msg.sender, value);
    }

    function collect2(address from, address payable to, uint256 value, uint256 fees, bytes32 secretHash, bytes calldata secret) external {
        bytes32 id = keccak256(abi.encode(msg.sender, to, value, fees, secretHash));
        require(s_transfers2[id] == 1, "SafeTransfer: request not exist");
        require(keccak256(secret) == secretHash, "SafeTransfer: wrong secret");
        delete  s_transfers2[id];
        s_fees.add(fees);
        to.transfer(value);
        emit Collected(from, to, value, fees);
    }

    function retrieve(uint64 index) external {
        uint256 transferId = uint256(msg.sender)<<64 + uint256(index);
        Transfer storage tr = s_transfers[transferId];
        TransfersInfo storage transfersInfo = s_transfersInfo[msg.sender];
        uint256 value = tr.value.add(tr.fee);
        require(value > 0, "SafeTransfer: no value");
        s_fees = s_fees.sub(tr.fee);
        delete s_transfers[transferId];
        transfersInfo.size -= 1;
        msg.sender.transfer(value);
        emit Retrieved(msg.sender, value);
    }

    function collect(address from, uint64 index, bytes calldata secret) external {
        uint256 transferId = uint256(from)<<64 + uint256(index);
        Transfer storage tr = s_transfers[transferId];
        TransfersInfo storage transfersInfo = s_transfersInfo[from];
        require(tr.to != address(0x0), "SafeTransfer: destination not found");
        require(keccak256(secret) == tr.secretHash, "SafeTransfer: wrong secret");
        uint256 value = tr.value;
        require(value > 0, "SafeTransfer: no value");
        address payable to = tr.to;
        delete s_transfers[transferId];
        transfersInfo.size -= 1;
        to.transfer(value);
        emit Collected(from, tr.to, tr.value, tr.fee);
    }

    function collectFees() external {
        s_fees = 0;
        msg.sender.transfer(s_fees);
    }

}
