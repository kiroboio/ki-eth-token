// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
}

contract SafeTransferPayments {

    address public tokenContract;
    
    struct Account {
        uint256 nonce;
        uint256 value;
    }

    mapping(address => Account) internal accounts;


    constructor(address _tokenContract) public {
      tokenContract = _tokenContract;
    }
  
    function totalSupply() view public returns (uint256) {
      return ERC20(tokenContract).balanceOf(address(this));
    }
}