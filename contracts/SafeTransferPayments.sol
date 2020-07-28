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
    uint256 public minSupply;
    
    struct Account {
        uint256 nonce;
        uint256 value;
        uint256 withdraw;
        uint256 release;
    }

    mapping(address => Account) internal accounts;

    constructor(address _tokenContract) public {
      tokenContract = _tokenContract;
    }
  
    function totalSupply() view public returns (uint256) {
      return ERC20(tokenContract).balanceOf(address(this));
    }

    function availableSupply() view public returns (uint256) {
      return ERC20(tokenContract).balanceOf(address(this)) - minSupply;
    }

    function deposit(uint256 value) public {
      require(ERC20(tokenContract).allowance(msg.sender, address(this)) >= value, "ERC20 allowance too low");
      ERC20(tokenContract).transferFrom(msg.sender, address(this), value);
      accounts[msg.sender].value += value;
      minSupply += value;
    }

    function postWithdraw(uint256 value) public {
      require(accounts[msg.sender].value >= value, "not enough tokens");
      require(value > 0, "cannot withdraw");
      accounts[msg.sender].withdraw = value;
      accounts[msg.sender].release = block.number + 240;
    }

    function cancelWithdraw() public {
      accounts[msg.sender].withdraw = 0;
      accounts[msg.sender].release = 0;
    }

    function withdraw() public {
      require(accounts[msg.sender].release > 0, "no withdraw request");
      require(accounts[msg.sender].release < block.number, "too soon");
      uint256 value = accounts[msg.sender].withdraw;
      accounts[msg.sender].withdraw = 0;
      accounts[msg.sender].release = 0;
      accounts[msg.sender].value -= value;
      minSupply -= value;
      ERC20(tokenContract).transfer(msg.sender, value);
    }

}