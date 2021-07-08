// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";

/** @title SafeSwap constract 
    @author Tal Asa <tal@kirobo.io> , Ori Shalom <oris@kirobo.io> 
    @notice handles swapping of token between 2 parties:
        sender - fills the information for both parties 
        addresses - his address and the recipient address
        token - address of the specific token to be transferred (eth, token20, token721)
        value - the value that he will be sending and the value he will be recieving
        fees - both parties fees
        secretHash - a hash of his secret for the secure transfer

        recipient - checks that all the agreed between the two is the info is filled correctly
        and if so, approves the swap
 */
contract SafeSwap is AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // keccak256("ACTIVATOR_ROLE");
    bytes32 public constant ACTIVATOR_ROLE =
        0xec5aad7bdface20c35bc02d6d2d5760df981277427368525d634f4e2603ea192;

    // keccak256("hiddenSwap(address from,address to,address token0,uint256 value0,uint256 fees0,address token1,uint256 value1,uint256 fees1,bytes32 secretHash)");
    bytes32 public constant HIDDEN_SWAP_TYPEHASH =
        0x0f11af065228fe4d4a82a264c46914620a3a99413bfee68f390bd6a3ba05e2c2;

    // keccak256("hiddenSwapERC721(address from,address to,address token0,uint256 value0,bytes tokenData0,uint256 fees0,address token1,uint256 value1,bytes tokenData1,uint256 fees1,bytes32 secretHash)");
    bytes32 public constant HIDDEN_ERC721_SWAP_TYPEHASH =
        0x22eb06b067ef6305a65d8334d41817cd2fb49f43ee331996ed20687c8152e5ed;

    bytes32 public DOMAIN_SEPARATOR;
    uint256 public CHAIN_ID;
    bytes32 s_uid;
    uint256 s_fees;

    struct SwapInfo {
        address token0;
        uint256 value0;
        uint256 fees0;
        address token1;
        uint256 value1;
        uint256 fees1;
        bytes32 secretHash;
    }

    struct SwapERC721Info {
        address token0;
        uint256 value0; //in case of ether it's a value, in case of 721 it's tokenId
        bytes tokenData0;
        uint256 fees0;
        address token1;
        uint256 value1; //in case of ether it's a value, in case of 721 it's tokenId
        bytes tokenData1;
        uint256 fees1;
        bytes32 secretHash;
    }

    mapping(bytes32 => uint256) s_transfers;
    mapping(bytes32 => uint256) s_erc20Transfers;
    mapping(bytes32 => uint256) s_erc721Transfers;
    mapping(bytes32 => uint256) s_htransfers;

    string public constant NAME = "Kirobo Safe Swap";
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

    event HSwapped(
        address indexed from,
        address indexed to,
        bytes32 indexed id1,
        address token0,
        uint256 value0,
        address token1,
        uint256 value1
    );

    event HERC721Swapped(
        address indexed from,
        address indexed to,
        bytes32 indexed id1,
        address token0,
        uint256 value0,
        address token1,
        uint256 value1
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

    // --------------------------------- ETH <==> ERC20 ---------------------------------

    /** @notice deposit - safe swap function that the sender side fills with all the relevet information for the swap
               this function deels with Ether and token20 swaps
        @param to: address of the recipient
        @param token0: the address of the token he is sending to the recipient
        @param value0: the amount being sent to the recipient side in the selected token in token0
        @param fees0: the amount of fees the he needs to pay for the swap
        @param token1: the address of the token he is recieving from the recipient 
        @param value1: the amount being sent to him by the recipient in the selected token in token1
        @param fees1: the amount of fees the recipient needs to pay for the swap
        @param secretHash: a hash of the secret 
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

    /** @notice timedDeposit - handles deposits with an addition that has a timer in seconds
        @param to: address of the recipient
        @param token0: the address of the token he is sending to the recipient
        @param value0: the amount being sent to the recipient side in the selected token in token0
        @param fees0: the amount of fees the he needs to pay for the swap
        @param token1: the address of the token he is recieving from the recipient 
        @param value1: the amount being sent to him by the recipient in the selected token in token1
        @param fees1: the amount of fees the recipient needs to pay for the swap
        @param secretHash: a hash of the secret 
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

    /** @notice Retrieve - gives the functionallity of the undo
                after the sender sends the deposit he can undo it (for what ever reason)
                until the recipient didnt approved the swap (swap function below)
        @param to: address of the recipient
        @param token0: the address of the token he is sending to the recipient
        @param value0: the amount being sent to the recipient side in the selected token in token0
        @param fees0: the amount of fees the he needs to pay for the swap
        @param token1: the address of the token he is recieving from the recipient 
        @param value1: the amount being sent to him by the recipient in the selected token in token1
        @param fees1: the amount of fees the recipient needs to pay for the swap
        @param secretHash: a hash of the secret 
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

    /** @notice Swap - the recipient side approves the info sent by the sender.
                once this function is submitted successuly the swap is made
        @param from: address of the recipient
        @param token0: the address of the token he is sending to the recipient
        @param value0: the amount being sent to the recipient side in the selected token in token0
        @param fees0: the amount of fees the he needs to pay for the swap
        @param token1: the address of the token he is recieving from the recipient 
        @param value1: the amount being sent to him by the recipient in the selected token in token1
        @param fees1: the amount of fees the recipient needs to pay for the swap
        @param secretHash: a hash of the secret 
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

    /** @notice autoRetrieve - gives the functionallity of the undo with addittion of automation.
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
        @param secretHash: a hash of the secret 
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

    /** @notice depositERC721  - safe swap function that the sender side fills with all the relevet information for the swap
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
        @param secretHash: a hash of the secret                     
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

    /** @notice swapERC721 - the recipient side, besically approves the info sent by the sender.
                once this function is submitted successuly the swap is made
        @param from: address of the recipient
        @param info: a struct (SwapErc721Struct) defimed above containing the following params:
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
                secretHash: a hash of the secret 
        @param secret: secret made up of passcode, private salt and public salt
     */
    function swapERC721(
        address payable from,
        SwapERC721Info memory info,
        bytes calldata secret
    ) external payable {
        bytes32 id = keccak256(
            abi.encode(
                from,
                msg.sender,
                info.token0,
                info.value0,
                info.tokenData0,
                info.fees0,
                info.token1,
                info.value1,
                info.tokenData1,
                info.fees1,
                info.secretHash
            )
        );
        uint256 tr = s_erc721Transfers[id];
        require(tr > 0, "SafeSwap: request not exist");
        require(uint64(tr) > now, "SafeSwap: expired");
        require(uint64(tr >> 64) <= now, "SafeSwap: not available yet");
        require(keccak256(secret) == info.secretHash, "SafeSwap: wrong secret");
        delete s_erc721Transfers[id];
        s_fees = s_fees.add(info.fees0).add(info.fees1);
        if (info.token0 == address(0)) {
            //ether to 721
            msg.sender.transfer(info.value0);
        } else {
            IERC721(info.token0).safeTransferFrom(
                from,
                msg.sender,
                info.value0,
                info.tokenData0
            );
        }
        if (info.token1 == address(0)) {
            //721 to ether
            require(
                msg.value == info.value1.add(info.fees1),
                "SafeSwap: value mismatch"
            );
            from.transfer(info.value1);
        } else {
            require(msg.value == info.fees1, "SafeSwap: value mismatch");
            IERC721(info.token1).safeTransferFrom(
                msg.sender,
                from,
                info.value1,
                info.tokenData1
            );
        }
        emit ERC721Swapped(
            from,
            msg.sender,
            info.token0,
            info.value0,
            info.token1,
            info.value1,
            id
        );
    }

    /** @notice retrieveERC721 - gives the functionallity of the undo for swaps containing ERC721 tokens
                after the sender sends the deposit he can undo it (for what ever reason)
                until the recipient didnt approved the swap (swap function below)
        @param  to: address of the recipient
        @param  info: a struct (SwapRetrieveERC721) defimed above containing the following params:    
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
                    secretHash: a hash of the secret
     */
    function retrieveERC721(address to, SwapERC721Info memory info) external {
        bytes32 id = keccak256(
            abi.encode(
                msg.sender,
                to,
                info.token0,
                info.value0,
                info.tokenData0,
                info.fees0,
                info.token1,
                info.value1,
                info.tokenData1,
                info.fees1,
                info.secretHash
            )
        );
        require(s_erc721Transfers[id] > 0, "SafeSwap: request not exist");
        delete s_erc721Transfers[id];
        uint256 valueToSend;
        if (info.token0 == address(0)) {
            valueToSend = info.value0.add(info.fees0);
        } else {
            valueToSend = info.fees0;
        }
        msg.sender.transfer(valueToSend);
        if (info.token0 == address(0)) {
            emit Retrieved(msg.sender, to, id, valueToSend);
        } else {
            emit ERC721Retrieved(info.token0, msg.sender, to, id, info.value0);
        }
    }

    /** @notice autoRetrieveERC721 - gives the functionallity of the undo for swaps containing ERC721 tokens with addittion of automation.
                after the sender sends the deposit he can undo it (for what ever reason)
                until the recipient didnt approved the swap (swap function below)
        @param  to: address of the recipient
        @param  info: a struct (SwapRetrieveERC721) defimed above containing the following params:    
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
                    secretHash: a hash of the secret
     */
    function autoRetrieveERC721(address to, SwapERC721Info memory info)
        external
        onlyActivator()
    {
        bytes32 id = keccak256(
            abi.encode(
                msg.sender,
                to,
                info.token0,
                info.value0,
                info.tokenData0,
                info.fees0,
                info.token1,
                info.value1,
                info.tokenData1,
                info.fees1,
                info.secretHash
            )
        );
        uint256 tr = s_erc721Transfers[id];
        require(tr > 0, "SafeSwap: request not exist");
        require(uint64(tr) <= now, "SafeSwap: not expired");
        delete s_erc721Transfers[id];
        s_fees = s_fees + (tr >> 128); // autoRetreive fees
        uint256 valueToRetrieve;
        if (info.token0 == address(0)) {
            valueToRetrieve = info.value0.add(info.fees0).sub(tr >> 128);
        } else {
            valueToRetrieve = info.fees0.sub(tr >> 128);
        }
        msg.sender.transfer(valueToRetrieve);
        if (info.token0 == address(0)) {
            emit Retrieved(msg.sender, to, id, valueToRetrieve);
        } else {
            emit ERC721Retrieved(info.token0, msg.sender, to, id, info.value0);
        }
    }

    /** @notice timedDepositERC721 - handles deposits for ERC721 tokens with an addition that has a timer in seconds
        @param  to: address of the recipient
        @param  info: a struct (SwapRetrieveERC721) defimed above containing the following params:    
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
                    secretHash: a hash of the secret
        @param availableAt: sets a start time in seconds for when the deposite can happen
        @param expiresAt: sets an end time in seconds for when the deposite can happen
        @param autoRetrieveFees: the amount of fees that will be collected from the sender in case of retrieve
     */
    function timedDepositERC721(
        address to,
        SwapERC721Info memory info,
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
    ) external payable {
        if (info.token0 == address(0)) {
            //eth to 721
            require(
                info.token0 != info.token1,
                "SafeSwap: try to swap ether and ether"
            );
            require(
                msg.value == info.value0.add(info.fees0),
                "SafeSwap: value mismatch"
            );
            require(info.value1 > 0, "SafeSwap: no token id");
        } else if (info.token1 == address(0)) {
            //721 to eth
            require(msg.value == info.fees0, "SafeSwap: value mismatch");
            require(info.value0 > 0, "SafeSwap: no token id");
        } else {
            //721 to 721
            require(info.value0 > 0, "SafeSwap: no token id");
            require(info.value1 > 0, "SafeSwap: no token id");
        }
        require(expiresAt > now, "SafeSwap: already expired");
        bytes32 id = keccak256(
            abi.encode(
                msg.sender,
                to,
                info.token0,
                info.value0,
                info.tokenData0,
                info.fees0,
                info.token1,
                info.value1,
                info.tokenData1,
                info.fees1,
                info.secretHash
            )
        );
        require(s_erc721Transfers[id] == 0, "SafeSwap: request exist");
        s_erc721Transfers[id] =
            uint256(expiresAt) +
            (uint256(availableAt) << 64) +
            (uint256(autoRetrieveFees) << 128);
        emit ERC721TimedDeposited(
            msg.sender,
            to,
            info.token0,
            info.value0,
            info.fees0,
            info.token1,
            info.value1,
            info.fees1,
            info.secretHash,
            availableAt,
            expiresAt,
            autoRetrieveFees
        );
    }

    // ----------------------- Hidden ETH / ERC-20 / ERC-721 -----------------------

    /** @notice hiddenRetrieve - an abillity to retrive (undo) without exposing the info of the sender 
        @param  id1: a hash of the info being hided (sender address, token exc...)
        @param  value: the amount being sent to the recipient side in the selected token
     */
    function hiddenRetrieve(bytes32 id1, uint256 value) external {
        bytes32 id = keccak256(abi.encode(msg.sender, value, id1));
        require(s_htransfers[id] > 0, "SafeSwap: request not exist");
        delete s_htransfers[id];
        msg.sender.transfer(value);
        emit HRetrieved(msg.sender, id1, value);
    }

    /** @notice hiddenAutoRetrieve - an abillity to retrive (undo) without exposing the info of the sender 
                with the addition of the automation abillity
        @param  from: the address of the sender
        @param  id1: a hash of the info being hided
        @param  value: the amount being sent to the recipient side in the selected token
     */
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

    /** @notice hiddenDeposit - an ability to deposit without exposing the trx details
        @param  id1: a hash of the info being hided (sender address, token exc...)
     */
    function hiddenDeposit(bytes32 id1) external payable {
        bytes32 id = keccak256(abi.encode(msg.sender, msg.value, id1));
        require(s_htransfers[id] == 0, "SafeSwap: request exist");
        s_htransfers[id] = 0xffffffffffffffff;
        emit HDeposited(msg.sender, msg.value, id1);
    }

    /** @notice hiddenTimedDeposit - an ability to deposit without exposing the trx details 
                with an addition that has a timer in seconds
        @param  id1: a hash of the info being hided (sender address, token exc...)
        @param availableAt: sets a start time in seconds for when the deposite can happen
        @param expiresAt: sets an end time in seconds for when the deposite can happen
        @param autoRetrieveFees: the amount of fees that will be collected from the sender in case of retrieve
     */
    function hiddenTimedDeposit(
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

    /** @notice hiddenSwap - an ability to swap without exposing the trx details 
        @param  from: address of the recipient 
        @param  info: a struct (SwapRetrieveERC721) defimed above containing the following params:    
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
                    secretHash: a hash of the secret
        @param  secret: secret made up of passcode, private salt and public salt
        @param  v:
        @param  r:
        @param  s:
     */
    function hiddenSwap(
        address payable from,
        SwapInfo memory info,
        bytes calldata secret,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        bytes32 id1 = keccak256(
            abi.encode(
                HIDDEN_SWAP_TYPEHASH,
                from,
                msg.sender,
                info.token0,
                info.value0,
                info.fees0,
                info.token1,
                info.value1,
                info.fees1,
                info.secretHash
            )
        );
        require(
            ecrecover(
                keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, id1)),
                v,
                r,
                s
            ) == from,
            "SafeTransfer: wrong signature"
        );
        bytes32 id = keccak256(
            abi.encode(from, info.value0.add(info.fees0), id1)
        );
        uint256 tr = s_htransfers[id];
        require(tr > 0, "SafeSwap: request not exist");
        require(uint64(tr) > now, "SafeSwap: expired");
        require(uint64(tr >> 64) <= now, "SafeSwap: not available yet");
        require(keccak256(secret) == info.secretHash, "SafeSwap: wrong secret");
        delete s_htransfers[id];
        s_fees = s_fees.add(info.fees0).add(info.fees1);
        if (info.token0 == address(0)) {
            msg.sender.transfer(info.value0);
        } else {
            IERC20(info.token0).safeTransferFrom(from, msg.sender, info.value0);
        }
        if (info.token1 == address(0)) {
            require(
                msg.value == info.value1.add(info.fees1),
                "SafeSwap: value mismatch"
            );
            from.transfer(info.value1);
        } else {
            require(msg.value == info.fees1, "SafeSwap: value mismatch");
            IERC20(info.token1).safeTransferFrom(msg.sender, from, info.value1);
        }
        emit HSwapped(
            from,
            msg.sender,
            id1,
            info.token0,
            info.value0,
            info.token1,
            info.value1
        );
    }

    /** @notice hiddenSwapERC721 - an ability to swap without exposing the trx details for ERC721 tokens
        @param  from: address of the recipient
        @param  info: a struct (SwapRetrieveERC721) defimed above containing the following params:    
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
                    secretHash: a hash of the secret
        @param  secret: secret made up of passcode, private salt and public salt
        @param  v:
        @param  r:
        @param  s:
     */
    function hiddenSwapERC721(
        address payable from,
        SwapERC721Info memory info,
        bytes calldata secret,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        bytes32 id1 = _calcHiddenERC712Id1(from, info);
        require(
            ecrecover(
                keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, id1)),
                v,
                r,
                s
            ) == from,
            "SafeTransfer: wrong signature"
        );
        bytes32 id = keccak256(
            abi.encode(from, info.value0.add(info.fees0), id1)
        );
        uint256 tr = s_htransfers[id];
        require(tr > 0, "SafeSwap: request not exist");
        require(uint64(tr) > now, "SafeSwap: expired");
        require(uint64(tr >> 64) <= now, "SafeSwap: not available yet");
        require(keccak256(secret) == info.secretHash, "SafeSwap: wrong secret");
        delete s_htransfers[id];
        s_fees = s_fees.add(info.fees0).add(info.fees1);
        if (info.token0 == address(0)) {
            //ether to 721
            msg.sender.transfer(info.value0);
        } else {
            IERC721(info.token0).safeTransferFrom(
                from,
                msg.sender,
                info.value0,
                info.tokenData0
            );
        }
        if (info.token1 == address(0)) {
            //721 to ether
            require(
                msg.value == info.value1.add(info.fees1),
                "SafeSwap: value mismatch"
            );
            from.transfer(info.value1);
        } else {
            require(msg.value == info.fees1, "SafeSwap: value mismatch");
            IERC721(info.token1).safeTransferFrom(
                msg.sender,
                from,
                info.value1,
                info.tokenData1
            );
        }
        emit HERC721Swapped(
            from,
            msg.sender,
            id1,
            info.token0,
            info.value0,
            info.token1,
            info.value1
        );
    }

    /** @notice _calcHiddenERC712Id1 - private view function that calculates the id of the hidden ERC721 token swap
        @param  from: address of the recipient
        @param  info: a struct (SwapRetrieveERC721) defimed above containing the following params:   
    */
    function _calcHiddenERC712Id1(address from, SwapERC721Info memory info)
        private
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    HIDDEN_ERC721_SWAP_TYPEHASH,
                    from,
                    msg.sender,
                    info.token0,
                    info.value0,
                    info.tokenData0,
                    info.fees0,
                    info.token1,
                    info.value1,
                    info.tokenData1,
                    info.fees1,
                    info.secretHash
                )
            );
    }
}
