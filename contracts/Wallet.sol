// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;

import "./MultiSig.sol";

contract Wallet is MultiSig {
    address s_target;

    event Received(address indexed from, uint256 value);
    event Transfered(address indexed to, uint256 value);
    event ContractDeployed(address c);
    event ContractDeployed2(address c);

    constructor(address owner1, address owner2, address owner3)
        MultiSig(owner1, owner2, owner3)
        public
    {
    }

    receive () external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback () external multiSig2of3(0) {
        require(s_target != address(0), "Wallet: no target");

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
        multiSig2of3(0)
    {
        to.transfer(value);
        emit Transfered(to, value);
    }

    function deployContract_(bytes memory bytecode) external multiSig2of3(0) returns (address addr) {
        require(bytecode.length != 0, "Wallet: bytecode length is zero");
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
        emit ContractDeployed(addr);
    }

    function deployContract2_(bytes memory bytecode, bytes32 salt) external multiSig2of3(0) returns (address addr) {
        require(bytecode.length != 0, "Wallet: bytecode length is zero");
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
        emit ContractDeployed2(addr);
    }

    function setOwnTarget_(address target) external multiSig2of3(0) {
        s_target = target;
    }

    function getOwnTarget_() external view returns (address) {
        return s_target;
    }
  
}