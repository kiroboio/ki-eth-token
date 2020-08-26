// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./Claimable.sol";

struct Account {
    uint256 nonce;  
    uint256 balance;
    uint256 issueBlock;
    uint256 pending;
    uint256 withdrawal;
    uint256 releaseBlock;
    bytes32 secretHash;
}

library AccountUtils {
    using SafeMath for uint256;

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
    
    function acceptPending(Account storage self, uint256 value) internal {
        uint256 pending = self.pending;
        require(pending > 0, "no pending tokens");
        require(pending == value, "value must equal issued tokens");
        self.secretHash = 0;
        self.pending = 0;
        self.balance = self.balance.add(pending);
    }

    function take(Account storage self, uint256 value) internal {
        self.balance = self.balance.add(value);
    }

    function payment(Account storage self, uint256 value) internal {
        self.balance = self.balance.sub(value);
    }

    function deposit(Account storage self, uint256 value) internal {
        self.balance = self.balance.add(value);
    }

    function withdraw(Account storage self, uint256 value) internal {
        self.withdrawal = 0;
        self.releaseBlock = 0;
        self.balance = self.balance.sub(value);
    }
}

struct Supply {
    uint256 total;
    uint256 minimum;
    uint256 pending;
}

library SupplyUtils {
    using SafeMath for uint256;

    // event MinimumReached(uint256 before, uint256 delta);

    modifier checkAvailability(Supply storage self) {
        _;
        require(self.total >= self.minimum.add(self.pending), "not enough available tokens");
    }

    // modifier safeReduceMinimum(Supply storage self, uint256 value) {
    //     self.minimum > value ? self.minimum -= value : self.minimum = 0; 
    //     if (self.minimum == 0) {
    //       emit MinimumReached(self.minimum, value);
    //     }
    //     _;
    // }

    function updatePending(Supply storage self, uint256 from, uint256 to) internal checkAvailability(self) { 
        self.pending = self.pending.add(to).sub(from, "not enough available tokens");       
    }

    function acceptPending(Supply storage self, uint256 value) internal {
        self.pending = self.pending.sub(value, "not enough pending");
        self.minimum = self.minimum.add(value);
    }

    function give(Supply storage self, uint256 value) internal checkAvailability(self) {
        self.minimum = self.minimum.add(value);
    }

    function payment(Supply storage self, uint256 value) internal /*safeReduceMinimum(self, value)*/ {
        self.minimum = self.minimum.sub(value); // this line should be remove if using safeReduceMinimum modifier
    }

    function deposit(Supply storage self, uint256 value) internal {
        self.minimum = self.minimum.add(value);
        self.total = self.total.add(value);
    }

    function widthdraw(Supply storage self, uint256 value) internal /*safeReduceMinimum(self, value)*/ checkAvailability(self) {
        self.minimum = self.minimum.sub(value); // this line should be remove if using safeReduceMinimum modifier
        self.total = self.total.sub(value);
    }

    function decrease(Supply storage self, uint256 value) internal checkAvailability(self) {
        self.total = self.total.sub(value, "value larger than total");
    }

    function update(Supply storage self, uint256 value) internal checkAvailability(self) {
        self.total = value;
    }

    function available(Supply storage self) internal view returns (uint256) {
        return self.total.sub(self.minimum.add(self.pending));
    }
}

struct Limits {
    uint256 releaseDelay;
    uint256 maxTokensPerIssue;
    uint256 maxTokensPerBlock;
}

struct Entities {
    address manager;
    address token;
    address wallet;
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
    
