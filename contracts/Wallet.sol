// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./MultiSig.sol";

contract Wallet is MultiSig {
    address s_target;

    event Received(address indexed from, uint256 value);
    event Transfered(address indexed to, uint256 value);

    constructor(address owner1, address owner2, address owner3)
        MultiSig(owner1, owner2, owner3)
        public
    {
    }

    receive () external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback () external payable multiSig2of3(msg.value) {
        require(s_target != address(0), "no target");

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            calldatacopy(0x00, 0x00, calldatasize())
            let res := call(
                gas(),
                sload(s_target_slot),
                callvalue(),
                0x00,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0x00, 0x00, returndatasize())
            if res { return(0x00, returndatasize()) }
            revert(0x00, returndatasize())
        }
    }

    function transferOwnEther_(address payable to, uint256 value) 
        external 
        payable
        multiSig2of3(msg.value)
    {
        to.transfer(value);
        emit Transfered(to, value);
    }

    function setOwnTarget_(address target) external multiSig2of3(0) {
        s_target = target;
    }

    function getOwnTarget_() external view returns (address) {
        return s_target;
    }
  
}