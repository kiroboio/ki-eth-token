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

    uint256 s_fees;

    mapping(address => Transfer) s_transfers;

    constructor () public {
    }

    receive () external payable {
        require(false, "Minter: not accepting ether");
    }

    function transfer(address payable to, uint256 value, uint256 fee, bytes32 secretHash) payable external {
        require(msg.value == value.add(fee), "SafeTransfer: value mismatch");
        s_transfers[msg.sender] = Transfer({ to:to, value:value, fee: fee, secretHash:secretHash });
        s_fees.add(fee);
    }
    
    function retrieve(uint256 index) external {
        Transfer storage tr = s_transfers[msg.sender];
        uint256 value = tr.value.add(tr.fee);
        s_fees.sub(tr.fee);
        delete s_transfers[msg.sender];
        msg.sender.transfer(value);
    }

    function collect(address from, uint256 index, bytes calldata secret) external {
        Transfer storage tr = s_transfers[from];
        require(tr.to != address(0x0), "SafeTransfer: destination not found");
        require(keccak256(secret) == tr.secretHash, "SafeTransfer: wrong secret");
        uint256 value = tr.value;
        address payable to = tr.to;
        delete s_transfers[msg.sender];
        to.transfer(value);
    }

    function collectFees() external {
        s_fees = 0;
        msg.sender.transfer(s_fees);
    }

}
