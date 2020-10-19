// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControl.sol";

contract SafeTransfer is AccessControl {
    using SafeMath for uint256;

    // keccak256("ACTIVATOR_ROLE");
    bytes32 public constant ACTIVATOR_ROLE = 0xec5aad7bdface20c35bc02d6d2d5760df981277427368525d634f4e2603ea192;

    uint256 s_fees;
    mapping(bytes32 => uint256) s_transfers;

    event Deposited(address indexed from, address indexed to, uint256 value, uint256 fee, bytes32 secretHash);
    event Retrieved(address indexed from, bytes32 indexed id, uint256 value);
    event Collected(address indexed from, address indexed to, bytes32 indexed id, uint256 value);

    modifier onlyActivator() {
        require(hasRole(ACTIVATOR_ROLE, msg.sender), "SafeTransfer: not an activator");    
        _;
    }

    constructor () public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ACTIVATOR_ROLE, msg.sender);
    }

    receive () external payable {
        require(false, "SafeTransfer: not accepting ether");
    }

    function deposit(
        address payable to,
        uint256 value,
        uint256 fee,
        bytes32 secretHash
    ) 
        payable external
    {
        require(msg.value == value.add(fee), "SafeTransfer: value mismatch");
        require(value > 0, "SafeTransfer: no value");
        bytes32 id = keccak256(abi.encode(msg.sender, to, value, fee, secretHash));
        require(s_transfers[id] != 1, "SafeTransfer: request exist"); 
        s_transfers[id] = 1;
        emit Deposited(msg.sender, to, value, fee, secretHash);
    }

    function retrieve(
        address payable to,
        uint256 value,
        uint256 fees,
        bytes32 secretHash
    ) 
        external 
    {
        bytes32 id = keccak256(abi.encode(msg.sender, to, value, fees, secretHash));
        require(s_transfers[id] == 1, "SafeTransfer: request not exist");
        delete  s_transfers[id];
        msg.sender.transfer(value.add(fees));
        emit Retrieved(msg.sender, id, value);
    }

    function collect(
        address from,
        address payable to,
        uint256 value,
        uint256 fees,
        bytes32 secretHash,
        bytes calldata secret
    ) 
        external
        onlyActivator()
    {
        bytes32 id = keccak256(abi.encode(from, to, value, fees, secretHash));
        require(s_transfers[id] == 1, "SafeTransfer: request not exist");
        require(keccak256(secret) == secretHash, "SafeTransfer: wrong secret");
        delete s_transfers[id];
        s_fees.add(fees);
        to.transfer(value);
        emit Collected(from, to, id, value);
    }

    function collectFees() external onlyActivator() {
        s_fees = 0;
        msg.sender.transfer(s_fees);
    }

}
