// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20.sol";
import "./Claimable.sol";

contract Pool is Claimable {

    uint256 constant MAX_RELEASE_DELAY = 11_520; // about 48h
    
    address tokenContract;
    uint256 minSupply;
    uint256 pendingSupply;
    address manager;
    address payable etherWallet;
    address tokenWallet;
    uint256 releaseDelay;
    uint256 maxTokensPerIssueCall;

    struct Account {
        uint256 nonce;  
        uint256 balance;
        uint256 pending;
        uint256 withdraw;
        uint256 release;
        bytes32 secret;
    }

    mapping(address => Account) accounts;

    constructor(address _tokenContract) public {
        tokenContract = _tokenContract;
        releaseDelay = 240;
        maxTokensPerIssueCall = 10000;
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

    function issueTokens(address _to, uint256 _amount, bytes32 _secretHash) public onlyAdmins() {
        require(_amount <= availableSupply(), "not enough available tokens");
        require(_amount <= maxTokensPerIssueCall, "amount exeed max tokens per call");
        uint256 _currentAmount = accounts[_to].pending;
        accounts[_to].secret = _secretHash;
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
        accounts[_account].secret = 0;
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

    function generatePaymentMessage(address _from, uint256 _value) public view returns (bytes memory) {
        Account memory _account = accounts[_from]; 
        require(_account.balance >= _value, "account balnace too low");
        return abi.encodePacked(
                uint8(0x2),
                this,
                uint32(_account.nonce),
                _from,
                _value
        );
    }

    function validatePaymentMessage(address _from, uint256 _value, uint8 _v, bytes32 _r, bytes32 _s) public view returns (bool) {
        bytes32 message  = _messageToRecover(keccak256(generatePaymentMessage(_from, _value)));
        address addr = ecrecover(message, _v, _r, _s);
        return addr == _from;      
    }

    function payment(address _from, uint256 _value, uint8 _v, bytes32 _r, bytes32 _s) public onlyAdmins() {
        require(validatePaymentMessage(_from, _value, _v, _r, _s), "wrong signature or data");
        require(accounts[_from].nonce != block.timestamp, "too soon");
        accounts[_from].nonce = block.timestamp;
        accounts[_from]. balance -= _value;
        minSupply -= _value;
    }

    function generateAcceptTokensMessage(address _for, bytes32 _secretHash) public view returns (bytes memory) {
        require(accounts[_for].secret == _secretHash, "wrong secret hash");
        return  abi.encodePacked(
                uint8(0x1),
                this,
                _secretHash,
                _for
        );
    }

    function validateAcceptTokensMessage(address _for, bytes32 _secretHash, uint8 _v, bytes32 _r, bytes32 _s) public view returns (bool) {
        bytes32 message  = _messageToRecover(keccak256(generateAcceptTokensMessage(_for, _secretHash)));
        address addr = ecrecover(message, _v, _r, _s);
        return addr == _for;
    }

    function acceptTokens(address _for, bytes memory _secret, uint8 _v, bytes32 _r, bytes32 _s) public onlyAdmins() {
        require(accounts[_for].secret == keccak256(_secret), "wrong secret");
        require(validateAcceptTokensMessage(_for, keccak256(_secret), _v, _r ,_s), "wrong signature or data");
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
        return keccak256(abi.encodePacked(prefix, unsignedMessageBytes));
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