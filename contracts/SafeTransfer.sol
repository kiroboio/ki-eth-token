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

    event OldDeposited(address indexed from, address indexed to, uint256 value, uint256 fees, bytes32 secretHash);
    event OldRetrieved(address indexed from, address indexed to, bytes32 indexed id, uint256 value);
    
    event Deposited(address indexed from, uint256 value, uint256 fees, bytes32 secretHash);
    event SafeDeposited(address indexed from, uint256 value, uint256 fees, bytes32 secretHash, uint64 expiresAt, uint192 depositFees);
    event Retrieved(address indexed from, bytes32 indexed id, uint256 value);
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

    function deposit(
        uint256 value,
        uint256 fees,
        bytes32 secretHash
    ) 
        payable external
    {
        require(msg.value == value.add(fees), "SafeTransfer: value mismatch");
        require(value > 0, "SafeTransfer: no value");
        bytes32 id = keccak256(abi.encode(msg.sender, value, fees, secretHash));
        require(s_transfers[id] == 0, "SafeTransfer: request exist"); 
        s_transfers[id] = 0xffffffffffffffff; // expiresAt: max, depositFees: 0
        emit Deposited(msg.sender, value, fees, secretHash);
    }

    function saferDeposit(
        uint256 value,
        uint256 fees,
        bytes32 secretHash,
        uint64 expiresAt,
        uint192 depositFees
    ) 
        payable external
    {
        require(msg.value == value.add(fees).add(depositFees), "SafeTransfer: value mismatch");
        require(value > 0, "SafeTransfer: no value");
        bytes32 id = keccak256(abi.encode(msg.sender, value, fees, secretHash));
        require(s_transfers[id] == 0, "SafeTransfer: request exist"); 
        s_transfers[id] = expiresAt + depositFees << 64;
        emit SafeDeposited(msg.sender, value, fees, secretHash, expiresAt, depositFees);
    }

    function retrieve(
        uint256 value,
        uint256 fees,
        bytes32 secretHash
    )   
        external 
    {
        bytes32 id = keccak256(abi.encode(msg.sender, value, fees, secretHash));
        require(s_transfers[id]  > 0, "SafeTransfer: request not exist");
        delete  s_transfers[id];
        msg.sender.transfer(value.add(fees));
        emit Retrieved(msg.sender, id, value.add(fees));
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
        bytes32 id = keccak256(abi.encode(from, value, fees, secretHash));
        uint256 tr = s_transfers[id];
        require(tr > 0, "SafeTransfer: request not exist");
        require(uint64(tr) < now, "SafeTranfer: expired");
        require(keccak256(abi.encode(to, secret)) == secretHash, "SafeTransfer: wrong secret");
        delete s_transfers[id];
        s_fees.add(fees);
        to.transfer(value);
        emit Collected(from, to, id, value);
    }

    function cancel(
        address payable from,
        uint256 value,
        uint256 fees,
        bytes32 secretHash
    ) 
        external
        onlyActivator()
    {
        bytes32 id = keccak256(abi.encode(from, value, fees, secretHash));
        require(s_transfers[id] > 0, "SafeTransfer: request not exist");
        uint256 tr = s_transfers[id];
        require(uint64(tr) >= now, "SafeTranfer: not expired");
        delete  s_transfers[id];
        from.transfer(value.add(fees));
        emit Retrieved(from, id, value.add(fees));
    }

    function collectFees(address payable wallet, uint256 amount) external onlyActivator() {
        s_fees = s_fees.sub(amount);
        wallet.transfer(amount);
    }

    function totalFees() external view returns (uint256) {
        return s_fees;
    }

    // ---------------------------------------------------------------------------

    function oldDeposit(
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
        emit OldDeposited(msg.sender, to, value, fees, secretHash);
    }

        function oldSaferDeposit(
        address payable to,
        uint256 value,
        uint256 fees,
        bytes32 secretHash,
        uint64 expiresAt,
        uint192 depositFees
    ) 
        payable external
    {
        require(msg.value == value.add(fees).add(depositFees), "SafeTransfer: value mismatch");
        require(value > 0, "SafeTransfer: no value");
        bytes32 id = keccak256(abi.encode(msg.sender, to, value, fees, secretHash));
        require(s_transfers[id] == 0, "SafeTransfer: request exist"); 
        s_transfers[id] = expiresAt + depositFees << 64;
        emit OldDeposited(msg.sender, to, value, fees, secretHash);
    }

    function oldRetrieve(
        address payable to,
        uint256 value,
        uint256 fees,
        bytes32 secretHash
    )   
        external 
    {
        bytes32 id = keccak256(abi.encode(msg.sender, to, value, fees, secretHash));
        require(s_transfers[id]  > 0, "SafeTransfer: request not exist");
        delete  s_transfers[id];
        msg.sender.transfer(value.add(fees));
        emit OldRetrieved(msg.sender, to, id, value.add(fees));
    }

    function oldCollect(
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
        require(uint64(tr) < now, "SafeTranfer: expired");
        require(keccak256(secret) == secretHash, "SafeTransfer: wrong secret");
        delete s_transfers[id];
        s_fees.add(fees);
        to.transfer(value);
        emit Collected(from, to, id, value);
    }

   function oldCancel(
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
        require(uint64(tr) >= now, "SafeTranfer: not expired");
        delete  s_transfers[id];
        from.transfer(value.add(fees));
        emit OldRetrieved(from, to, id, value.add(fees));
    }

}
