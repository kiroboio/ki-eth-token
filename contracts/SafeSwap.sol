// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
@title SafeSwap constract 
@author Tal Asa <tal@kirobo.io> , Ori Shalom <oris@kirobo.io> 
@notice handles swapping of token between 2 parties:
        sender - fills the information for both parties 
        addresses - his address and the recipient address
        token - address of the specific token to be transferred (eth, token20, token721)
        value - the value that he will be sending and the value he will be recieving
        fees - both parties fees
        secretHash - a hash of his secret phrase for the secure transfer

        recipient - checks that all the agreed between the two is the info is filled correctly
        and if so, approves the swap
 */
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

    struct SwapAutoRetrieveERC721 {
        address to;
        address token0;
        uint256 value0;
        bytes tokenData0;
        uint256 fees0;
        address token1;
        uint256 value1;
        bytes tokenData1;
        uint256 fees1;
        bytes32 secretHash;
    }

    struct SwapRetrieveERC721 {
        address to;
        address token0;
        uint256 value0;
        bytes tokenData0;
        uint256 fees0;
        address token1;
        uint256 value1;
        bytes tokenData1;
        uint256 fees1;
        bytes32 secretHash;
    }
    struct SwapTimedDepositERC721 {
        address payable to;
        address token0;
        uint256 value0; //in case of ether it's a value, in case of 721 it's tokenId
        bytes tokenData0;
        uint256 fees0;
        address token1;
        uint256 value1; //in case of ether it's a value, in case of 721 it's tokenId
        bytes tokenData1;
        uint256 fees1;
        bytes32 secretHash;
        uint64 availableAt;
        uint64 expiresAt;
        uint128 autoRetrieveFees;
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
        bytes tokenData0;
        bytes tokenData1;
        bytes secret;
        bytes32 secretHash;
    }

    mapping(bytes32 => uint256) s_transfers;
    mapping(bytes32 => uint256) s_erc20Transfers;
    mapping(bytes32 => uint256) s_erc721Transfers;
    mapping(bytes32 => uint256) s_htransfers;

    string public constant NAME = "Kirobo Safe Transfer";
    string public constant VERSION = "1";
    uint8 public constant VERSION_NUMBER = 0x1;

    event SwapDeposited(
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

    event SwapTimedDeposited(
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

    event Swapped(
        address indexed from,
        address indexed to,
        bytes32 indexed id,
        address token0,
        uint256 value0,
        address token1,
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

    event ERC721SwapDeposited(
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
        address indexed from,
        address indexed to,
        address indexed token0,
        uint256 value0, //in case of ether it's a value, in case of 721 it's tokenId
        uint256 fees0,
        address token1,
        uint256 value1, //in case of ether it's a value, in case of 721 it's tokenId
        uint256 fees1,
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

    /**
    @notice deposit - safe swap function that the sender side fills with all the relevet information for the swap
            this function deels with Ether and token20 swaps
    @param to: address of the recipient
    @param token0: the address of the token he is sending to the recipient
    @param value0: the amount being sent to the recipient side in the selected token in token0
    @param fees0: the amount of fees the he needs to pay for the swap
    @param token1: the address of the token he is recieving from the recipient 
    @param value1: the amount being sent to him by the recipient in the selected token in token1
    @param fees1: the amount of fees the recipient needs to pay for the swap
    @param secretHash: a hash of the secret phrase 
 */
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
        emit SwapDeposited(
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

    /**
    @notice timedDeposit - handles deposits like the above deposit function with an addition that has a timer in seconds
    @param to: address of the recipient
    @param token0: the address of the token he is sending to the recipient
    @param value0: the amount being sent to the recipient side in the selected token in token0
    @param fees0: the amount of fees the he needs to pay for the swap
    @param token1: the address of the token he is recieving from the recipient 
    @param value1: the amount being sent to him by the recipient in the selected token in token1
    @param fees1: the amount of fees the recipient needs to pay for the swap
    @param secretHash: a hash of the secret phrase 
    @param availableAt: sets a start time in seconds for when the deposite can happen
    @param expiresAt: sets an end time in seconds for when the deposite can happen
    @param autoRetrieveFees: the amount of fees that will be collected from the sender in case of retrieve
     */
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
        emit SwapTimedDeposited(
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

    /**
    @notice Retrieve - gives the functionallity of the undo
            after the sender sends the deposit he can undo it (for what ever reason)
            until the recipient didnt approved the swap (swap function below)
    @param to: address of the recipient
    @param token0: the address of the token he is sending to the recipient
    @param value0: the amount being sent to the recipient side in the selected token in token0
    @param fees0: the amount of fees the he needs to pay for the swap
    @param token1: the address of the token he is recieving from the recipient 
    @param value1: the amount being sent to him by the recipient in the selected token in token1
    @param fees1: the amount of fees the recipient needs to pay for the swap
    @param secretHash: a hash of the secret phrase 
     */
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

    /**
    @notice Swap - the recipient side approves the info sent by the sender.
            once this function is submitted successuly the swap is made
    @param from: address of the recipient
    @param token0: the address of the token he is sending to the recipient
    @param value0: the amount being sent to the recipient side in the selected token in token0
    @param fees0: the amount of fees the he needs to pay for the swap
    @param token1: the address of the token he is recieving from the recipient 
    @param value1: the amount being sent to him by the recipient in the selected token in token1
    @param fees1: the amount of fees the recipient needs to pay for the swap
    @param secretHash: a hash of the secret phrase 
     */
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
        emit Swapped(from, msg.sender, id, token0, value0, token1, value1);
    }

    /**
    @notice autoRetrieve - gives the functionallity of the undo with addittion of automation.
            after the sender sends the deposit he can undo it (for what ever reason)
            until the recipient didnt approved the swap (swap function below)
            the autoRetrieve automatically retrieves the funds when a time that was set by the sender is met
    @param to: address of the recipient
    @param token0: the address of the token he is sending to the recipient
    @param value0: the amount being sent to the recipient side in the selected token in token0
    @param fees0: the amount of fees the he needs to pay for the swap
    @param token1: the address of the token he is recieving from the recipient 
    @param value1: the amount being sent to him by the recipient in the selected token in token1
    @param fees1: the amount of fees the recipient needs to pay for the swap
    @param secretHash: a hash of the secret phrase 
     */
    function autoRetrieve(
        address to,
        address token0,
        uint256 value0,
        uint256 fees0,
        address token1,
        uint256 value1,
        uint256 fees1,
        bytes32 secretHash
    ) external onlyActivator() {
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
        uint256 tr = s_transfers[id];
        require(tr > 0, "SafeSwap: request not exist");
        require(uint64(tr) <= now, "SafeSwap: not expired");
        delete s_transfers[id];
        s_fees = s_fees + (tr >> 128); // autoRetreive fees
        uint256 valueToRetrieve;
        if (token0 == address(0)) {
            valueToRetrieve = value0.add(fees0).sub(tr >> 128);
        } else {
            valueToRetrieve = fees0.sub(tr >> 128);
        }
        msg.sender.transfer(valueToRetrieve);
        emit Retrieved(msg.sender, to, id, valueToRetrieve);
    }

    // ------------------------------- ERC-721 -------------------------------

    /**
    @notice depositERC721  - safe swap function that the sender side fills with all the relevet information for the swap
                    this function deels with Ether and token721 swaps
    @param to: address of the recipient
    @param token0: the address of the token he is sending to the recipient
    @param value0: in case of Ether  - the amount being sent to the recipient side in the selected token in token0
                   in case of token721 - it's the tokenId of the token721
    @param tokenData0: data on the token Id (only in token721)
    @param fees0: the amount of fees the he needs to pay for the swap
    @param token1: the address of the token he is recieving from the recipient 
    @param value1: in case of Ether  - the amount being sent to the recipient side in the selected token in token1
                   in case of token721 - it's the tokenId of the token721
    @param tokenData1: data on the token Id (only in token721)
    @param fees1: the amount of fees the recipient needs to pay for the swap
    @param secretHash: a hash of the secret phrase                     
 */
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
        require(s_erc721Transfers[id] == 0, "SafeSwap: request exist");
        s_erc721Transfers[id] = 0xffffffffffffffff; // expiresAt: max, AvailableAt: 0, autoRetrieveFees: 0
        emit ERC721SwapDeposited(
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

    /**
    @notice swapERC721 - the recipient side, besically approves the info sent by the sender.
            once this function is submitted successuly the swap is made
    @param inputs: a struct (SwapErc721Struct) defimed above containing the following params:
        to:     address of the recipient
        token0: the address of the token he is sending to the recipient
        value0: in case of Ether  - the amount being sent to the recipient side in the selected token in token0
                in case of token721 - it's the tokenId of the token721
        tokenData0: data on the token Id (only in token721)
        fees0: the amount of fees the he needs to pay for the swap
        token1: the address of the token he is recieving from the recipient 
        value1: in case of Ether  - the amount being sent to the recipient side in the selected token in token1
                in case of token721 - it's the tokenId of the token721
        tokenData1: data on the token Id (only in token721)
        fees1: the amount of fees the recipient needs to pay for the swap
        secretHash: a hash of the secret phrase 
     */
    function swapERC721(SwapErc721Struct memory inputs) external payable {
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
        uint256 tr = s_erc721Transfers[id];
        require(tr > 0, "SafeSwap: request not exist");
        require(uint64(tr) > now, "SafeSwap: expired");
        require(uint64(tr >> 64) <= now, "SafeSwap: not available yet");
        require(
            keccak256(inputs.secret) == inputs.secretHash,
            "SafeSwap: wrong secret"
        );
        delete s_erc721Transfers[id];
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

    /**
    @notice retrieveERC721 - gives the functionallity of the undo for swaps containing ERC721 tokens
            after the sender sends the deposit he can undo it (for what ever reason)
            until the recipient didnt approved the swap (swap function below)
    @param inputs: a struct (SwapRetrieveERC721) defimed above containing the following params:    
            to: address of the recipient
            token0: the address of the token he is sending to the recipient
            value0: in case of Ether  - the amount being sent to the recipient side in the selected token in token0
                    in case of token721 - it's the tokenId of the token721
            tokenData0: data on the token Id (only in token721)
            fees0: the amount of fees the he needs to pay for the swap
            token1: the address of the token he is recieving from the recipient 
            value1: in case of Ether  - the amount being sent to the recipient side in the selected token in token1
                    in case of token721 - it's the tokenId of the token721
            tokenData1: data on the token Id (only in token721)
            fees1: the amount of fees the recipient needs to pay for the swap
            secretHash: a hash of the secret phrase 

     */
    function retrieveERC721(SwapRetrieveERC721 memory inputs) external {
        bytes32 id = keccak256(
            abi.encode(
                msg.sender,
                inputs.to,
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
        require(s_erc721Transfers[id] > 0, "SafeSwap: request not exist");
        delete s_erc721Transfers[id];
        uint256 valueToSend;
        if (inputs.token0 == address(0)) {
            valueToSend = inputs.value0.add(inputs.fees0);
        } else {
            valueToSend = inputs.fees0;
        }
        msg.sender.transfer(valueToSend);
        if (inputs.token0 == address(0)) {
            emit Retrieved(msg.sender, inputs.to, id, valueToSend);
        } else {
            emit ERC721Retrieved(
                inputs.token0,
                msg.sender,
                inputs.to,
                id,
                inputs.value0
            );
        }
    }

    function autoRetrieveERC721(SwapAutoRetrieveERC721 memory inputs)
        external
        onlyActivator()
    {
        bytes32 id = keccak256(
            abi.encode(
                msg.sender,
                inputs.to,
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
        uint256 tr = s_erc721Transfers[id];
        require(tr > 0, "SafeSwap: request not exist");
        require(uint64(tr) <= now, "SafeSwap: not expired");
        delete s_erc721Transfers[id];
        s_fees = s_fees + (tr >> 128); // autoRetreive fees
        uint256 valueToRetrieve;
        if (inputs.token0 == address(0)) {
            valueToRetrieve = inputs.value0.add(inputs.fees0).sub(tr >> 128);
        } else {
            valueToRetrieve = inputs.fees0.sub(tr >> 128);
        }
        msg.sender.transfer(valueToRetrieve);
        if (inputs.token0 == address(0)) {
            emit Retrieved(msg.sender, inputs.to, id, valueToRetrieve);
        } else {
            emit ERC721Retrieved(
                inputs.token0,
                msg.sender,
                inputs.to,
                id,
                inputs.value0
            );
        }
    }

    function timedDepositERC721(SwapTimedDepositERC721 memory inputs)
        external
        payable
    {
        if (inputs.token0 == address(0)) {
            //eth to 721
            require(
                inputs.token0 != inputs.token1,
                "SafeSwap: try to swap ether and ether"
            );
            require(
                msg.value == inputs.value0.add(inputs.fees0),
                "SafeSwap: value mismatch"
            );
            require(inputs.value1 > 0, "SafeSwap: no token id");
        } else if (inputs.token1 == address(0)) {
            //721 to eth
            require(msg.value == inputs.fees0, "SafeSwap: value mismatch");
            require(inputs.value0 > 0, "SafeSwap: no token id");
        } else {
            //721 to 721
            require(inputs.value0 > 0, "SafeSwap: no token id");
            require(inputs.value1 > 0, "SafeSwap: no token id");
        }
        require(inputs.expiresAt > now, "SafeSwap: already expired");
        bytes32 id = keccak256(
            abi.encode(
                msg.sender,
                inputs.to,
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
        require(s_erc721Transfers[id] == 0, "SafeSwap: request exist");
        s_erc721Transfers[id] =
            uint256(inputs.expiresAt) +
            (uint256(inputs.availableAt) << 64) +
            (uint256(inputs.autoRetrieveFees) << 128);
        emit ERC721TimedDeposited(
            msg.sender,
            inputs.to,
            inputs.token0,
            inputs.value0,
            inputs.fees0,
            inputs.token1,
            inputs.value1,
            inputs.fees1,
            inputs.secretHash,
            inputs.availableAt,
            inputs.expiresAt,
            inputs.autoRetrieveFees
        );
    }

    // ----------------------- Hidden ETH / ERC-20 / ERC-721 -----------------------
    /*
    function hiddenRetrieve(bytes32 id1, uint256 value) external {
        bytes32 id = keccak256(abi.encode(msg.sender, value, id1));
        require(s_htransfers[id] > 0, "SafeSwap: request not exist");
        delete s_htransfers[id];
        msg.sender.transfer(value);
        emit HRetrieved(msg.sender, id1, value);
    }

    function hiddenAutoRetrieve(
        address payable from,
        bytes32 id1,
        uint256 value
    ) external onlyActivator() {
        bytes32 id = keccak256(abi.encode(from, value, id1));
        uint256 tr = s_htransfers[id];
        require(tr > 0, "SafeSwap: request not exist");
        require(uint64(tr) <= now, "SafeSwap: not expired");
        delete s_htransfers[id];
        s_fees = s_fees + (tr >> 128);
        uint256 toRetrieve = value.sub(tr >> 128);
        from.transfer(toRetrieve);
        emit HRetrieved(from, id1, toRetrieve);
    }
    

    unction hiddenSwapDeposit(bytes32 id1) external payable {
        bytes32 id = keccak256(abi.encode(msg.sender, msg.value, id1));
        require(s_htransfers[id] == 0, "SafeSwap: request exist");
        s_htransfers[id] = 0xffffffffffffffff;
        emit HDeposited(msg.sender, msg.value, id1);
    }

    function hiddenSwapTimedDeposit(
        bytes32 id1,
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
    ) external payable {
        require(
            msg.value >= autoRetrieveFees,
            "SafeSwap: autoRetrieveFees exeed value"
        );
        bytes32 id = keccak256(abi.encode(msg.sender, msg.value, id1));
        require(s_htransfers[id] == 0, "SafeSwap: request exist");
        require(expiresAt > now, "SafeSwap: already expired");
        s_htransfers[id] =
            uint256(expiresAt) +
            (uint256(availableAt) << 64) +
            (uint256(autoRetrieveFees) << 128);
        emit HTimedDeposited(
            msg.sender,
            msg.value,
            id1,
            availableAt,
            expiresAt,
            autoRetrieveFees
        );
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

   
*/
}
