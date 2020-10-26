// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SafeTransfer is AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // keccak256("ACTIVATOR_ROLE");
    bytes32 public constant ACTIVATOR_ROLE = 0xec5aad7bdface20c35bc02d6d2d5760df981277427368525d634f4e2603ea192;

    uint256 s_fees;
    mapping(bytes32 => uint256) s_transfers;
    mapping(bytes32 => uint256) s_erc20Transfers;
    mapping(bytes32 => uint256) s_erc721Transfers;

    event Deposited(
        address indexed from,
        address indexed to,
        uint256 value,
        uint256 fees,
        bytes32 secretHash
    );
    
    event TimedDeposited(
        address indexed from,
        address indexed to,
        uint256 value,
        uint256 fees,
        bytes32 secretHash,
        uint64 expiresAt,
        uint128 depositFees
    );
    
    event Retrieved(
        address indexed from,
        address indexed to,
        bytes32 indexed id,
        uint256 value
    );    
    
    event Collected(
        address indexed from,
        address indexed to,
        bytes32 indexed id,
        uint256 value
    );

    event ERC20Deposited(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 value,
        uint256 fees,
        bytes32 secretHash
    );

    event ERC20TimedDeposited(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 value,
        uint256 fees,
        bytes32 secretHash,
        uint64 expiresAt,
        uint128 depositFees
    );

    event ERC20Retrieved(
        address indexed token,
        address indexed from,
        address indexed to,
        bytes32 id,
        uint256 value
    );    
    
    event ERC20Collected(
        address indexed token,
        address indexed from,
        address indexed to,
        bytes32 id,
        uint256 value
    );

    event ERC721Deposited(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 tokenId,
        uint256 fees,
        bytes32 secretHash
    );

    event ERC721TimedDeposited(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 tokenId,
        uint256 fees,
        bytes32 secretHash,
        uint64 expiresAt,
        uint128 depositFees
    );

    event ERC721Retrieved(
        address indexed token,
        address indexed from,
        address indexed to,
        bytes32 id,
        uint256 tokenId
    );    
    
    event ERC721Collected(
        address indexed token,
        address indexed from,
        address indexed to,
        bytes32 id,
        uint256 tokenId
    );

    modifier onlyActivator() {
        require(hasRole(ACTIVATOR_ROLE, msg.sender), "SafeTransfer: not an activator");    
        _;
    }

    constructor (address activator) public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ACTIVATOR_ROLE, msg.sender);
        _setupRole(ACTIVATOR_ROLE, activator);
        s_fees = 1; // TODO: remove
    }

    receive () external payable {
        require(false, "SafeTransfer: not accepting ether directly");
    }

    function transferERC20(address token, address wallet, uint256 value) external onlyActivator() {
        IERC20(token).safeTransfer(wallet, value);
    }

    function transferERC721(address token, address wallet, uint256 tokenId, bytes calldata data) external onlyActivator() {
        IERC721(token).safeTransferFrom(address(this), wallet, tokenId, data);
    }

    function transferFees(address payable wallet, uint256 value) external onlyActivator() {
        s_fees = s_fees.sub(value);
        wallet.transfer(value);
    }

    function totalFees() external view returns (uint256) {
        return s_fees;
    }

    // --------------------------------- ETH ---------------------------------

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
        emit TimedDeposited(msg.sender, to, value, fees, secretHash, expiresAt, depositFees);
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
        s_fees = s_fees.add(fees);
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

    // ------------------------------- ERC-20 --------------------------------

    function depositERC20(
        address token,
        string calldata tokenSymbol,
        address to,
        uint256 value,
        uint256 fees,
        bytes32 secretHash
    ) 
        payable external
    {
        require(msg.value == fees, "SafeTransfer: msg.value must match fees");
        require(value > 0, "SafeTransfer: no value");
        bytes32 id = keccak256(abi.encode(token, tokenSymbol, msg.sender, to, value, fees, secretHash));
        require(s_erc20Transfers[id] == 0, "SafeTransfer: request exist"); 
        s_erc20Transfers[id] = 0xffffffffffffffff; // expiresAt: max, depositFees: 0
        emit ERC20Deposited(token, msg.sender, to, value, fees, secretHash);
    }

    function timedDepositERC20(
        address token,
        string calldata tokenSymbol,
        address to,
        uint256 value,
        uint256 fees,
        bytes32 secretHash,
        uint64 expiresAt,
        uint128 depositFees
    ) 
        payable external
    {
        require(msg.value == fees, "SafeTransfer: msg.value must match fees");
        require(value > 0, "SafeTransfer: no value");
        bytes32 id = keccak256(abi.encode(token, tokenSymbol, msg.sender, to, value, fees, secretHash));
        require(s_erc20Transfers[id] == 0, "SafeTransfer: request exist"); 
        s_erc20Transfers[id] = uint256(expiresAt) + (uint256(depositFees) << 64);
        emit ERC20TimedDeposited(token, msg.sender, to, value, fees, secretHash, expiresAt, depositFees);
    }

    function retrieveERC20(
        address token,
        string calldata tokenSymbol,
        address to,
        uint256 value,
        uint256 fees,
        bytes32 secretHash
    )   
        external 
    {
        bytes32 id = keccak256(abi.encode(token, tokenSymbol, msg.sender, to, value, fees, secretHash));
        require(s_erc20Transfers[id]  > 0, "SafeTransfer: request not exist");
        delete s_erc20Transfers[id];
        msg.sender.transfer(fees);
        emit ERC20Retrieved(token, msg.sender, to, id, value);
    }

    function collectERC20(
        address token,
        string calldata tokenSymbol,
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
        bytes32 id = keccak256(abi.encode(token, tokenSymbol, from, to, value, fees, secretHash));
        uint256 tr = s_erc20Transfers[id];
        require(tr > 0, "SafeTransfer: request not exist");
        require(uint64(tr) > now, "SafeTranfer: expired");
        require(keccak256(secret) == secretHash, "SafeTransfer: wrong secret");
        delete s_erc20Transfers[id];
        s_fees = s_fees.add(fees);
        IERC20(token).safeTransferFrom(from, to, value);
        emit ERC20Collected(token, from, to, id, value);
    }

   function cancelERC20(
        address token,
        string calldata tokenSymbol,
        address payable from,
        address to,
        uint256 value,
        uint256 fees,
        bytes32 secretHash
    ) 
        external
        onlyActivator()
    {
        bytes32 id = keccak256(abi.encode(token, tokenSymbol, from, to, value, fees, secretHash));
        require(s_erc20Transfers[id] > 0, "SafeTransfer: request not exist");
        uint256 tr = s_erc20Transfers[id];
        require(uint64(tr) <= now, "SafeTranfer: not expired");
        delete  s_erc20Transfers[id];
        from.transfer(fees);
        emit ERC20Retrieved(token, from, to, id, value);
    }

    // ------------------------------- ERC-721 -------------------------------

    function depositERC721(
        address token,
        string calldata tokenSymbol,
        address to,
        uint256 tokenId,
        bytes calldata tokenData,
        uint256 fees,
        bytes32 secretHash
    ) 
        payable external
    {
        require(msg.value == fees, "SafeTransfer: msg.value must match fees");
        require(tokenId > 0, "SafeTransfer: no token id");
        bytes32 id = keccak256(abi.encode(token, tokenSymbol, msg.sender, to, tokenId, tokenData, fees, secretHash));
        require(s_erc721Transfers[id] == 0, "SafeTransfer: request exist"); 
        s_erc721Transfers[id] = 0xffffffffffffffff; // expiresAt: max, depositFees: 0
        emit ERC721Deposited(token, msg.sender, to, tokenId, fees, secretHash);
    }

    function timedDepositERC721(
        address token,
        string calldata tokenSymbol,
        address to,
        uint256 tokenId,
        bytes calldata tokenData,
        uint256 fees,
        bytes32 secretHash,
        uint64 expiresAt,
        uint128 depositFees
    ) 
        payable external
    {
        require(msg.value == fees, "SafeTransfer: msg.value must match fees");
        require(tokenId > 0, "SafeTransfer: no token id");
        bytes32 id = keccak256(abi.encode(token, tokenSymbol, msg.sender, to, tokenId, tokenData, fees, secretHash));
        require(s_erc721Transfers[id] == 0, "SafeTransfer: request exist"); 
        s_erc721Transfers[id] = uint256(expiresAt) + (uint256(depositFees) << 64);
        emit ERC721TimedDeposited(token, msg.sender, to, tokenId, fees, secretHash, expiresAt, depositFees);
    }

    function retrieveERC721(
        address token,
        string calldata tokenSymbol,
        address to,
        uint256 tokenId,
        bytes calldata tokenData,
        uint256 fees,
        bytes32 secretHash
    )   
        external 
    {
        bytes32 id = keccak256(abi.encode(token, tokenSymbol, msg.sender, to, tokenId, tokenData, fees, secretHash));
        require(s_erc721Transfers[id]  > 0, "SafeTransfer: request not exist");
        delete s_erc721Transfers[id];
        msg.sender.transfer(fees);
        emit ERC721Retrieved(token, msg.sender, to, id, tokenId);
    }

    function collectERC721(
        address token,
        string calldata tokenSymbol,
        address from,
        address payable to,
        uint256 tokenId,
        bytes calldata tokenData,
        uint256 fees,
        bytes32 secretHash,
        bytes calldata secret
    ) 
        external
        onlyActivator()
    {
        bytes32 id = keccak256(abi.encode(token, tokenSymbol, from, to, tokenId, tokenData, fees, secretHash));
        uint256 tr = s_erc721Transfers[id];
        require(tr > 0, "SafeTransfer: request not exist");
        require(uint64(tr) > now, "SafeTranfer: expired");
        require(keccak256(secret) == secretHash, "SafeTransfer: wrong secret");
        delete s_erc721Transfers[id];
        s_fees = s_fees.add(fees);
        IERC721(token).safeTransferFrom(from, to, tokenId, tokenData);
        emit ERC721Collected(token, from, to, id, tokenId);
    }

   function cancelERC721(
        address token,
        string calldata tokenSymbol,
        address payable from,
        address to,
        uint256 tokenId,
        bytes calldata tokenData,
        uint256 fees,
        bytes32 secretHash
    ) 
        external
        onlyActivator()
    {
        bytes32 id = keccak256(abi.encode(token, tokenSymbol, from, to, tokenId, tokenData, fees, secretHash));
        require(s_erc721Transfers[id] > 0, "SafeTransfer: request not exist");
        uint256 tr = s_erc721Transfers[id];
        require(uint64(tr) <= now, "SafeTranfer: not expired");
        delete  s_erc721Transfers[id];
        from.transfer(fees);
        emit ERC721Retrieved(token, from, to, id, tokenId);
    }


}
