// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20.sol";
import "./Claimable.sol";

struct Account {
    uint256 nonce;  
    uint256 balance;
    uint256 pending;
    uint256 withdrawal;
    uint256 release;
    bytes32 secretHash;
}

library AccountUtils {
    function initNonce(Account storage self) internal {
        if (self.nonce == 0) {
            self.nonce =
                uint256(1) << 240 |
                uint256(blockhash(block.number-1)) << 80 >> 32 |
                block.timestamp;
        }
    }
    function updateNonce(Account storage self) internal {
        uint256 count = self.nonce >> 240;
        uint256 nonce = 
            ++count << 240 |
            uint256(blockhash(block.number-1)) << 80 >> 32 |
            block.timestamp;
        require(uint16(self.nonce) != uint16(nonce), "too soon");
        self.nonce = nonce;
    }
}

/*

    Owner
    setManager(address manager) public onlyOwner()
    setReleaseDelay(uint256 blocks) public onlyOwner()
    setMaxTokensPerIssue(uint256 tokens) public onlyOwner()
    resyncTotalSupply() public onlyAdmins() returns (uint256)
    setTokenWallet(address tokenWallet) public onlyOwner()
    setEtherWallet(address payable etherWallet) public onlyOwner()
    
    Admins
    issueTokens(address to, uint256 value, bytes32 secretHash) public onlyAdmins()    
    executeAcceptTokens(address recipient, uint256 value, bytes calldata c_secret, uint8 v, bytes32 r, bytes32 s) public onlyAdmins()
    executePayment(address from, uint256 value, uint8 v, bytes32 r, bytes32 s) public onlyAdmins()
    transferTokens(uint256 value) public onlyAdmins()
    transferEther(uint256 value) public onlyAdmins()
    
    External
    acceptTokens(uint256 value) public
    depositTokens(uint256 value) public
    requestWithdrawal(uint256 value) public
    cancelWithdrawal() public
    withdrawTokens() public
    account(address addr) public view
    availableSupply() view public returns (uint256)
    
    Public
    totalSupply() view public returns (uint256)
    generateAcceptTokensMessage(address recipient, uint256 value, bytes32 secretHash) public view
    validateAcceptTokens(address recipient, uint256 value, bytes32 secretHash, uint8 v, bytes32 r, bytes32 s) public view 
    generatePaymentMessage(address from, uint256 value) public view
    validatePayment(address from, uint256 value, uint8 v, bytes32 r, bytes32 s) public view
    
    Private
    _acceptTokens(address recipient, uint256 value) internal
    _messageToRecover(bytes32 hashedUnsignedMessage) private pure
    _hashToAscii(bytes32 hash) private pure returns (bytes memory)
    _char(byte b) private pure returns (byte c)
    
*/

