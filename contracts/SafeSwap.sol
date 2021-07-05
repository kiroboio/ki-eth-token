// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SafeSwap is AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // keccak256("ACTIVATOR_ROLE");
    bytes32 public constant ACTIVATOR_ROLE =
        0xec5aad7bdface20c35bc02d6d2d5760df981277427368525d634f4e2603ea192;

    // keccak256("hiddenCollect(address from,address to,uint256 value,uint256 fees,bytes32 secretHash)");
    bytes32 public constant HIDDEN_COLLECT_TYPEHASH =
        0x0506afef36f3613836f98ef019cb76a3e6112be8f9dc8d8fa77275d64f418234;

    // keccak256("hiddenCollectERC20(address from,address to,address token,string tokenSymbol,uint256 value,uint256 fees,bytes32 secretHash)");
    bytes32 public constant HIDDEN_ERC20_COLLECT_TYPEHASH =
        0x9e6214229b9fba1927010d30b22a3a5d9fd5e856bb29f056416ff2ad52e8de44;

    // keccak256("hiddenCollectERC721(address from,address to,address token,string tokenSymbol,uint256 tokenId,bytes tokenData,uint256 fees,bytes32 secretHash)");
    bytes32 public constant HIDDEN_ERC721_COLLECT_TYPEHASH =
        0xa14a2dc51c26e451800897aa798120e7d6c35039caf5eb29b8ac35d1e914c591;

    bytes32 public DOMAIN_SEPARATOR;
    uint256 public CHAIN_ID;
    bytes32 s_uid;
    uint256 s_fees;

    struct TokenInfo {
        bytes32 id;
        bytes32 id1;
        uint256 tr;
    }

    struct SwapErc721Struct {
        address payable from;
        address token0;
        uint256 value0; //in case of ether it's a value, in case of 721 it's tokenId
        bytes tokenData0;
        uint256 fees0;
        address token1;
        uint256 value1; //in case of ether it's a value, in case of 721 it's tokenId
        bytes tokenData1;
        uint256 fees1;
        bytes32 secretHash;
        bytes secret;
    }
    struct SwapAddresses {
        address payable from;
        address token0;
        address token1;
    }
    struct SwapUints {
        uint256 value0;
        uint256 fees0;
        uint256 value1;
        uint256 fees1;
    }
    struct SwapBytes {
        bytes32 secretHash;
        bytes tokenData0;
        bytes tokenData1;
        bytes secret;
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
        address indexed token0,
        uint256 value0,
        uint256 fees0,
        bytes32 secretHash0,
        address token1,
        uint256 value1,
        uint256 fees1
    );

    event TimedDeposited(
        address indexed from,
        address indexed to,
        address indexed token0,
        uint256 value0,
        uint256 fees0,
        bytes32 secretHash0,
        address token1,
        uint256 value1,
        uint256 fees1,
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

    event Rejected(
        address indexed from,
        address indexed to,
        bytes32 indexed id,
        uint256 value
    );

    event Swapped(
        address indexed from,
        address indexed to,
        bytes32 indexed id,
        uint256 value0,
        uint256 value1
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

    /*
            msg.sender,
            to,
            token0,
            value0,
            fees0,
            token1,
            value1,
            fees1,
            secretHash

        address payable to,
        address token0,
        uint256 value0, //in case of ether it's a value, in case of 721 it's tokenId
        bytes calldata tokenData0,
        uint256 fees0,
        address token1,
        uint256 value1, //in case of ether it's a value, in case of 721 it's tokenId
        bytes calldata tokenData1,
        uint256 fees1,
        bytes32 secretHash
*/
    event ERC721Deposited(
        address indexed from,
        address indexed to,
        address indexed token0,
        uint256 value0, //in case of ether it's a value, in case of 721 it's tokenId
        uint256 fees0,
        address token1,
        uint256 value1, //in case of ether it's a value, in case of 721 it's tokenId
        uint256 fees1,
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

    event ERC721Swapped(
        address indexed from,
        address indexed to,
        address indexed token0,
        uint256 value0,
        address token1,
        uint256 value1,
        bytes32 id
    );

    event HDeposited(address indexed from, uint256 value, bytes32 indexed id1);

    event HTimedDeposited(
        address indexed from,
        uint256 value,
        bytes32 indexed id1,
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
    );

    event HRetrieved(address indexed from, bytes32 indexed id1, uint256 value);

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
        require(
            hasRole(ACTIVATOR_ROLE, msg.sender),
            "SafeTransfer: not an activator"
        );
        _;
    }

    constructor(address activator) public {
        s_fees = 1; // only for testing

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ACTIVATOR_ROLE, msg.sender);
        _setupRole(ACTIVATOR_ROLE, activator);

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        CHAIN_ID = chainId;

        s_uid = bytes32(
            (uint256(VERSION_NUMBER) << 248) |
                ((uint256(blockhash(block.number - 1)) << 192) >> 16) |
                uint256(address(this))
        );

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
                ),
                keccak256(bytes(NAME)),
                keccak256(bytes(VERSION)),
                chainId,
                address(this),
                s_uid
            )
        );
    }

    receive() external payable {
        require(false, "SafeTransfer: not accepting ether directly");
    }

    function transferERC20(
        address token,
        address wallet,
        uint256 value
    ) external onlyActivator() {
        IERC20(token).safeTransfer(wallet, value);
    }

    function transferERC721(
        address token,
        address wallet,
        uint256 tokenId,
        bytes calldata data
    ) external onlyActivator() {
        IERC721(token).safeTransferFrom(address(this), wallet, tokenId, data);
    }

    function transferFees(address payable wallet, uint256 value)
        external
        onlyActivator()
    {
        s_fees = s_fees.sub(value);
        wallet.transfer(value);
    }

    function totalFees() external view returns (uint256) {
        return s_fees;
    }

    function uid() external view returns (bytes32) {
        return s_uid;
    }

    // --------------------------------- ETH ---------------------------------

    function deposit(
        address payable to,
        address token0,
        uint256 value0,
        uint256 fees0,
        address token1,
        uint256 value1,
        uint256 fees1,
        bytes32 secretHash
    ) external payable {
        require(token0 != token1, "SafeSwap: try to swap the same token");
        if (token0 == address(0)) {
            require(msg.value == value0.add(fees0), "SafeSwap: value mismatch");
        } else {
            require(msg.value == fees0, "SafeSwap: value mismatch");
        }
        require(to != msg.sender, "SafeSwap: sender==recipient");
        bytes32 id = keccak256(
            abi.encode(
                msg.sender,
                to,
                token0,
                value0,
                fees0,
                token1,
                value1,
                fees1,
                secretHash
            )
        );
        require(s_transfers[id] == 0, "SafeSwap: request exist");
        s_transfers[id] = 0xffffffffffffffff; // expiresAt: max, AvailableAt: 0, autoRetrieveFees: 0
        emit Deposited(
            msg.sender,
            to,
            token0,
            value0,
            fees0,
            secretHash,
            token1,
            value1,
            fees1
        );
    }

    function timedDeposit(
        address payable to,
        address token0,
        uint256 value0,
        uint256 fees0,
        address token1,
        uint256 value1,
        uint256 fees1,
        bytes32 secretHash,
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
    ) external payable {
        require(token0 != token1, "SafeSwap: try to swap the same token");
        require(
            fees0 >= autoRetrieveFees,
            "SafeSwap: autoRetrieveFees exeed fees"
        );
        require(to != msg.sender, "SafeSwap: sender==recipient");
        require(expiresAt > now, "SafeSwap: already expired");
        if (token0 == address(0)) {
            require(msg.value == value0.add(fees0), "SafeSwap: value mismatch");
        } else {
            require(msg.value == fees0, "SafeSwap: value mismatch");
        }

        bytes32 id = keccak256(
            abi.encode(
                msg.sender,
                to,
                token0,
                value0,
                fees0,
                token1,
                value1,
                fees1,
                secretHash
            )
        );
        require(s_transfers[id] == 0, "SafeSwap: request exist");
        s_transfers[id] =
            uint256(expiresAt) +
            uint256(availableAt << 64) +
            (uint256(autoRetrieveFees) << 128);
        emit TimedDeposited(
            msg.sender,
            to,
            token0,
            value0,
            fees0,
            secretHash,
            token1,
            value1,
            fees1,
            availableAt,
            expiresAt,
            autoRetrieveFees
        );
    }

    function retrieve(
        address to,
        address token0,
        uint256 value0,
        uint256 fees0,
        address token1,
        uint256 value1,
        uint256 fees1,
        bytes32 secretHash
    ) external {
        bytes32 id = keccak256(
            abi.encode(
                msg.sender,
                to,
                token0,
                value0,
                fees0,
                token1,
                value1,
                fees1,
                secretHash
            )
        );
        require(s_transfers[id] > 0, "SafeSwap: request not exist");
        delete s_transfers[id];
        uint256 valueToSend;
        if (token0 == address(0)) {
            valueToSend = value0.add(fees0);
        } else {
            valueToSend = fees0;
        }
        msg.sender.transfer(valueToSend);
        emit Retrieved(msg.sender, to, id, valueToSend);
    }

    function reject(
        address payable from,
        address token0,
        uint256 value0,
        uint256 fees0,
        address token1,
        uint256 value1,
        uint256 fees1,
        bytes32 secretHash
    ) external {
        bytes32 id = keccak256(
            abi.encode(
                from,
                msg.sender,
                token0,
                value0,
                fees0,
                token1,
                value1,
                fees1,
                secretHash
            )
        );
        require(s_transfers[id] > 0, "SafeSwap: request not exist");
        delete s_transfers[id];
        uint256 valueToSend;
        if (token0 == address(0)) {
            valueToSend = value0.add(fees0);
        } else {
            valueToSend = fees0;
        }
        from.transfer(valueToSend);
        emit Rejected(from, msg.sender, id, valueToSend);
    }

    function swap(
        address payable from,
        address token0,
        uint256 value0,
        uint256 fees0,
        address token1,
        uint256 value1,
        uint256 fees1,
        bytes32 secretHash,
        bytes calldata secret
    ) external payable {
        bytes32 id = keccak256(
            abi.encode(
                from,
                msg.sender,
                token0,
                value0,
                fees0,
                token1,
                value1,
                fees1,
                secretHash
            )
        );
        uint256 tr = s_transfers[id];
        require(tr > 0, "SafeSwap: request not exist");
        require(uint64(tr) > now, "SafeSwap: expired");
        require(uint64(tr >> 64) <= now, "SafeSwap: not available yet");
        require(keccak256(secret) == secretHash, "SafeSwap: wrong secret");
        delete s_transfers[id];
        s_fees = s_fees.add(fees0).add(fees1);
        if (token0 == address(0)) {
            msg.sender.transfer(value0);
        } else {
            IERC20(token0).safeTransferFrom(from, msg.sender, value0);
        }
        if (token1 == address(0)) {
            require(msg.value == value1.add(fees1), "SafeSwap: value mismatch");
            from.transfer(value1);
        } else {
            require(msg.value == fees1, "SafeSwap: value mismatch");
            IERC20(token1).safeTransferFrom(msg.sender, from, value1);
        }
        emit Swapped(from, msg.sender, id, value0, value1);
    }

    /*
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
        uint256 tr = s_transfers[id];
        require(tr > 0, "SafeTransfer: request not exist");
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
        address from,
        address payable to,
        uint256 value,
        uint256 fees,
        bytes32 secretHash,
        bytes calldata secret
    ) 
        public
        onlyActivator()
    {
        bytes32 id = keccak256(abi.encode(token, from, to, value, fees, secretHash));
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
        uint256 tr = s_erc20Transfers[id];
        require(tr > 0, "SafeTransfer: request not exist");
        require(uint64(tr) <= now, "SafeTranfer: not expired");
        delete  s_erc20Transfers[id];
        s_fees = s_fees + (tr>>128); // autoRetreive fees
        from.transfer(fees.sub(tr>>128));
        emit ERC20Retrieved(token, from, to, id, value);
    }
 */
    // ------------------------------- ERC-721 -------------------------------

    function depositERC721(
        address payable to,
        address token0,
        uint256 value0, //in case of ether it's a value, in case of 721 it's tokenId
        bytes calldata tokenData0,
        uint256 fees0,
        address token1,
        uint256 value1, //in case of ether it's a value, in case of 721 it's tokenId
        bytes calldata tokenData1,
        uint256 fees1,
        bytes32 secretHash
    ) external payable {
        if (token0 == address(0)) {
            //eth to 721
            require(token0 != token1, "SafeSwap: try to swap ether and ether");
            require(msg.value == value0.add(fees0), "SafeSwap: value mismatch");
            require(value1 > 0, "SafeSwap: no token id");
        } else if (token1 == address(0)) {
            //721 to eth
            require(msg.value == fees0, "SafeSwap: value mismatch");
            require(value0 > 0, "SafeSwap: no token id");
        } else {
            //721 to 721
            require(value0 > 0, "SafeSwap: no token id");
            require(value1 > 0, "SafeSwap: no token id");
        }
        require(to != msg.sender, "SafeSwap: sender==recipient");
        bytes32 id = keccak256(
            abi.encode(
                msg.sender,
                to,
                token0,
                value0,
                tokenData0,
                fees0,
                token1,
                value1,
                tokenData1,
                fees1,
                secretHash
            )
        );
        require(s_transfers[id] == 0, "SafeSwap: request exist");
        s_transfers[id] = 0xffffffffffffffff; // expiresAt: max, AvailableAt: 0, autoRetrieveFees: 0
        emit ERC721Deposited(
            msg.sender,
            to,
            token0,
            value0,
            fees0,
            token1,
            value1,
            fees1,
            secretHash
        );
    }

    /*
    struct SwapAddresses {
        address payable from;
        address token0;
        address token1;
    }
    struct SwapUints {
        uint256 value0;
        uint256 fees0;
        uint256 value1;
        uint256 fees1;
    }
    struct SwapBytes {
        bytes32 secretHash;
        bytes tokenData0;
        bytes tokenData1;
        bytes secret;
    }
    */

    function swapERC721(
        SwapAddresses memory addresses,
        SwapUints memory uints,
        SwapBytes memory swapBytes
    ) external payable {
        bytes32 id = keccak256(
            abi.encode(
                addresses.from,
                msg.sender,
                addresses.token0,
                uints.value0,
                swapBytes.tokenData0,
                uints.fees0,
                addresses.token1,
                uints.value1,
                swapBytes.tokenData1,
                uints.fees1,
                swapBytes.secretHash
            )
        );
        uint256 tr = s_transfers[id];
        require(tr > 0, "SafeSwap: request not exist");
        require(uint64(tr) > now, "SafeSwap: expired");
        require(uint64(tr >> 64) <= now, "SafeSwap: not available yet");

        require(
            keccak256(swapBytes.secret) == swapBytes.secretHash,
            "SafeSwap: wrong secret"
        );
        delete s_transfers[id];
        s_fees = s_fees.add(uints.fees0).add(uints.fees1);
        if (addresses.token0 == address(0)) {
            //ether to 721
            msg.sender.transfer(uints.value0);
        } else {
            IERC721(addresses.token0).safeTransferFrom(
                addresses.from,
                msg.sender,
                uints.value0,
                swapBytes.tokenData0
            );
        }
        if (addresses.token1 == address(0)) {
            //721 to ether
            require(
                msg.value == uints.value1.add(uints.fees1),
                "SafeSwap: value mismatch"
            );
            addresses.from.transfer(uints.value1);
        } else {
            require(msg.value == uints.fees1, "SafeSwap: value mismatch");
            IERC721(addresses.token1).safeTransferFrom(
                msg.sender,
                addresses.from,
                uints.value1,
                swapBytes.tokenData1
            );
        }
        emit ERC721Swapped(
            addresses.from,
            msg.sender,
            addresses.token0,
            uints.value0,
            addresses.token1,
            uints.value1,
            id
        );
    }

    function swapERC721_1(SwapErc721Struct memory inputs) external payable {
        bytes32 id = keccak256(
            abi.encode(
                inputs.from,
                msg.sender,
                inputs.token0,
                inputs.value0,
                inputs.tokenData0,
                inputs.fees0,
                inputs.token1,
                inputs.value1,
                inputs.tokenData1,
                inputs.fees1,
                inputs.secretHash
            )
        );
        uint256 tr = s_transfers[id];
        require(tr > 0, "SafeSwap: request not exist");
        require(uint64(tr) > now, "SafeSwap: expired");
        require(uint64(tr >> 64) <= now, "SafeSwap: not available yet");
        require(
            keccak256(inputs.secret) == inputs.secretHash,
            "SafeSwap: wrong secret"
        );
        delete s_transfers[id];
        s_fees = s_fees.add(inputs.fees0).add(inputs.fees1);
        if (inputs.token0 == address(0)) {
            //ether to 721
            msg.sender.transfer(inputs.value0);
        } else {
            IERC721(inputs.token0).safeTransferFrom(
                inputs.from,
                msg.sender,
                inputs.value0,
                inputs.tokenData0
            );
        }
        if (inputs.token1 == address(0)) {
            //721 to ether
            require(
                msg.value == inputs.value1.add(inputs.fees1),
                "SafeSwap: value mismatch"
            );
            inputs.from.transfer(inputs.value1);
        } else {
            require(msg.value == inputs.fees1, "SafeSwap: value mismatch");
            IERC721(inputs.token1).safeTransferFrom(
                msg.sender,
                inputs.from,
                inputs.value1,
                inputs.tokenData1
            );
        }
        emit ERC721Swapped(
            inputs.from,
            msg.sender,
            inputs.token0,
            inputs.value0,
            inputs.token1,
            inputs.value1,
            id
        );
    }

    function retrieveERC721(
        address to,
        address token0,
        uint256 value0,
        bytes calldata tokenData0,
        uint256 fees0,
        address token1,
        uint256 value1,
        bytes calldata tokenData1,
        uint256 fees1,
        bytes32 secretHash
    ) external {
        bytes32 id = keccak256(
            abi.encode(
                msg.sender,
                to,
                token0,
                value0,
                tokenData0,
                fees0,
                token1,
                value1,
                tokenData1,
                fees1,
                secretHash
            )
        );
        require(s_transfers[id] > 0, "SafeSwap: request not exist");
        delete s_transfers[id];
        uint256 valueToSend;
        if (token0 == address(0)) {
            valueToSend = value0.add(fees0);
        } else {
            valueToSend = fees0;
        }
        msg.sender.transfer(valueToSend);
        emit Retrieved(msg.sender, to, id, valueToSend);
    }

    /*
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
        uint256 tr = s_erc721Transfers[id];
        require(tr > 0, "SafeTransfer: request not exist");
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
        tinfo.tr = s_htransfers[tinfo.id]; 
        require(tinfo.tr > 0, "SafeTransfer: request not exist");
        require(uint64(tinfo.tr) > now, "SafeTranfer: expired");
        require(uint64(tinfo.tr>>64) <= now, "SafeTranfer: not available yet");
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
        uint256 tr = s_htransfers[id];
        require(tr > 0, "SafeTransfer: request not exist");
        require(uint64(tr) <= now, "SafeTranfer: not expired");
        delete  s_htransfers[id];
        s_fees = s_fees + (tr>>128);
        uint256 toRetrieve = value.sub(tr>>128);
        from.transfer(toRetrieve);
        emit HRetrieved(from, id1, toRetrieve);
    }

    function swap(
        address from,
        address to,
        address token0,
        uint256 value0,
        uint256 fees0,
        bytes32 secretHash0,
        bytes calldata secret0,
        address token1,
        uint256 value1,
        uint256 fees1,
        bytes32 secretHash1,
        bytes calldata secret1
    ) 
        external
    {
        if (token0 == address(0)) {
            collect(from, payable(to), value0, fees0, secretHash0, secret0);
        } else {
            collectERC20(token0, from, payable(to), value0, fees0, secretHash0, secret0);
        }
        if (token1 == address(0)) {
            collect(from, payable(to), value1, fees1, secretHash1, secret1);
        } else {
            collectERC20(token0, from, payable(to), value1, fees1, secretHash1, secret1);
        }
    }
*/
}
