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

    // keccak256("hiddenCollect(address from,address to,uint256 value,uint256 fees,bytes32 secretHash)");
    bytes32 public constant HIDDEN_COLLECT_TYPEHASH = 0x0506afef36f3613836f98ef019cb76a3e6112be8f9dc8d8fa77275d64f418234;

    // keccak256("hiddenCollectERC20(address from,address to,address token,string tokenSymbol,uint256 value,uint256 fees,bytes32 secretHash)");
    bytes32 public constant HIDDEN_ERC20_COLLECT_TYPEHASH = 0x9e6214229b9fba1927010d30b22a3a5d9fd5e856bb29f056416ff2ad52e8de44;

    // keccak256("hiddenCollectERC721(address from,address to,address token,string tokenSymbol,uint256 tokenId,bytes tokenData,uint256 fees,bytes32 secretHash)");
    bytes32 public constant HIDDEN_ERC721_COLLECT_TYPEHASH = 0xa14a2dc51c26e451800897aa798120e7d6c35039caf5eb29b8ac35d1e914c591;

    bytes32 public DOMAIN_SEPARATOR;
    uint256 public CHAIN_ID;
    bytes32 s_uid;
    uint256 s_fees;
    
    struct TokenInfo {
        bytes32 id;
        bytes32 id1;
    }

    mapping(bytes32 => uint256) s_transfers;
    mapping(bytes32 => uint256) s_erc20Transfers;
    mapping(bytes32 => uint256) s_erc721Transfers;
    mapping(bytes32 => uint256) s_htransfers;

    string public constant NAME = "Kirobo Safe Transfer";
    string public constant VERSION = "1";
    uint8 public constant VERSION_NUMBER = 0x1;

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
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
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
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
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
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
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

    event HDeposited(
        address indexed from,
        uint256 value,
        bytes32 indexed id1
    );

    event HTimedDeposited(
        address indexed from,
        uint256 value,
        bytes32 indexed id1,
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
    );

    event HRetrieved(
        address indexed from,
        bytes32 indexed id1,
        uint256 value
    );

    event HCollected(
        address indexed from,
        address indexed to,
        bytes32 indexed id1,
        uint256 value
    );

    event HERC20Collected(
        address indexed token,
        address indexed from,
        address indexed to,
        bytes32 id1,
        uint256 value
    );

    event HERC721Collected(
        address indexed token,
        address indexed from,
        address indexed to,
        bytes32 id1,
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

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        CHAIN_ID = chainId;

        s_uid = bytes32(
          uint256(VERSION_NUMBER) << 248 |
          uint256(blockhash(block.number-1)) << 192 >> 16 |
          uint256(address(this))
        );

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"),
                keccak256(bytes(NAME)),
                keccak256(bytes(VERSION)),
                chainId,
                address(this),
                s_uid
            )
        );

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

    function uid() view external returns (bytes32) {
        return s_uid;
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
        require(to != msg.sender, "SafeTransfer: sender==recipient");
        bytes32 id = keccak256(abi.encode(msg.sender, to, value, fees, secretHash));
        require(s_transfers[id] == 0, "SafeTransfer: request exist"); 
        s_transfers[id] = 0xffffffffffffffff; // expiresAt: max, AvailableAt: 0, autoRetrieveFees: 0
        emit Deposited(msg.sender, to, value, fees, secretHash);
    }

    function timedDeposit(
        address payable to,
        uint256 value,
        uint256 fees,
        bytes32 secretHash,
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
    ) 
        payable external
    {
        require(msg.value == value.add(fees), "SafeTransfer: value mismatch");
        require(fees >= autoRetrieveFees, "SafeTransfer: autoRetrieveFees exeed fees");
        require(value > 0, "SafeTransfer: no value");
        require(to != msg.sender, "SafeTransfer: sender==recipient");
        require(expiresAt > now, "SafeTransfer: already expired");
        bytes32 id = keccak256(abi.encode(msg.sender, to, value, fees, secretHash));
        require(s_transfers[id] == 0, "SafeTransfer: request exist"); 
        s_transfers[id] = uint256(expiresAt) + uint256(availableAt << 64) + (uint256(autoRetrieveFees) << 128);
        emit TimedDeposited(msg.sender, to, value, fees, secretHash, availableAt, expiresAt, autoRetrieveFees);
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
        require(uint64(tr>>64) <= now, "SafeTranfer: not available yet");
        require(keccak256(secret) == secretHash, "SafeTransfer: wrong secret");
        delete s_transfers[id];
        s_fees = s_fees.add(fees);
        to.transfer(value);
        emit Collected(from, to, id, value);
    }

   function autoRetrieve(
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
        s_fees = s_fees + (tr>>128); // autoRetreive fees
        uint256 valueToRetrieve = value.add(fees).sub(tr>>128);
        from.transfer(valueToRetrieve);
        emit Retrieved(from, to, id, valueToRetrieve);
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
        require(to != msg.sender, "SafeTransfer: sender==recipient");
        bytes32 id = keccak256(abi.encode(token, tokenSymbol, msg.sender, to, value, fees, secretHash));
        require(s_erc20Transfers[id] == 0, "SafeTransfer: request exist"); 
        s_erc20Transfers[id] = 0xffffffffffffffff;
        emit ERC20Deposited(token, msg.sender, to, value, fees, secretHash);
    }

    function timedDepositERC20(
        address token,
        string calldata tokenSymbol,
        address to,
        uint256 value,
        uint256 fees,
        bytes32 secretHash,
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
    ) 
        payable external
    {
        require(msg.value == fees, "SafeTransfer: msg.value must match fees");
        require(fees >= autoRetrieveFees, "SafeTransfer: autoRetrieveFees exeed fees");
        require(value > 0, "SafeTransfer: no value");
        require(to != msg.sender, "SafeTransfer: sender==recipient");
        require(expiresAt > now, "SafeTransfer: already expired");
        bytes32 id = keccak256(abi.encode(token, tokenSymbol, msg.sender, to, value, fees, secretHash));
        require(s_erc20Transfers[id] == 0, "SafeTransfer: request exist"); 
        s_erc20Transfers[id] = uint256(expiresAt) + (uint256(availableAt) << 64) + (uint256(autoRetrieveFees) << 128);
        emit ERC20TimedDeposited(token, msg.sender, to, value, fees, secretHash, availableAt, expiresAt, autoRetrieveFees);
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
        require(uint64(tr>>64) <= now, "SafeTranfer: not available yet");
        require(keccak256(secret) == secretHash, "SafeTransfer: wrong secret");
        delete s_erc20Transfers[id];
        s_fees = s_fees.add(fees);
        IERC20(token).safeTransferFrom(from, to, value);
        emit ERC20Collected(token, from, to, id, value);
    }

   function autoRetrieveERC20(
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
        s_fees = s_fees + (tr>>128); // autoRetreive fees
        from.transfer(fees.sub(tr>>128));
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
        require(to != msg.sender, "SafeTransfer: sender==recipient");
        bytes32 id = keccak256(abi.encode(token, tokenSymbol, msg.sender, to, tokenId, tokenData, fees, secretHash));
        require(s_erc721Transfers[id] == 0, "SafeTransfer: request exist"); 
        s_erc721Transfers[id] = 0xffffffffffffffff;
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
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
    ) 
        payable external
    {
        require(msg.value == fees, "SafeTransfer: msg.value must match fees");
        require(fees >= autoRetrieveFees, "SafeTransfer: autoRetrieveFees exeed fees");
        require(tokenId > 0, "SafeTransfer: no token id");
        require(to != msg.sender, "SafeTransfer: sender==recipient");
        require(expiresAt > now, "SafeTransfer: already expired");
        bytes32 id = keccak256(abi.encode(token, tokenSymbol, msg.sender, to, tokenId, tokenData, fees, secretHash));
        require(s_erc721Transfers[id] == 0, "SafeTransfer: request exist"); 
        s_erc721Transfers[id] = uint256(expiresAt) + (uint256(availableAt) << 64) + (uint256(autoRetrieveFees) << 128);
        emit ERC721TimedDeposited(token, msg.sender, to, tokenId, fees, secretHash, availableAt, expiresAt, autoRetrieveFees);
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
        require(uint64(tr>>64) <= now, "SafeTranfer: not available yet");
        require(keccak256(secret) == secretHash, "SafeTransfer: wrong secret");
        delete s_erc721Transfers[id];
        s_fees = s_fees.add(fees);
        IERC721(token).safeTransferFrom(from, to, tokenId, tokenData);
        emit ERC721Collected(token, from, to, id, tokenId);
    }

   function autoRetrieveERC721(
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
        s_fees = s_fees + (tr>>128); // autoRetreive fees
        from.transfer(fees.sub(tr>>128));
        emit ERC721Retrieved(token, from, to, id, tokenId);
    }

    // ----------------------- Hidden ETH / ERC-20 / ERC-721 -----------------------

    function hiddenDeposit(bytes32 id1) 
        payable external
    {
        require(msg.value > 0, "SafeTransfer: no value");
        bytes32 id = keccak256(abi.encode(msg.sender, msg.value, id1));
        require(s_htransfers[id] == 0, "SafeTransfer: request exist"); 
        s_htransfers[id] = 0xffffffffffffffff;
        emit HDeposited(msg.sender, msg.value, id1);
    }

    function hiddenTimedDeposit(
        bytes32 id1,
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
    ) 
        payable external
    {
        require(msg.value > 0, "SafeTransfer: no value");
        require(msg.value >= autoRetrieveFees, "SafeTransfers: autoRetrieveFees exeed value");
        bytes32 id = keccak256(abi.encode(msg.sender, msg.value, id1));
        require(s_htransfers[id] == 0, "SafeTransfer: request exist");
        require(expiresAt > now, "SafeTransfer: already expired"); 
        s_htransfers[id] = uint256(expiresAt) + (uint256(availableAt) << 64) + (uint256(autoRetrieveFees) << 128);
        emit HTimedDeposited(msg.sender, msg.value, id1, availableAt, expiresAt, autoRetrieveFees);
    }

    function hiddenRetrieve(
        bytes32 id1,
        uint256 value
    )   
        external 
    {
        bytes32 id = keccak256(abi.encode(msg.sender, value, id1));
        require(s_htransfers[id]  > 0, "SafeTransfer: request not exist");
        delete s_htransfers[id];
        msg.sender.transfer(value);
        emit HRetrieved(msg.sender, id1, value);
    }

    function hiddenCollect(
        address from,
        address payable to,
        uint256 value,
        uint256 fees,
        bytes32 secretHash,
        bytes calldata secret,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) 
        external
        onlyActivator()
    {
        bytes32 id1 = keccak256(abi.encode(HIDDEN_COLLECT_TYPEHASH, from, to, value, fees, secretHash));
        require(ecrecover(keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, id1)), v, r, s) == from, "SafeTransfer: wrong signature");
        bytes32 id = keccak256(abi.encode(from, value.add(fees), id1));
        uint256 tr = s_htransfers[id];
        require(tr > 0, "SafeTransfer: request not exist");
        require(uint64(tr) > now, "SafeTranfer: expired");
        require(uint64(tr>>64) <= now, "SafeTranfer: not available yet");
        require(keccak256(secret) == secretHash, "SafeTransfer: wrong secret");
        delete s_htransfers[id];
        s_fees = s_fees.add(fees);
        to.transfer(value);
        emit HCollected(from, to, id1, value);
    }

    function hiddenCollectERC20(
        address from,
        address to,
        address token,
        string memory tokenSymbol,
        uint256 value,
        uint256 fees,
        bytes32 secretHash,
        bytes calldata secret,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) 
        external
        onlyActivator()
    {
        TokenInfo memory tinfo;
        tinfo.id1 = keccak256(abi.encode(HIDDEN_ERC20_COLLECT_TYPEHASH, from, to, token, tokenSymbol, value, fees, secretHash));
        require(ecrecover(keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, tinfo.id1)), v, r, s) == from, "SafeTransfer: wrong signature");
        tinfo.id = keccak256(abi.encode(from, fees, tinfo.id1));
        uint256 tr = s_htransfers[tinfo.id];
        require(tr > 0, "SafeTransfer: request not exist");
        require(uint64(tr) > now, "SafeTranfer: expired");
        require(uint64(tr>>64) <= now, "SafeTranfer: not available yet");
        require(keccak256(secret) == secretHash, "SafeTransfer: wrong secret");
        delete s_htransfers[tinfo.id];
        s_fees = s_fees.add(fees);
        IERC20(token).safeTransferFrom(from, to, value);
        emit HERC20Collected(token, from, to, tinfo.id1, value);
    }

    function hiddenCollectERC721(
        address from,
        address to,
        address token,
        string memory tokenSymbol,
        uint256 tokenId,
        bytes memory tokenData,
        uint256 fees,
        bytes32 secretHash,
        bytes calldata secret,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) 
        external
        onlyActivator()
    {
        TokenInfo memory tinfo;
        tinfo.id1 = keccak256(abi.encode(HIDDEN_ERC721_COLLECT_TYPEHASH, from, to, token, tokenSymbol, tokenId, tokenData, fees, secretHash));
        require(ecrecover(keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, tinfo.id1)), v, r, s) == from, "SafeTransfer: wrong signature");
        tinfo.id = keccak256(abi.encode(from, fees, tinfo.id1));
        require(s_htransfers[tinfo.id] > 0, "SafeTransfer: request not exist");
        require(uint64(s_htransfers[tinfo.id]) > now, "SafeTranfer: expired");
        require(uint64(s_htransfers[tinfo.id]>>64) <= now, "SafeTranfer: not available yet");
        require(keccak256(secret) == secretHash, "SafeTransfer: wrong secret");
        delete s_htransfers[tinfo.id];
        s_fees = s_fees.add(fees);
        IERC721(token).safeTransferFrom(from, to, tokenId, tokenData);
        emit HERC721Collected(token, from, to, tinfo.id1, tokenId);
    }

   function hiddenAutoRetrieve(
        address payable from,
        bytes32 id1,
        uint256 value
    ) 
        external
        onlyActivator()
    {
        bytes32 id = keccak256(abi.encode(from, value, id1));
        require(s_htransfers[id] > 0, "SafeTransfer: request not exist");
        uint256 tr = s_htransfers[id];
        require(uint64(tr) <= now, "SafeTranfer: not expired");
        delete  s_htransfers[id];
        s_fees = s_fees + (tr>>128);
        uint256 toRetrieve = value.sub(tr>>128);
        from.transfer(toRetrieve);
        emit HRetrieved(from, id1, toRetrieve);
    }

}