contract Pool is Claimable {
    using AccountUtils for Account;

    uint8 public constant VERSION = 0x1;
    uint256 public constant MAX_RELEASE_DELAY = 11_520; // about 48h
    
    uint256 s_uid;
    uint256 s_totalSupply;
    uint256 s_minSupply;
    uint256 s_pendingSupply;
    uint256 s_releaseDelay;
    uint256 s_maxTokensPerIssue;
    address s_manager;
    address s_tokenContract;
    address s_tokenWallet;
    address payable s_etherWallet;

    mapping(address => Account) s_accounts;

    event TokensIssued(address indexed account, uint256 value, bytes32 secretHash);
    event TokensAccepted(address indexed account, bool directCall);
    event Payment(address indexed account, uint256 value);
    event Deposit(address indexed account, uint256 value);
    event WithdrawalRequested(address indexed account, uint256 value);
    event WithdrawalCanceled(address indexed account);
    event Withdrawal(address indexed account, uint256 value);
    event EtherTransfered(address indexed to, uint256 value);
    event TokensTransfered(address indexed to, uint256 value);

    modifier onlyAdmins() {
        require(msg.sender == owner || msg.sender == s_manager, "not owner or manager");
        _;
    }

    constructor(address tokenContract) public {
        s_tokenContract = tokenContract;
        s_releaseDelay = 240;
        s_maxTokensPerIssue = 10000;
        s_uid = (
          uint256(VERSION) << 248 |
          uint256(blockhash(block.number-1)) << 192 >> 16 |
          uint256(address(this))
        );
        s_totalSupply = ERC20(tokenContract).balanceOf(address(this));
    }

    // ----------- Owner Functions ------------

    function setManager(address manager) external onlyOwner() {
        s_manager = manager; 
    }

    function setReleaseDelay(uint256 blocks) external onlyOwner() {
        require(blocks <= MAX_RELEASE_DELAY, "exeeds max release delay");
        s_releaseDelay = blocks;
    }

    function setMaxTokensPerIssue(uint256 tokens) external onlyOwner() {
        s_maxTokensPerIssue = tokens;
    }

    function resyncTotalSupply() external onlyAdmins() returns (uint256) {
        s_totalSupply = ERC20(s_tokenContract).balanceOf(address(this));
    }

    function setTokenWallet(address tokenWallet) external onlyOwner() {
        s_tokenWallet = tokenWallet;
    }

    function setEtherWallet(address payable etherWallet) external onlyOwner() {
        s_etherWallet = etherWallet;
    }

    // ----------- Admins Functions ------------

    function transferEther(uint256 value) external onlyAdmins() {
        require(s_etherWallet != address(0), "ether wallet not set");
        s_etherWallet.transfer(value);
        emit EtherTransfered(s_etherWallet, value);
    }

    function transferTokens(uint256 value) external onlyAdmins() {
        require(s_tokenWallet != address(0), "token wallet not set");
        require(value <= availableSupply(), "value larget than available tokens");
        s_totalSupply -= value;
        ERC20(s_tokenContract).transfer(s_tokenWallet, value);
        emit TokensTransfered(s_tokenWallet, value);
    }

    /**
     * @dev Issueing tokens for an address to be used for payments.
     * The owner of the receiving address must accept via a signed message or a direct call.
     * @param to The tokens recipient. 
     * @param value The number of tokens to issue.
     * @param secretHash The keccak256 of the confirmation secret.
    */
    function issueTokens(address to, uint256 value, bytes32 secretHash) external onlyAdmins() {
        require(value <= availableSupply(), "not enough available tokens");
        require(value <= s_maxTokensPerIssue, "amount exeed max tokens per call");
        Account storage sp_account = s_accounts[to];
        uint256 currentAmount = sp_account.pending;
        sp_account.secretHash = secretHash;
        if (currentAmount > value) {
            sp_account.pending = value;
            s_pendingSupply += currentAmount - value;
        } else if (currentAmount < value) {
            sp_account.pending = value;
            s_pendingSupply += value - currentAmount;
        }
        sp_account.initNonce();
        emit TokensIssued(to, value, secretHash);
    }

    function executePayment(address from, uint256 value, uint8 v, bytes32 r, bytes32 s)
        external
        onlyAdmins()
    {
        require(validatePayment(from, value, v, r, s), "wrong signature or data");
        Account storage sp_account = s_accounts[from];
        sp_account.updateNonce();
        sp_account.balance -= value;
        s_minSupply -= value;
        s_totalSupply -= value;
        emit Payment(from, value);
    }

    function executeAcceptTokens(
        address recipient,
        uint256 value,
        bytes calldata c_secret,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external 
        onlyAdmins()
    {
        require(s_accounts[recipient].secretHash == keccak256(c_secret), "wrong secret");
        require(
            validateAcceptTokens(recipient, value, keccak256(c_secret), v, r ,s),
            "wrong signature or data"
        );
        _acceptTokens(recipient, value);
        emit TokensAccepted(recipient, false);
    }
  
    // ----------- External Functions ------------

    function acceptTokens(uint256 value) external {
        _acceptTokens(msg.sender, value);
        emit TokensAccepted(msg.sender, true);
    }

    function depositTokens(uint256 value) external {
        require(
            ERC20(s_tokenContract).allowance(msg.sender, address(this)) >= value,
            "ERC20 allowance too low"
        );
        Account storage sp_account = s_accounts[msg.sender]; 
        sp_account.balance += value;
        sp_account.initNonce();
        s_minSupply += value;
        s_totalSupply += value;
        ERC20(s_tokenContract).transferFrom(msg.sender, address(this), value);
        emit Deposit(msg.sender, value);
    }

    function requestWithdrawal(uint256 value) external {
        require(s_accounts[msg.sender].balance >= value, "not enough tokens");
        require(value > 0, "cannot withdraw");
        s_accounts[msg.sender].withdrawal = value;
        s_accounts[msg.sender].release = block.number + 240;
        emit WithdrawalRequested(msg.sender, value);
    }

    function cancelWithdrawal() external {
        s_accounts[msg.sender].withdrawal = 0;
        s_accounts[msg.sender].release = 0;
        emit WithdrawalCanceled(msg.sender);
    }

    function withdrawTokens() external {
        Account storage sp_account = s_accounts[msg.sender];   
        require(sp_account.release > 0, "no withdraw request");
        require(sp_account.release < block.number, "too soon");
        uint256 value = sp_account.withdrawal;
        sp_account.withdrawal = 0;
        sp_account.release = 0;
        sp_account.balance -= value;
        s_minSupply -= value;
        s_totalSupply -= value;
        ERC20(s_tokenContract).transfer(msg.sender, value);
        emit Withdrawal(msg.sender, value);
    }

    function account(address addr) external view
        returns (
            uint256 nonce,  
            uint256 balance,
            uint256 pending,
            uint256 withdrawal,
            uint256 release,
            bytes32 secretHash
        ) 
    {
        Account storage sp_account = s_accounts[addr];
        return (
            sp_account.nonce,
            sp_account.balance,
            sp_account.pending,
            sp_account.withdrawal,
            sp_account.release,
            sp_account.secretHash
        );
    }


    function totalSupply() view external returns (uint256) {
        return s_totalSupply;
    }

    // ----------- Public Functions ------------

    function availableSupply() view public returns (uint256) {
        require(s_totalSupply >= s_minSupply + s_pendingSupply, 'internal error');
        return s_totalSupply - s_minSupply - s_pendingSupply;
    }

    function generatePaymentMessage(address from, uint256 value)
        public view
        returns (bytes memory)
    {
        Account storage sp_account = s_accounts[from]; 
        require(sp_account.balance >= value, "account balnace too low");
        return abi.encodePacked(
            s_uid,
            this.generatePaymentMessage.selector,
            from,
            value,
            sp_account.nonce
        );
    }

    function validatePayment(address from, uint256 value, uint8 v, bytes32 r, bytes32 s)
        public view 
        returns (bool)
    {
        bytes32 message  = _messageToRecover(
            keccak256(generatePaymentMessage(from, value))
        );
        address addr = ecrecover(message, v, r, s);
        return addr == from;      
    }

    function generateAcceptTokensMessage(address recipient, uint256 value, bytes32 secretHash)
        public view 
        returns (bytes memory)
    {
        require(s_accounts[recipient].secretHash == secretHash, "wrong secret hash");
        require(s_accounts[recipient].pending == value, "value must equal pending(issued tokens)");
        return abi.encodePacked(
            s_uid,
            this.generateAcceptTokensMessage.selector,
            recipient,
            value,
            secretHash
        );
    }

    function validateAcceptTokens(
        address recipient,
        uint256 value,
        bytes32 secretHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        public view 
        returns (bool)
    {
        bytes32 message = _messageToRecover(
            keccak256(generateAcceptTokensMessage(recipient, value, secretHash))
        );
        address addr = ecrecover(message, v, r, s);
        return addr == recipient;
    }

    // ----------- Private Functions ------------

    function _acceptTokens(address recipient, uint256 value) private {
        Account storage sp_account = s_accounts[recipient];
        uint256 pending = sp_account.pending;
        require(pending > 0, "no pending tokens");
        require(pending == value, "value must equal issued tokens");
        sp_account.secretHash = 0;
        sp_account.pending = 0;
        sp_account.balance += pending;
        s_pendingSupply -= pending;
    }

    function _messageToRecover(bytes32 hashedUnsignedMessage)
        private pure 
        returns (bytes32)
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