    External
    acceptTokens(uint256 value) public
    depositTokens(uint256 value) public
    requestWithdrawal(uint256 value) public
    cancelWithdrawal() public
    withdrawTokens() public
    account(address addr) public view
    supply() view external returns (uint256 total, uint256 minimum, uint256 pending) {
    limits()
    entities()
    availableSupply() view public returns (uint256)
    totalSupply() view public returns (uint256)
    
    Public
    generateAcceptTokensMessage(address recipient, uint256 value, bytes32 secretHash) public view
    generatePaymentMessage(address from, uint256 value) public view
    validateAcceptTokens(address recipient, uint256 value, bytes32 secretHash, uint8 v, bytes32 r, bytes32 s) public view 
    validatePayment(address from, uint256 value, uint8 v, bytes32 r, bytes32 s) public view
    
    Private
    _acceptTokens(address recipient, uint256 value) internal
    _messageToRecover(bytes32 hashedUnsignedMessage) private pure
    _hashToAscii(bytes32 hash) private pure returns (bytes memory)
    _char(byte b) private pure returns (byte c)
    
*/

contract Pool is Claimable {
    using AccountUtils for Account;
    using SupplyUtils for Supply;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 private s_uid;
    Supply private s_supply;
    Limits private s_limits;
    Entities private s_entities;
    uint256 private s_lastIssuedBlock;
    uint256 private s_totalIssuedInBlock;

    mapping(address => Account) private s_accounts;

    uint8 public constant VERSION = 0x1;
    uint256 public constant MAX_RELEASE_DELAY = 11_520; // about 48h
    
    event TokensIssued(address indexed account, uint256 value, bytes32 secretHash);
    event TokensAccepted(address indexed account, bool directCall);
    event TokensDistributed(address indexed account, uint256 value);
    event Payment(address indexed account, uint256 value);
    event Deposit(address indexed account, uint256 value);
    event WithdrawalRequested(address indexed account, uint256 value);
    event WithdrawalCanceled(address indexed account);
    event Withdrawal(address indexed account, uint256 value);
    event EtherTransfered(address indexed to, uint256 value);
    event TokensTransfered(address indexed to, uint256 value);
    event ManagerChanged(address from, address to);
    event WalletChanged(address from, address to);
    event ReleaseDelayChanged(uint256 from, uint256 to);
    event MaxTokensPerIssueChanged(uint256 from, uint256 to);
    event MaxTokensPerBlockChanged(uint256 from, uint256 to);

    modifier onlyAdmins() {
        require(msg.sender == s_owner || msg.sender == s_entities.manager, "not owner or manager");
        _;
    }

    constructor(address tokenContract) public {
        s_entities.token = tokenContract;
        s_limits = Limits({releaseDelay: 240, maxTokensPerIssue: 10*1000*(10**18), maxTokensPerBlock: 50*1000*(10**18)});
        s_uid = (
          uint256(VERSION) << 248 |
          uint256(blockhash(block.number-1)) << 192 >> 16 |
          uint256(address(this))
        );
    }

    receive () external payable {
        require(false, "not accepting ether");
    }


    // ----------- Owner Functions ------------


    function setManager(address manager) external onlyOwner() {
        require(manager != address(this), "pool cannot be mananger");
        require(manager != s_entities.token, "token cannot be manager");
        emit ManagerChanged(s_entities.manager, manager);
        s_entities.manager = manager;
    }

    function setWallet(address wallet) external onlyOwner() {
        require(wallet != address(this), "pool cannot be wallet");
        require(wallet != s_entities.token, "token cannot be wallt");
        emit WalletChanged(s_entities.wallet, wallet);
        s_entities.wallet = wallet;
    }

    function setReleaseDelay(uint256 blocks) external onlyOwner() {
        require(blocks <= MAX_RELEASE_DELAY, "exeeds max release delay");
        emit ReleaseDelayChanged(s_limits.releaseDelay, blocks);
        s_limits.releaseDelay = blocks;
    }

    function setMaxTokensPerIssue(uint256 tokens) external onlyOwner() {
        emit MaxTokensPerIssueChanged(s_limits.maxTokensPerIssue, tokens);
        s_limits.maxTokensPerIssue = tokens;
    }

    function setMaxTokensPerBlock(uint256 tokens) external onlyOwner() {
        emit MaxTokensPerBlockChanged(s_limits.maxTokensPerBlock, tokens);
        s_limits.maxTokensPerBlock = tokens;
    }

    function resyncTotalSupply(uint256 value) external onlyAdmins() returns (uint256) {
        uint256 tokens = ownedTokens();
        require(tokens >= s_supply.total, "internal error, check contract logic"); 
        require(value >= s_supply.total, "only transferTokens can decrease total supply");
        require(value <= tokens, "not enough tokens");
        s_supply.update(value);
    }


    // ----------- Admins Functions ------------


    function transferTokens(uint256 value) external onlyAdmins() {
        require(s_entities.wallet != address(0), "token wallet not set");
        s_supply.decrease(value);
        IERC20(s_entities.token).safeTransfer(s_entities.wallet, value);
        emit TokensTransfered(s_entities.wallet, value);
    }

    function distributeTokens(address to, uint256 value) external onlyAdmins() {
        require(value <= s_limits.maxTokensPerIssue, "exeeds max tokens per call");
        require(s_accounts[to].issueBlock < block.number, "too soon");
        _validateTokensPerBlock(value);
        Account storage sp_account = s_accounts[to];
        sp_account.issueBlock = block.number;
        sp_account.initNonce();
        s_supply.give(value);
        sp_account.take(value);
        emit TokensDistributed(to, value);
    }

    /**
     * @dev Issueing tokens for an address to be used for payments.
     * The owner of the receiving address must accept via a signed message or a direct call.
     * @param to The tokens recipient. 
     * @param value The number of tokens to issue.
     * @param secretHash The keccak256 of the confirmation secret.
    */
    function issueTokens(address to, uint256 value, bytes32 secretHash) external onlyAdmins() {
        require(value <= s_limits.maxTokensPerIssue, "exeeds max tokens per call");
        _validateTokensPerBlock(value);
        Account storage sp_account = s_accounts[to];
        uint256 prevPending = sp_account.pending;
        sp_account.initNonce();
        sp_account.secretHash = secretHash;
        sp_account.pending = value;
        sp_account.issueBlock = block.number;
        s_supply.updatePending(prevPending, value);
        emit TokensIssued(to, value, secretHash);
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

    function executePayment(address from, uint256 value, uint8 v, bytes32 r, bytes32 s)
        external
        onlyAdmins()
    {
        require(validatePayment(from, value, v, r, s), "wrong signature or data");
        Account storage sp_account = s_accounts[from];
        sp_account.updateNonce();
        sp_account.payment(value);
        s_supply.payment(value);
        emit Payment(from, value);
    }
  

    // ----------- External Functions ------------


    function acceptTokens(uint256 value, bytes calldata c_secret) external {
        require(s_accounts[msg.sender].secretHash == keccak256(c_secret), "wrong secret");
        _acceptTokens(msg.sender, value);
        emit TokensAccepted(msg.sender, true);
    }

    function depositTokens(uint256 value) external {
        // require(
        //     IERC20(s_entities.token).allowance(msg.sender, address(this)) >= value,
        //    "IERC20 allowance too low"
        // );
        Account storage sp_account = s_accounts[msg.sender]; 
        sp_account.initNonce();
        sp_account.deposit(value);
        s_supply.deposit(value);
        IERC20(s_entities.token).safeTransferFrom(msg.sender, address(this), value);
        emit Deposit(msg.sender, value);
    }

    function requestWithdrawal(uint256 value) external {
        require(s_accounts[msg.sender].balance >= value, "not enough tokens");
        require(value > 0, "withdrawal value must be larger then 0");
        s_accounts[msg.sender].withdrawal = value;
        s_accounts[msg.sender].releaseBlock = block.number + s_limits.releaseDelay;
        emit WithdrawalRequested(msg.sender, value);
    }

    function cancelWithdrawal() external {
        s_accounts[msg.sender].withdrawal = 0;
        s_accounts[msg.sender].releaseBlock = 0;
        emit WithdrawalCanceled(msg.sender);
    }

    function withdrawTokens() external {
        Account storage sp_account = s_accounts[msg.sender];   
        require(sp_account.withdrawal > 0, "no withdraw request");
        require(sp_account.releaseBlock <= block.number, "too soon");
        uint256 value = sp_account.withdrawal > sp_account.balance ? sp_account.balance : sp_account.withdrawal;
        sp_account.withdraw(value);
        s_supply.widthdraw(value);
        IERC20(s_entities.token).safeTransfer(msg.sender, value);
        emit Withdrawal(msg.sender, value);
    }

    function account(address addr) external view
        returns (
            uint256 nonce,  
            uint256 balance,
            uint256 issueBlock,
            uint256 pending,
            uint256 withdrawal,
            uint256 releaseBlock,
            bytes32 secretHash,
            uint256 externalBalance
        ) 
    {
        Account storage sp_account = s_accounts[addr];
        uint256 extBalance = IERC20(s_entities.token).balanceOf(addr);
        return (
            sp_account.nonce,
            sp_account.balance,
            sp_account.issueBlock,
            sp_account.pending,
            sp_account.withdrawal,
            sp_account.releaseBlock,
            sp_account.secretHash,
            extBalance
        );
    }

    function entities() view external
        returns (
            address manager,
            address token,
            address wallet
        )
    {
        return (
            s_entities.manager,
            s_entities.token,
            s_entities.wallet
        );
    }

    function limits() external view
        returns (
            uint256 releaseDelay, 
            uint256 maxTokensPerIssue,
            uint256 maxTokensPerBlock
        )
    {
        return (
            s_limits.releaseDelay,
            s_limits.maxTokensPerIssue,
            s_limits.maxTokensPerBlock
        );
    }

    function supply() view external 
        returns (
            uint256 total,
            uint256 minimum,
            uint256 pending,
            uint256 available
        ) 
    {
        return (
            s_supply.total,
            s_supply.minimum,
            s_supply.pending,
            s_supply.available()
        );
    }

    function uid() view external returns (uint256) {
        return s_uid;
    }

    function totalSupply() view external returns (uint256) {
        return s_supply.total;
    }

    function availableSupply() view external returns (uint256) {
        return s_supply.available();
    }


    // ----------- Public Functions ------------


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

    function validatePayment(address from, uint256 value, uint8 v, bytes32 r, bytes32 s)
        public view 
        returns (bool)
    {
        bytes32 message = _messageToRecover(
            keccak256(generatePaymentMessage(from, value))
        );
        address addr = ecrecover(message, v, r, s);
        return addr == from;      
    }

    function ownedTokens() view public returns (uint256) {
        return IERC20(s_entities.token).balanceOf(address(this));
    }


    // ----------- Private Functions ------------


    function _validateTokensPerBlock(uint256 value) private {
        if (s_lastIssuedBlock < block.number) {
            s_lastIssuedBlock = block.number;
            s_totalIssuedInBlock = value;
        } else {
            s_totalIssuedInBlock.add(value);
        }
        require(s_totalIssuedInBlock <= s_limits.maxTokensPerBlock, "exeeds max tokens per block");
    }

    function _acceptTokens(address recipient, uint256 value) private {
        require(s_accounts[recipient].issueBlock < block.number, "too soon");
        s_accounts[recipient].acceptPending(value);
        s_supply.acceptPending(value);
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
