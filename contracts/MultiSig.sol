// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

abstract contract MultiSig {
    mapping(address => bool) private owners;

    struct Action {
        address owner;
        uint256 value;
        bytes   data;
    }

    Action private action;

    constructor(address owner1, address owner2, address owner3) public {

        require(owner1 != address(0), "owner1 cannot be 0");
        require(owner2 != address(0), "owner2 cannot be 0");
        require(owner3 != address(0), "owner3 cannot be 0");

        require(owner1 != owner2, "owner1 cannot be owner2");
        require(owner2 != owner3, "owner2 cannot be owner3");
        require(owner1 != owner3, "owner1 cannot be owner3");

        owners[owner1] = true;
        owners[owner2] = true;
        owners[owner3] = true;
    }

    modifier multiSig2of3 (uint256 value) {
      require(owners[msg.sender], 'only owners');

      if (action.owner == address(0)) {
          action.owner = msg.sender;
          action.data = msg.data;
          action.value = value;
          return;
      }

      require(action.owner != msg.sender, 'same owner cannot sign twice');
      require(action.value == value, 'must sign the same value');
      require(keccak256(action.data) == keccak256(msg.data), 'must sign the same data');

      action.owner = address(0);
      _;
    }

    function isOwner() public view returns (bool) {
      return owners[msg.sender];
    }

    function cancel() public {
      require(owners[msg.sender], 'only owners');
      action.owner = address(0);
    }

    function replaceOwner(address _owner, address _newOwner) public multiSig2of3(0) {
      require(owners[_owner] == true, 'owner should exist');
      require(owners[_newOwner] == false, 'new owner should not exist');
      owners[_owner] = false;
      owners[_newOwner] = true;
    }
}