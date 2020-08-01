// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20.sol";
import "./Claimable.sol";

contract Pool is Claimable {

    address private tokenContract;
    uint256 private minSupply;
    uint256 private pendingSupply;
    
    address private manager;
    address payable private etherWallet;
    address private tokenWallet;
    uint256 private releaseDelay;
    uint256 constant private MAX_RELEASE_DELAY = 11520; // about 48h
    uint256 private maxTokensPerIssueCall;

    struct Account {
        uint256 nonce;  
        uint256 balance;
        uint256 pending;
        uint256 withdraw;
        uint256 release;
    }

    mapping(address => Account) private accounts;

    constructor(address _tokenContract) public {
        tokenContract = _tokenContract;
        releaseDelay = 240;
        maxTokensPerIssueCall = 1000;
    }

    modifier onlyAdmins() {
        require(msg.sender == owner || msg.sender == manager, "not owner or manager");
        _;
    }

    function setReleaseDelay(uint256 _blocks) public onlyOwner() {
        require(_blocks <= MAX_RELEASE_DELAY, "exeeds max release delay");
        releaseDelay = _blocks;
    }

    function setMaxTokensPerIssueCall(uint256 _tokens) public onlyOwner() {
        maxTokensPerIssueCall = _tokens;
    }

    function issueTokens(address _to, uint256 _amount) public onlyAdmins() {
        require(_amount <= availableSupply(), "not enough available tokens");
        require(_amount <= maxTokensPerIssueCall, "amount exeed max tokens per call");
        uint256 _currentAmount = accounts[_to].pending;
        if (_currentAmount > _amount) {
            accounts[_to].pending = _amount;
            pendingSupply += _currentAmount - _amount;
        } else if (_currentAmount < _amount) {
            accounts[_to].pending = _amount;
            pendingSupply += _amount - _currentAmount;
        }
    }

    function _acceptTokens(address _account) internal {
        uint256 _pending = accounts[_account].pending;
        require(_pending > 0, "no pending tokens");
        accounts[_account].pending = 0;
        accounts[_account].balance += _pending;
        pendingSupply -= _pending;
    }

    function acceptTokens() public {
        _acceptTokens(msg.sender);
    }

    function setEtherWallet(address payable _etherWallet) public onlyOwner() {
        etherWallet = _etherWallet;
    }

    function setTokenWallet(address _tokenWallet) public onlyOwner() {
        tokenWallet = _tokenWallet;
    }

    function transferEther(uint256 _value) public onlyAdmins() {
        require(etherWallet != address(0), "ether wallet not set");
        etherWallet.transfer(_value);
    }

    function transferTokens(uint256 _value) public onlyAdmins() {
        require(tokenWallet != address(0), "token wallet not set");
        require(_value <= availableSupply(), "value larget than available tokens");
        ERC20(tokenContract).transfer(tokenWallet, _value);
    }

    function accountNonce(address _account) public view returns (uint256) {
        return accounts[_account].nonce; 
    }

    function accountBalance(address _account) public view returns (uint256) {
        return accounts[_account].balance; 
    }

    function generatePaymentMessageToSign(address _from, uint256 _value) public view returns (bytes32) {
        Account memory _account = accounts[_from]; 
        require(_account.balance >= _value, "account balnace too low");
        bytes32 message = keccak256(
            abi.encodePacked(
                _account.nonce,
                this,
                _value,
                _from
            )
        );
        return message;
    }

    function paymentBySig(address _from, uint256 _value, uint8 _v, bytes32 _r, bytes32 _s) public onlyAdmins() {
        bytes32 message  = _messageToRecover(generatePaymentMessageToSign(_from, _value));
        address addr = ecrecover(message, _v+27, _r, _s);
        require(addr == _from, "wrong signature");
        if (accounts[_from].nonce == block.timestamp) {
            accounts[_from].nonce += 1;
        } else {
            accounts[_from].nonce = block.timestamp;
        }
        accounts[_from]. balance -= _value;
        minSupply -= _value;
    }

    function generateAcceptTokensMessageToSign(address _for, uint256 _secret) public view returns (bytes32) {
        bytes32 message = keccak256(
            abi.encodePacked(
                _secret,
                this,
                _for
            )
        );
        return message;
    }

    function acceptTokensBySig(address _for, uint256 _secret, uint8 _v, bytes32 _r, bytes32 _s) public onlyAdmins() {
        bytes32 message  = _messageToRecover(generateAcceptTokensMessageToSign(_for, _secret));
        address addr = ecrecover(message, _v+27, _r, _s);
        require(addr == _for, "wrong signature");
        _acceptTokens(_for);
    }

    function setManager(address _manager) public onlyOwner() {
        manager = _manager; 
    }
  
    function totalSupply() view public returns (uint256) {
        return ERC20(tokenContract).balanceOf(address(this));
    }

    function availableSupply() view public returns (uint256) {
        return ERC20(tokenContract).balanceOf(address(this)) - minSupply - pendingSupply;
    }

    function deposit(uint256 value) public {
        require(ERC20(tokenContract).allowance(msg.sender, address(this)) >= value, "ERC20 allowance too low");
        ERC20(tokenContract).transferFrom(msg.sender, address(this), value);
        accounts[msg.sender].balance += value;
        minSupply += value;
    }

    function postWithdraw(uint256 value) public {
        require(accounts[msg.sender].balance >= value, "not enough tokens");
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
        accounts[msg.sender].balance -= value;
        minSupply -= value;
        ERC20(tokenContract).transfer(msg.sender, value);
    }

    function _messageToRecover(bytes32 hashedUnsignedMessage) private pure returns (bytes32)
    {
        bytes memory unsignedMessageBytes = _hashToAscii(
            hashedUnsignedMessage
        );
        bytes memory prefix = "\x19Ethereum Signed Message:\n64";
        return keccak256(abi.encodePacked(prefix,unsignedMessageBytes));
    }

    function _hashToAscii(bytes32 hash) private pure returns (bytes memory) {
        bytes memory s = new bytes(64);
        for (uint i = 0; i < 32; i++) {
            byte  b = hash[i];
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2*i] = _char(hi);
            s[2*i+1] = _char(lo);
        }
        return s;
    }

    function _char(byte b) private pure returns (byte c) {
        if (b < byte(uint8(10))) {
            return byte(uint8(b) + 0x30);
        } else {
            return byte(uint8(b) + 0x57);
        }
    }

}