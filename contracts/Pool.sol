// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20.sol";
import "./Claimable.sol";

contract Pool is Claimable {

    uint256 constant MAX_RELEASE_DELAY = 11_520; // about 48h
    
    address s_tokenContract;
    uint256 s_minSupply;
    uint256 s_pendingSupply;
    address s_manager;
    address payable s_etherWallet;
    address s_tokenWallet;
    uint256 s_releaseDelay;
    uint256 s_maxTokensPerIssueCall;

    struct Account {
        uint256 nonce;  
        uint256 balance;
        uint256 pending;
        uint256 withdraw;
        uint256 release;
        bytes32 secret;
    }

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
        s_maxTokensPerIssueCall = 10000;
    }

    function setReleaseDelay(uint256 blocks) public onlyOwner() {
        require(blocks <= MAX_RELEASE_DELAY, "exeeds max release delay");
        s_releaseDelay = blocks;
    }

    function setMaxTokensPerIssueCall(uint256 tokens) public onlyOwner() {
        s_maxTokensPerIssueCall = tokens;
    }

    /**
     * @dev Issueing tokens for an address to be used for payments.
     * The owner of the receiving address must accept via a signed message or a direct call.
     * @param to The tokens recipeint. 
     * @param value The number of tokens to issue.
     * @param secretHash The keccak256 of the confirmation secret.
    */
    function issueTokens(address to, uint256 value, bytes32 secretHash) public onlyAdmins() {
        require(value <= availableSupply(), "not enough available tokens");
        require(value <= s_maxTokensPerIssueCall, "amount exeed max tokens per call");
        Account storage sp_account = s_accounts[to];
        uint256 currentAmount = sp_account.pending;
        sp_account.secret = secretHash;
        if (currentAmount > value) {
            sp_account.pending = value;
            s_pendingSupply += currentAmount - value;
        } else if (currentAmount < value) {
            sp_account.pending = value;
            s_pendingSupply += value - currentAmount;
        }
        emit TokensIssued(to, value, secretHash);
    }


    function issuedPendingTokens(address account) public view returns (uint256) {
        return s_accounts[account].pending;
    }

    function _acceptTokens(address recipeint, uint256 value) internal {
        Account storage sp_account = s_accounts[recipeint];
        uint256 pending = sp_account.pending;
        require(pending > 0, "no pending tokens");
        require(pending == value, "value must equal issued tokens");
        sp_account.pending = 0;
        sp_account.balance += pending;
        sp_account.secret = 0;
        s_pendingSupply -= pending;
    }

    function acceptTokens(uint256 value) public {
        _acceptTokens(msg.sender, value);
        emit TokensAccepted(msg.sender, true);
    }

    function setEtherWallet(address payable etherWallet) public onlyOwner() {
        s_etherWallet = etherWallet;
    }

    function setTokenWallet(address tokenWallet) public onlyOwner() {
        s_tokenWallet = tokenWallet;
    }

    function transferEther(uint256 value) public onlyAdmins() {
        require(s_etherWallet != address(0), "ether wallet not set");
        s_etherWallet.transfer(value);
        emit EtherTransfered(s_etherWallet, value);
    }

    function transferTokens(uint256 value) public onlyAdmins() {
        require(s_tokenWallet != address(0), "token wallet not set");
        require(value <= availableSupply(), "value larget than available tokens");
        ERC20(s_tokenContract).transfer(s_tokenWallet, value);
        emit TokensTransfered(s_tokenWallet, value);
    }

    function accountNonce(address account) public view returns (uint256) {
        return s_accounts[account].nonce; 
    }

    function accountBalance(address account) public view returns (uint256) {
        return s_accounts[account].balance; 
    }

    function generatePaymentMessage(address from, uint256 value)
        public view
        returns (bytes memory)
    {
        Account storage sp_account = s_accounts[from]; 
        require(sp_account.balance >= value, "account balnace too low");
        return abi.encodePacked(
            address(this),
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

    function executePayment(address from, uint256 value, uint8 v, bytes32 r, bytes32 s)
        public
        onlyAdmins()
    {
        require(validatePayment(from, value, v, r, s), "wrong signature or data");
        Account storage sp_account = s_accounts[from];
        require(sp_account.nonce != block.timestamp, "too soon");
        sp_account.nonce = block.timestamp;
        sp_account.balance -= value;
        s_minSupply -= value;
        emit Payment(from, value);
    }

    function generateAcceptTokensMessage(address recipeint, uint256 value, bytes32 secretHash)
        public view 
        returns (bytes memory)
    {
        require(s_accounts[recipeint].secret == secretHash, "wrong secret hash");
        require(s_accounts[recipeint].pending == value, "value must equal pending(issued tokens)");
        return abi.encodePacked(
            address(this),
            this.generateAcceptTokensMessage.selector,
            recipeint,
            value,
            secretHash
        );
    }

    function validateAcceptTokens(
        address recipeint,
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
            keccak256(generateAcceptTokensMessage(recipeint, value, secretHash))
        );
        address addr = ecrecover(message, v, r, s);
        return addr == recipeint;
    }

    function executeAcceptTokens(
        address recipeint,
        uint256 value,
        bytes calldata c_secret,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        public 
        onlyAdmins()
    {
        require(s_accounts[recipeint].secret == keccak256(c_secret), "wrong secret");
        require(
            validateAcceptTokens(recipeint, value, keccak256(c_secret), v, r ,s),
            "wrong signature or data"
        );
        _acceptTokens(recipeint, value);
        emit TokensAccepted(recipeint, false);
    }

    function setManager(address manager) public onlyOwner() {
        s_manager = manager; 
    }
  
    function totalSupply() view public returns (uint256) {
        return ERC20(s_tokenContract).balanceOf(address(this));
    }

    function availableSupply() view public returns (uint256) {
        return ERC20(s_tokenContract).balanceOf(address(this)) - s_minSupply - s_pendingSupply;
    }

    function deposit(uint256 value) public {
        require(
            ERC20(s_tokenContract).allowance(msg.sender, address(this)) >= value,
            "ERC20 allowance too low"
        );
        ERC20(s_tokenContract).transferFrom(msg.sender, address(this), value);
        s_accounts[msg.sender].balance += value;
        s_minSupply += value;
        emit Deposit(msg.sender, value);
    }

    function requestWithdrawal(uint256 value) public {
        require(s_accounts[msg.sender].balance >= value, "not enough tokens");
        require(value > 0, "cannot withdraw");
        s_accounts[msg.sender].withdraw = value;
        s_accounts[msg.sender].release = block.number + 240;
        emit WithdrawalRequested(msg.sender, value);
    }

    function cancelWithdrawal() public {
        s_accounts[msg.sender].withdraw = 0;
        s_accounts[msg.sender].release = 0;
        emit WithdrawalCanceled(msg.sender);
    }

    function withdraw() public {
        Account storage sp_account = s_accounts[msg.sender];   
        require(sp_account.release > 0, "no withdraw request");
        require(sp_account.release < block.number, "too soon");
        uint256 value = sp_account.withdraw;
        sp_account.withdraw = 0;
        sp_account.release = 0;
        sp_account.balance -= value;
        s_minSupply -= value;
        ERC20(s_tokenContract).transfer(msg.sender, value);
        emit Withdrawal(msg.sender, value);
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