// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./MultiSig.sol";

contract Wallet is MultiSig {
    address private target;

    event Received(address indexed from, uint256 value);

    function setTarget(address _target) public multiSig2of3(0) {
        target = _target;
    }

    function getTarget() public view returns (address) {
        return target;
    }

    fallback () external payable multiSig2of3(msg.value) {
        require(target != address(0), "no target");

        // solium-disable-next-line security/no-inline-assembly
        assembly {
                calldatacopy(0x00, 0x00, calldatasize())
                let res := delegatecall(gas(), sload(target_slot), 0x00, calldatasize(), 0, 0)
                returndatacopy(0x00, 0x00, returndatasize())
                if res { return(0x00, returndatasize()) }
                revert(0x00, returndatasize())
            }
    }

    receive () external payable {
      emit Received(msg.sender, msg.value);
    }

    function transfer(address payable to, uint256 amount) public payable multiSig2of3(msg.value) {
      transfer(to, amount);
    }

    constructor(address owner1, address owner2, address owner3) MultiSig(owner1, owner2, owner3) public {
    }

  
}