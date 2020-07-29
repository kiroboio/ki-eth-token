// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./MultiSig.sol";

contract Wallet is MultiSig {
    mapping(address => bool) private owners;

    fallback () external payable {
    }

    receive () external payable {
    }

    constructor(address owner1, address owner2, address owner3) MultiSig(owner1, owner2, owner3) public {
    }

  
}