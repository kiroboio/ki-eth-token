// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./MultiSig.sol";

contract Wallet is MultiSig {
    address target;

    event Received(address indexed from, uint256 value);
    event Transfered(address indexed to, uint256 value);

    function setOwnTarget_(address _target) public multiSig2of3(0) {
        target = _target;
    }

    function getOwnTarget_() public view returns (address) {
        return target;
    }

    fallback () external payable multiSig2of3(msg.value) {
        require(target != address(0), "no target");

        // solium-disable-next-line security/no-inline-assembly
        assembly {
                calldatacopy(0x00, 0x00, calldatasize())
                let res := call(gas(), sload(target_slot), callvalue(), 0x00, calldatasize(), 0, 0)
                returndatacopy(0x00, 0x00, returndatasize())
                if res { return(0x00, returndatasize()) }
                revert(0x00, returndatasize())
            }
    }

    receive () external payable {
        emit Received(msg.sender, msg.value);
    }

    function transferOwnEther_(address payable _to, uint256 _value) public payable multiSig2of3(msg.value) {
        _to.transfer(_value);
        emit Transfered(_to, _value);
    }

    constructor(address owner1, address owner2, address owner3) MultiSig(owner1, owner2, owner3) public {
    }

  
}