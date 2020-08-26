// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;

abstract contract MultiSig {
    mapping(address => bool) s_owners;

    address s_markedForRemoval;

    struct Action {
        address owner;
        uint256 value;
        bytes   data;
    }

    Action s_action;

    constructor(address owner1, address owner2, address owner3) public {
        require(owner1 != address(0), "owner1 cannot be 0");
        require(owner2 != address(0), "owner2 cannot be 0");
        require(owner3 != address(0), "owner3 cannot be 0");
        require(owner1 != owner2, "owner1 cannot be owner2");
        require(owner2 != owner3, "owner2 cannot be owner3");
        require(owner1 != owner3, "owner1 cannot be owner3");
        s_owners[owner1] = true;
        s_owners[owner2] = true;
        s_owners[owner3] = true;
    }

    modifier multiSig2of3 (uint256 value) {
      require(s_owners[msg.sender] && msg.sender != s_markedForRemoval, 'only owners that are not being removed');
      if (s_action.owner == address(0)) {
          s_action.owner = msg.sender;
          s_action.data = msg.data;
          s_action.value = value;
          return;
      }
      require(s_action.owner != msg.sender, 'same owner cannot sign twice');
      require(s_action.value == value, 'must sign the same value');
      require(keccak256(s_action.data) == keccak256(msg.data), 'must sign the same data');
      s_action.owner = address(0);
      _;
    }

    function cancel() external {
      require(s_owners[msg.sender], 'only owners can cancel');
      require(s_markedForRemoval != msg.sender, 'only owners that are not being replaced can cancel');
      s_action.owner = address(0);
      s_markedForRemoval = address(0);
    }

    function _replaceOwner(address owner, address newOwner)
      private 
      multiSig2of3(0)
    {
      s_owners[owner] = false;
      s_owners[newOwner] = true;
      s_markedForRemoval = address(0);
    }

    function replaceOwner(address owner, address newOwner) external {
      require(owner != address(0), 'owner cannot be 0');
      require(newOwner != address(0), 'new Owner cannot be 0');
      require(s_owners[owner] == true, 'owner must exist');
      require(owner != msg.sender, "senders cannot replace themselves");
      require(s_owners[newOwner] == false, 'new owner must not exist');
      s_markedForRemoval = owner;
      _replaceOwner(owner, newOwner);
    }

    function isOwner() external view returns (bool) {
      return s_owners[msg.sender];
    }

}