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

    event Deposited(address indexed from, address indexed to, uint256 value, uint256 fees, bytes32 secretHash);
    event SafeDeposited(address indexed from, uint256 value, uint256 fees, bytes32 secretHash, uint64 expiresAt, uint192 depositFees);
    event Retrieved(address indexed from, address indexed to, bytes32 indexed id, uint256 value);    
    event Collected(address indexed from, address indexed to, bytes32 indexed id, uint256 value);

    modifier onlyActivator() {
        require(hasRole(ACTIVATOR_ROLE, msg.sender), "SafeTransfer: not an activator");    
        _;
    }

    constructor (address activator) public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ACTIVATOR_ROLE, msg.sender);
        _setupRole(ACTIVATOR_ROLE, activator);
    }

    receive () external payable {
        require(false, "SafeTransfer: not accepting ether");
    }

    function collectFees(address payable wallet, uint256 amount) external onlyActivator() {
        s_fees = s_fees.sub(amount);
        wallet.transfer(amount);
    }

    function totalFees() external view returns (uint256) {
        return s_fees;
    }

    // ---------------------------------------------------------------------------

    function deposit(
        address payable to,
        uint256 value,
        uint256 fees,
        bytes32 secretHash
    ) 
        payable external
    {
        require(msg.value == value.add(fees), "SafeTransfer: value mismatch");
        require(value > 0, "SafeTransfer: no value");
        bytes32 id = keccak256(abi.encode(msg.sender, to, value, fees, secretHash));
        require(s_transfers[id] == 0, "SafeTransfer: request exist"); 
        s_transfers[id] = 0xffffffffffffffff; // expiresAt: max, depositFees: 0
        emit Deposited(msg.sender, to, value, fees, secretHash);
    }

    function timedDeposit(
        address payable to,
        uint256 value,
        uint256 fees,
        bytes32 secretHash,
        uint64 expiresAt,
        uint128 depositFees
    ) 
        payable external
    {
        require(msg.value == value.add(fees).add(depositFees), "SafeTransfer: value mismatch");
        require(value > 0, "SafeTransfer: no value");
        bytes32 id = keccak256(abi.encode(msg.sender, to, value, fees, secretHash));
        require(s_transfers[id] == 0, "SafeTransfer: request exist"); 
        s_transfers[id] = uint256(expiresAt) + (uint256(depositFees) << 64);
        emit Deposited(msg.sender, to, value, fees, secretHash);
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
        require(s_transfers[id]  > 0, "SafeTransfer: request not exist");
        delete s_transfers[id];
        uint256 valueToSend = value.add(fees);
        msg.sender.transfer(valueToSend);
        emit Retrieved(msg.sender, to, id, valueToSend);
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
        uint256 tr = s_transfers[id];
        require(tr > 0, "SafeTransfer: request not exist");
        require(uint64(tr) > now, "SafeTranfer: expired");
        require(keccak256(secret) == secretHash, "SafeTransfer: wrong secret");
        delete s_transfers[id];
        s_fees.add(fees);
        to.transfer(value);
        emit Collected(from, to, id, value);
    }

   function cancel(
        address payable from,
        address to,
        uint256 value,
        uint256 fees,
        bytes32 secretHash
    ) 
        external
        onlyActivator()
    {
        bytes32 id = keccak256(abi.encode(from, to, value, fees, secretHash));
        require(s_transfers[id] > 0, "SafeTransfer: request not exist");
        uint256 tr = s_transfers[id];
        require(uint64(tr) <= now, "SafeTranfer: not expired");
        delete  s_transfers[id];
        from.transfer(value.add(fees));
        emit Retrieved(from, to, id, value.add(fees));
    }

}
