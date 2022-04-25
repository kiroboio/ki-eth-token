// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract SafeForERC1155 is AccessControl {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // keccak256("ACTIVATOR_ROLE");
  bytes32 public constant ACTIVATOR_ROLE =
    0xec5aad7bdface20c35bc02d6d2d5760df981277427368525d634f4e2603ea192;

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
    uint256 tr;
  }

  struct SwapERC1155Info {
    address token0;
    uint256[] tokenIds0;
    uint256[] values0;
    bytes tokenData0;
    uint256 fees0;
    address token1;
    uint256[] tokenIds1;
    uint256[] values1;
    bytes tokenData1;
    uint256 fees1;
    bytes32 secretHash;
  }

  struct CollectBatchERC1155Info {
    address token;
    uint256[] tokenIds;
    uint256[] values;
    bytes tokenData;
    uint256 fees;
    bytes32 secretHash;
    bytes secret;
  }

  struct SwapBatchERC1155ToERC20Info {
    address token0;
    uint256[] tokenIds0;
    uint256[] values0;
    bytes tokenData0;
    uint256 fees0;
    address token1;
    uint256 value1;
    uint256 fees1;
    bytes32 secretHash;
  }

  struct SwapERC20ToBatchERC1155Info {
    address token0;
    uint256 value0;
    uint256 fees0;
    address token1;
    uint256[] tokenIds1;
    uint256[] values1;
    bytes tokenData1;
    uint256 fees1;
    bytes32 secretHash;
  }

 /*  struct SwapETHToBatchERC1155Info {
    address token0;
    uint256 tokenId0;
    uint256 value0;
    uint256 fees0;
    address token1;
    uint256[] tokenIds1;
    uint256[] values1;
    bytes tokenData1;
    uint256 fees1;
    bytes32 secretHash;
  } */

  mapping(bytes32 => uint256) s_erc1155Transfers;
  mapping(bytes32 => uint256) s_swaps;
  mapping(bytes32 => uint256) s_htransfers;
  mapping(bytes32 => uint256) s_hswaps;

  string public constant NAME = "Kirobo Safe Transfer";
  string public constant VERSION = "1";
  uint8 public constant VERSION_NUMBER = 0x1;

  event Retrieved(
    address indexed from,
    address indexed to,
    bytes32 indexed id,
    uint256 value
  );

  event ERC1155TransferDeposited(
    address indexed token,
    address indexed from,
    address indexed to,
    uint256 tokenId,
    uint256 value,
    uint256 fees,
    bytes32 secretHash
  );

  event TimedERC1155TransferDeposited(
    address indexed token,
    address indexed from,
    address indexed to,
    uint256 tokenId,
    uint256 value,
    uint256 fees,
    bytes32 secretHash,
    uint64 availableAt,
    uint64 expiresAt,
    uint128 autoRetrieveFees
  );

  event ERC1155BatchTransferDeposited(
    address indexed token,
    address indexed from,
    address indexed to,
    uint256[] tokenIds,
    uint256[] values,
    uint256 fees,
    bytes32 secretHash
  );

  event TimedERC1155BatchTransferDeposited(
    address indexed token,
    address indexed from,
    address indexed to,
    uint256[] tokenIds,
    uint256[] values,
    uint256 fees,
    bytes32 secretHash,
    uint64 availableAt,
    uint64 expiresAt,
    uint128 autoRetrieveFees
  );

  event ERC1155TransferRetrieved(
    address indexed token,
    address indexed from,
    address indexed to,
    bytes32 id
  );

  event ERC721Retrieved(
    address indexed token,
    address indexed from,
    address indexed to,
    bytes32 id
  );

  event ERC1155BatchTransferRetrieved(
    address indexed token,
    address indexed from,
    address indexed to,
    uint256[] tokenIds,
    uint256[] values
  );

  event ERC1155Collected(
    address indexed token,
    address indexed from,
    address indexed to,
    bytes32 id
  );

  // event ERC1155BatchCollected(
  //   address indexed token,
  //   address indexed from,
  //   address indexed to,
  //   uint256[] tokenIds,
  //   uint256[] values
  // );

  event ERC1155SwapDeposited(
    address indexed from,
    address indexed to,
    address indexed token0,
    uint256[] tokenIds0,
    uint256[] values0,
    uint256 fees0,
    address token1,
    uint256[] tokenIds1,
    uint256[] values1,
    uint256 fees1,
    bytes32 secretHash
  );

  event TimedERC1155SwapDeposited(
    address indexed from,
    address indexed to,
    address indexed token0,
    uint256[] tokenIds0,
    uint256[] values0,
    uint256 fees0,
    address token1,
    uint256[] tokenIds1,
    uint256[] values1,
    uint256 fees1,
    bytes32 secretHash,
    uint64 availableAt,
    uint64 expiresAt,
    uint128 autoRetrieveFees
  );

  event ERC1155SwapRetrieved(
    address indexed from,
    address indexed to,
    address indexed token,
    bytes32 id
  );

  event ERC1155Swapped(
    address indexed from,
    address indexed to,
    address indexed token0,
    uint256[] tokenIds0,
    uint256[] values0,
    address token1,
    uint256[] tokenIds1,
    uint256[] values1,
    bytes32 id
  );

  event swapDepositERC1155ToERC20Event(
    address indexed from,
    address indexed to,
    address indexed token0,
    uint256[] tokenIds0,
    uint256[] values0,
    bytes tokenData0,
    uint256 fees0,
    address token1,
    uint256 value1,
    uint256 fees1,
    bytes32 secretHash
  );

  event TimedSwapDepositERC1155ToERC20Event(
    address indexed from,
    address indexed to,
    address indexed token0,
    uint256[] tokenIds0,
    uint256[] values0,
    bytes tokenData0,
    uint256 fees0,
    address token1,
    uint256 value1,
    uint256 fees1,
    bytes32 secretHash,
    uint64 availableAt,
    uint64 expiresAt,
    uint128 autoRetrieveFees
  );
  
  event swapDepositERC20ToERC1155Event(
    address indexed from,
    address indexed to,
    address indexed token0,
    uint256 value0,
    uint256 fees0,
    address token1,
    uint256[] tokenIds1,
    uint256[] values1,
    bytes tokenData1,
    uint256 fees1,
    bytes32 secretHash
  );

  event TimedSwapDepositERC20ToERC1155Event(
    address indexed from,
    address indexed to,
    address indexed token0,
    uint256 value0,
    uint256 fees0,
    address token1,
    uint256[] tokenIds1,
    uint256[] values1,
    bytes tokenData1,
    uint256 fees1,
    bytes32 secretHash,
    uint64 availableAt,
    uint64 expiresAt,
    uint128 autoRetrieveFees
  );

  /* event swapDepositETHToERC1155Event(
    address indexed from,
    address indexed to,
    address indexed token0,
    uint256 value0,
    uint256 fees0,
    address token1,
    uint256[] tokenIds1,
    uint256[] values1,
    uint256 fees1,
    bytes32 secretHash
  ); */

  event swapRetrieveERC1155ToERC20Event(
    address indexed from,
    address indexed to,
    address indexed token0,
    uint256[] tokenIds0,
    uint256[] values0,
    bytes tokenData0,
    bytes32 id
  );

  event swapRetrieveERC20ToERC1155Event(
    address indexed from,
    address indexed to,
    address indexed token0,
    uint256 value0,
    bytes32 id
  );

  event swapERC1155ToETHEvent(
    address indexed from,
    address indexed to,
    address indexed token0,
    uint256[] tokenIds0,
    uint256[] values0,
    address token1,
    uint256 value1,
    bytes32 id
  );

  event swapERC1155ToERC20Event(
    address indexed from,
    address indexed to,
    address indexed token0,
    uint256[] tokenIds0,
    uint256[] values0,
    bytes tokenData0,
    address token1,
    uint256 value1,
    bytes32 id
  );

  event swapERC20ToERC1155Event(
    address indexed from,
    address indexed to,
    address indexed token0,
    uint256 value0,
    address token1,
    uint256[] tokenIds1,
    uint256[] values1,
    bytes tokenData1,
    bytes32 id
  );

  event HiddenERC1155Deposited(
        address indexed from,
        uint256 value,
        bytes32 indexed id1
  );

  event HiddenERC1155TimedDeposited(
        address indexed from,
        uint256 value,
        bytes32 indexed id1,
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
    );

    event HiddenERC1155Retrieved(
        address indexed from,
        bytes32 indexed id1,
        uint256 value
    );

  /* event swapETHToERC1155Event(
    address indexed from,
    address indexed to,
    address indexed token0,
    uint256 value0,
    address token1,
    uint256[] tokenIds1,
    uint256[] values1,
    bytes32 id
  ); */

  modifier onlyActivator() {
    require(
      hasRole(ACTIVATOR_ROLE, msg.sender),
      "SafeTransfer: not an activator"
    );
    _;
  }

  constructor(address activator) public {
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

  /* function transferERC20(address token, address wallet, uint256 value) external onlyActivator() {
        IERC20(token).safeTransfer(wallet, value);
    }

    function transferERC721(address token, address wallet, uint256 tokenId, bytes calldata data) external onlyActivator() {
        IERC721(token).safeTransferFrom(address(this), wallet, tokenId, data);
    } */

  function transferFees(address payable wallet, uint256 value)
    external
    onlyActivator
  {
    s_fees = s_fees.sub(value);
    wallet.transfer(value);
  }

  function totalFees() external view returns (uint256) {
    return s_fees;
  }

  /* function uid() view external returns (bytes32) {
        return s_uid;
    } */

  // ------------------------------- ERC-1155 transfer single--------------------------------
  //0x5978e4630233612269aC217784A41fB3EA720d30
  function depositERC1155(
    address token,
    address to,
    uint256 tokenId,
    uint256 value,
    bytes calldata tokenData,
    uint256 fees,
    bytes32 secretHash
  ) public payable {
    require(msg.value == fees, "SafeTransfer: msg.value must match fees");
    require(to != msg.sender, "SafeTransfer: sender==recipient");
    bytes32 id = keccak256(
      abi.encode(
        token,
        msg.sender,
        to,
        tokenId,
        value,
        tokenData,
        fees,
        secretHash
      )
    );
    require(s_erc1155Transfers[id] == 0, "SafeTransfer: request exist");
    s_erc1155Transfers[id] = 0xffffffffffffffff;
    emit ERC1155TransferDeposited(
      token,
      msg.sender,
      to,
      tokenId,
      value,
      fees,
      secretHash
    );
  }

  function timedDepositERC1155(
    address token,
    address to,
    uint256 tokenId,
    uint256 value,
    bytes calldata tokenData,
    uint256 fees,
    bytes32 secretHash,
    uint64 availableAt,
    uint64 expiresAt,
    uint128 autoRetrieveFees
  ) public payable {
    require(msg.value == fees, "SafeTransfer: msg.value must match fees");
    require(fees >= autoRetrieveFees, "SafeTransfer: autoRetrieveFees exeed fees");
    require(to != msg.sender, "SafeTransfer: sender==recipient");
    require(expiresAt > now, "SafeTransfer: already expired");
    bytes32 id = keccak256(
      abi.encode(
        token,
        msg.sender,
        to,
        tokenId,
        value,
        tokenData,
        fees,
        secretHash
      )
    );
    require(s_erc1155Transfers[id] == 0, "SafeTransfer: request exist");
    s_erc1155Transfers[id] = uint256(expiresAt) + uint256(availableAt << 64) + (uint256(autoRetrieveFees) << 128);
    emit TimedERC1155TransferDeposited(
      token,
      msg.sender,
      to,
      tokenId,
      value,
      fees,
      secretHash,
      availableAt,
      expiresAt,
      autoRetrieveFees
    );
  }

  function retrieveERC1155(
    address token,
    address to,
    uint256 tokenId,
    uint256 value,
    bytes calldata tokenData,
    uint256 fees,
    bytes32 secretHash
  ) external {
    bytes32 id = keccak256(
      abi.encode(
        token,
        msg.sender,
        to,
        tokenId,
        value,
        tokenData,
        fees,
        secretHash
      )
    );
    require(s_erc1155Transfers[id] > 0, "SafeTransfer: request not exist");
    delete s_erc1155Transfers[id];
    msg.sender.transfer(fees);
    emit ERC1155TransferRetrieved(token, msg.sender, to, id);
  }

  function collectERC1155(
    address token,
    address from,
    address payable to,
    uint256 tokenId,
    uint256 value,
    bytes memory tokenData,
    uint256 fees,
    bytes32 secretHash,
    bytes memory secret
  ) public onlyActivator {
    bytes32 id = keccak256(
      abi.encode(token, from, to, tokenId, value, tokenData, fees, secretHash)
    );
    uint256 tr = s_erc1155Transfers[id];
    require(tr > 0, "SafeTransfer: request not exist");
    // require(uint64(tr) > now, "SafeTranfer: expired");
    // require(uint64(tr >> 64) <= now, "SafeTranfer: not available yet");
    require(keccak256(secret) == secretHash, "SafeTransfer: wrong secret");
    delete s_erc1155Transfers[id];
    s_fees = s_fees.add(fees);
    IERC1155(token).safeTransferFrom(from, to, tokenId, value, tokenData);
    emit ERC1155Collected(token, from, to, id);
    // emit ERC1155Collected(token, from, to, tokenId, value);
  }

  function autoRetrieveERC1155(
    address payable from,
    address token,
    address to,
    uint256 tokenId,
    uint256 value,
    bytes calldata tokenData,
    uint256 fees,
    bytes32 secretHash
  ) external {
    bytes32 id = keccak256(
      abi.encode(
        token,
        from,
        to,
        tokenId,
        value,
        tokenData,
        fees,
        secretHash
      )
    );
    uint256 tr = s_erc1155Transfers[id];
    require(tr > 0, "SafeTransfer: request not exist");
    require(uint64(tr) <= now, "SafeTranfer: not expired");
    delete s_erc1155Transfers[id];
    s_fees = s_fees + (tr>>128); // autoRetreive fees
    from.transfer(fees - (tr >> 128));
    emit ERC1155TransferRetrieved(token, from, to, id);
  }

  function hiddenERC1155Deposit(bytes32 id1) payable external
  {
      bytes32 id = keccak256(abi.encode(msg.sender, msg.value, id1));
      require(s_htransfers[id] == 0, "SafeTransfer: request exist"); 
      s_htransfers[id] = 0xffffffffffffffff;
      emit HiddenERC1155Deposited(msg.sender, msg.value, id1);
  }

  function hiddenERC1155TimedDeposit(
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
        emit HiddenERC1155TimedDeposited(msg.sender, msg.value, id1, availableAt, expiresAt, autoRetrieveFees);
    }

    function hiddenERC1155Retrieve(
        bytes32 id1,
        uint256 value
    )   
        external 
    {
        bytes32 id = keccak256(abi.encode(msg.sender, value, id1));
        require(s_htransfers[id]  > 0, "SafeTransfer: request not exist");
        delete s_htransfers[id];
        msg.sender.transfer(value);
        emit HiddenERC1155Retrieved(msg.sender, id1, value);
    }

  //------------------------------ERC-1155 batch transfer -----------------------------------------
  function depositBatchERC1155(
    address token,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata values,
    bytes calldata tokenData,
    uint256 fees,
    bytes32 secretHash
  ) external payable {
    if(tokenIds.length == 1 && values.length == 1){
      depositERC1155(token, to, tokenIds[0], values[0], tokenData, fees, secretHash);
    }
    else{
      require(msg.value == fees, "SafeTransfer: msg.value must match fees");
      require(to != msg.sender, "SafeTransfer: sender==recipient");
      bytes32 id = keccak256(
        abi.encode(
          token,
          msg.sender,
          to,
          tokenIds,
          values,
          tokenData,
          fees,
          secretHash
        )
      );
      require(s_erc1155Transfers[id] == 0, "SafeTransfer: request exist");
      s_erc1155Transfers[id] = 0xffffffffffffffff;
      emit ERC1155BatchTransferDeposited(
        token,
        msg.sender,
        to,
        tokenIds,
        values,
        fees,
        secretHash
      );
    }
  }

  function TimedDepositBatchERC1155(
    address token,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata values,
    bytes calldata tokenData,
    uint256 fees,
    bytes32 secretHash,
    uint64 availableAt,
    uint64 expiresAt,
    uint128 autoRetrieveFees
  ) external payable {
    if(tokenIds.length == 1 && values.length == 1){
      timedDepositERC1155(token, to, tokenIds[0], values[0], tokenData, 
                fees, secretHash, availableAt, expiresAt, autoRetrieveFees);
    }
    else{
      require(msg.value == fees, "SafeTransfer: msg.value must match fees");
      require(fees >= autoRetrieveFees, "SafeTransfer: autoRetrieveFees exeed fees");
      require(to != msg.sender, "SafeTransfer: sender==recipient");
      require(expiresAt > now, "SafeTransfer: already expired");
      bytes32 id = keccak256(
        abi.encode(
          token,
          msg.sender,
          to,
          tokenIds,
          values,
          tokenData,
          fees,
          secretHash
        )
      );
      require(s_erc1155Transfers[id] == 0, "SafeTransfer: request exist");
      s_erc1155Transfers[id] = uint256(expiresAt) + uint256(availableAt << 64) + (uint256(autoRetrieveFees) << 128);
      emit TimedERC1155BatchTransferDeposited(
        token,
        msg.sender,
        to,
        tokenIds,
        values,
        fees,
        secretHash,
        availableAt,
        expiresAt,
        autoRetrieveFees
      );
    }
  }

  function retrieveBatchERC1155(
    address token,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata values,
    bytes calldata tokenData,
    uint256 fees,
    bytes32 secretHash
  ) external {
    bytes32 id = keccak256(
      abi.encode(
        token,
        msg.sender,
        to,
        tokenIds,
        values,
        tokenData,
        fees,
        secretHash
      )
    );
    require(s_erc1155Transfers[id] > 0, "SafeTransfer: request not exist");
    delete s_erc1155Transfers[id];
    msg.sender.transfer(fees);
    emit ERC1155BatchTransferRetrieved(token, msg.sender, to, tokenIds, values);
  }

  function collectBatchERC1155(
    address payable to,
    address from,
    CollectBatchERC1155Info memory info
  ) external onlyActivator {
    if(info.tokenIds.length == 1 && info.values.length == 1){
      collectERC1155(info.token, from, to, info.tokenIds[0], info.values[0], 
      info.tokenData, info.fees, info.secretHash, info.secret);
    }
    else{
      bytes32 id = keccak256(
        abi.encode(
          info.token,
          from,
          to,
          info.tokenIds,
          info.values,
          info.tokenData,
          info.fees,
          info.secretHash
        )
      );
      uint256 tr = s_erc1155Transfers[id];
      require(tr > 0, "SafeTransfer: request not exist");
      require(uint64(tr) > now, "SafeTranfer: expired");
      require(uint64(tr >> 64) <= now, "SafeTranfer: not available yet");
      require(
        keccak256(info.secret) == info.secretHash,
        "SafeTransfer: wrong secret"
      );
      delete s_erc1155Transfers[id];
      s_fees = s_fees.add(info.fees);
      IERC1155(info.token).safeBatchTransferFrom(
        from,
        to,
        info.tokenIds,
        info.values,
        info.tokenData
      );
      emit ERC1155Collected(
        info.token,
        from,
        to,
        id
      );
    }
  }

  function autoRetrieveBatchERC1155(
    address payable from,
    address token,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata values,
    bytes calldata tokenData,
    uint256 fees,
    bytes32 secretHash
  ) external {
    bytes32 id = keccak256(
      abi.encode(
        token,
        from,
        to,
        tokenIds,
        values,
        tokenData,
        fees,
        secretHash
      )
    );
    uint256 tr = s_erc1155Transfers[id];
    require(tr > 0, "SafeTransfer: request not exist");
    require(uint64(tr) <= now, "SafeTranfer: not expired");
    delete s_erc1155Transfers[id];
    s_fees = s_fees + (tr>>128); // autoRetreive fees
    from.transfer(fees - (tr >> 128));
    emit ERC1155BatchTransferRetrieved(token, from, to, tokenIds, values);
  }

  function encodeObject(
    address a,
    uint256[] memory arr1,
    uint256[] memory arr2,
    bytes memory b,
    uint256 c
  ) internal pure returns (bytes memory) {
    return abi.encode(a, arr1, arr2, b, c);
  }

  // ----------------------- swap - batch ERC1155 <--> ETH/721 -------------------------------------------
  //0x0Fc471ed8ed3a01Ab11E1F7A3A3d71F4bCEf39E7
  function swapDepositERC1155(address payable to, SwapERC1155Info memory info)
    external
    payable
  {
    if (info.token0 == address(0)) {
      //eth to 1155
      require(
        info.token0 != info.token1,
        "SafeSwap: try to swap ether and ether"
      );
      require(
        msg.value == info.values0[0].add(info.fees0),
        "SafeSwap: value mismatch"
      );
      require(info.values1[0] > 0, "SafeSwap: no value for ERC1155 token");
    } else if (info.token1 == address(0)) {
      //1155 to eth
      require(msg.value == info.fees0, "SafeSwap: value mismatch");
      require(info.values0[0] > 0, "SafeSwap: no value for ERC1155 token");
      require(info.values1[0] > 0, "SafeSwap: no value for ETH");
    } else if (info.values0[0] == 0) {
      //721 to 1155
      require(msg.value == info.fees0, "SafeSwap: value mismatch");
      require(info.values1[0] > 0, "SafeSwap: no value for ERC1155 token");
    } else if (info.values1[0] == 0) {
      //1155 to 721
      require(msg.value == info.fees0, "SafeSwap: value mismatch");
      require(info.values0[0] > 0, "SafeSwap: no value");
    } else {
      //1155 to 1155
      require(msg.value == info.fees0, "SafeSwap: value mismatch");
      require(info.values0[0] > 0, "SafeSwap: no value for ERC1155 token");
      require(info.values1[0] > 0, "SafeSwap: no value for ERC1155 token");
    }
    require(to != msg.sender, "SafeSwap: sender==recipient");
    bytes32 id = keccak256(
      abi.encode(
        msg.sender,
        to,
        encodeObject(
          info.token0,
          info.tokenIds0,
          info.values0,
          info.tokenData0,
          info.fees0
        ),
        encodeObject(
          info.token1,
          info.tokenIds1,
          info.values1,
          info.tokenData1,
          info.fees1
        ),
        info.secretHash
      )
    );
    require(s_swaps[id] == 0, "SafeSwap: request exist");
    s_swaps[id] = 0xffffffffffffffff; // expiresAt: max, AvailableAt: 0, autoRetrieveFees: 0
    emit ERC1155SwapDeposited(
      msg.sender,
      to,
      info.token0,
      info.tokenIds0,
      info.values0,
      info.fees0,
      info.token1,
      info.tokenIds1,
      info.values1,
      info.fees1,
      info.secretHash
    );
  }

  function swapDepositERC1155(
    address payable to, 
    SwapERC1155Info memory info,
    uint64 availableAt,
    uint64 expiresAt,
    uint128 autoRetrieveFees
  )
    external
    payable
  {
    require(info.fees0 >= autoRetrieveFees,"SafeSwap: autoRetrieveFees exeed fees");
    require(expiresAt > now, "SafeSwap: already expired");
    if (info.token0 == address(0)) {
      //eth to 1155
      require(
        info.token0 != info.token1,
        "SafeSwap: try to swap ether and ether"
      );
      require(
        msg.value == info.values0[0].add(info.fees0),
        "SafeSwap: value mismatch"
      );
      require(info.values1[0] > 0, "SafeSwap: no value for ERC1155 token");
    } else if (info.token1 == address(0)) {
      //1155 to eth
      require(msg.value == info.fees0, "SafeSwap: value mismatch");
      require(info.values0[0] > 0, "SafeSwap: no value for ERC1155 token");
      require(info.values1[0] > 0, "SafeSwap: no value for ETH");
    } else if (info.values0[0] == 0) {
      //721 to 1155
      require(msg.value == info.fees0, "SafeSwap: value mismatch");
      require(info.values1[0] > 0, "SafeSwap: no value for ERC1155 token");
    } else if (info.values1[0] == 0) {
      //1155 to 721
      require(msg.value == info.fees0, "SafeSwap: value mismatch");
      require(info.values0[0] > 0, "SafeSwap: no value");
    } else {
      //1155 to 1155
      require(msg.value == info.fees0, "SafeSwap: value mismatch");
      require(info.values0[0] > 0, "SafeSwap: no value for ERC1155 token");
      require(info.values1[0] > 0, "SafeSwap: no value for ERC1155 token");
    }
    require(to != msg.sender, "SafeSwap: sender==recipient");
    bytes32 id = keccak256(
      abi.encode(
        msg.sender,
        to,
        encodeObject(
          info.token0,
          info.tokenIds0,
          info.values0,
          info.tokenData0,
          info.fees0
        ),
        encodeObject(
          info.token1,
          info.tokenIds1,
          info.values1,
          info.tokenData1,
          info.fees1
        ),
        info.secretHash
      )
    );
    require(s_swaps[id] == 0, "SafeSwap: request exist");
    s_swaps[id] = uint256(expiresAt) + uint256(availableAt << 64) + (uint256(autoRetrieveFees) << 128);
    emit TimedERC1155SwapDeposited(
      msg.sender,
      to,
      info.token0,
      info.tokenIds0,
      info.values0,
      info.fees0,
      info.token1,
      info.tokenIds1,
      info.values1,
      info.fees1,
      info.secretHash,
      availableAt,
      expiresAt,
      autoRetrieveFees
    );
  }

  function swapRetrieveERC1155(address to, SwapERC1155Info memory info)
    external
  {
    bytes32 id = keccak256(
      abi.encode(
        msg.sender,
        to,
        encodeObject(
          info.token0,
          info.tokenIds0,
          info.values0,
          info.tokenData0,
          info.fees0
        ),
        encodeObject(
          info.token1,
          info.tokenIds1,
          info.values1,
          info.tokenData1,
          info.fees1
        ),
        info.secretHash
      )
    );
    require(s_swaps[id] > 0, "SafeSwap: request not exist");
    delete s_swaps[id];
    uint256 valueToSend;
    if (info.token0 == address(0)) {
      valueToSend = info.values0[0].add(info.fees0);
    } else {
      valueToSend = info.fees0;
    }
    msg.sender.transfer(valueToSend);
    if (info.token0 == address(0)) {
      emit Retrieved(msg.sender, to, id, valueToSend);
    } else if (info.values0[0] == 0) {
      //retrieve 721
      emit ERC721Retrieved(info.token0, msg.sender, to, id);
    } else {
      emit ERC1155SwapRetrieved(
        msg.sender,
        to,
        info.token0,
        id
      );
    }
  }

  function swapERC1155(
    address payable from,
    SwapERC1155Info memory info,
    bytes calldata secret
  ) external payable {
    bytes32 id = keccak256(
      abi.encode(
        from,
        msg.sender,
        encodeObject(
          info.token0,
          info.tokenIds0,
          info.values0,
          info.tokenData0,
          info.fees0
        ),
        encodeObject(
          info.token1,
          info.tokenIds1,
          info.values1,
          info.tokenData1,
          info.fees1
        ),
        info.secretHash
      )
    );
    uint256 tr = s_swaps[id];
    require(tr > 0, "SafeSwap: request not exist");
    require(uint64(tr) > now, "SafeSwap: expired");
    require(uint64(tr >> 64) <= now, "SafeSwap: not available yet");
    require(keccak256(secret) == info.secretHash, "SafeSwap: wrong secret");
    delete s_swaps[id];
    s_fees = s_fees.add(info.fees0).add(info.fees1);
    if (info.token0 == address(0)) {
      //ether to 1155
      msg.sender.transfer(info.values0[0]);
    } else if (info.values0[0] == 0) {
      //721 to 1155
      IERC721(info.token0).safeTransferFrom(
        from,
        msg.sender,
        info.tokenIds0[0],
        info.tokenData0
      );
    } else {
      //1155 to...
      IERC1155(info.token0).safeBatchTransferFrom(
        from,
        msg.sender,
        info.tokenIds0,
        info.values0,
        info.tokenData0
      );
    }
    if (info.token1 == address(0)) {
      //1155 to ether
      require(
        msg.value == info.values1[0].add(info.fees1),
        "SafeSwap: value mismatch"
      );
      from.transfer(info.values1[0]);
    } else if (info.values1[0] == 0) {
      //1155 to 721
      IERC721(info.token1).safeTransferFrom(
        from,
        msg.sender,
        info.tokenIds1[0],
        info.tokenData1
      );
    } else {
      //... to 1155
      require(msg.value == info.fees1, "SafeSwap: value mismatch");
      IERC1155(info.token1).safeBatchTransferFrom(
        msg.sender,
        from,
        info.tokenIds1,
        info.values1,
        info.tokenData1
      );
    }
    emit ERC1155Swapped(
      from,
      msg.sender,
      info.token0,
      info.tokenIds0,
      info.values0,
      info.token1,
      info.tokenIds1,
      info.values1,
      id
    );
  }

  function autoSwapRetrieveERC1155(
    address payable from, 
    address to, 
    SwapERC1155Info memory info)
    external
  {
    bytes32 id = keccak256(
      abi.encode(
        from,
        to,
        encodeObject(
          info.token0,
          info.tokenIds0,
          info.values0,
          info.tokenData0,
          info.fees0
        ),
        encodeObject(
          info.token1,
          info.tokenIds1,
          info.values1,
          info.tokenData1,
          info.fees1
        ),
        info.secretHash
      )
    );
    uint256 tr = s_swaps[id];
    require(tr > 0, "SafeSwap: request not exist");
    require(uint64(tr) <= now, "SafeSwap: not expired");
    delete s_swaps[id];
    s_fees = s_fees + (tr >> 128); // autoRetreive fees
    uint256 valueToSend;
    if (info.token0 == address(0)) {
      valueToSend = info.values0[0].add(info.fees0).sub(tr >> 128);
    } else {
      valueToSend = info.fees0 - (tr >> 128);
    }
    from.transfer(valueToSend);
    if (info.token0 == address(0)) {
      emit Retrieved(from, to, id, valueToSend);
    } else if (info.values0[0] == 0) {
      //retrieve 721
      emit ERC721Retrieved(info.token0, from, to, id);
    } else {
      emit ERC1155SwapRetrieved(
        from,
        to,
        info.token0,
        id
      );
    }
  }

  // ------------------------ swap batch ERC-1155 <-> ERC20 -----------------

  function swapDepositERC1155ToERC20(
    address payable to,
    SwapBatchERC1155ToERC20Info memory info
  ) external payable {
    require(msg.value == info.fees0, "SafeSwap: value mismatch");
    require(to != msg.sender, "SafeSwap: sender==recipient");
    bytes32 id = keccak256(
      abi.encode(
        msg.sender,
        to,
        info.token0,
        info.tokenIds0,
        info.values0,
        info.tokenData0,
        info.fees0,
        info.token1,
        info.value1,
        info.fees1,
        info.secretHash
      )
    );
    require(s_swaps[id] == 0, "SafeSwap: request exist");
    s_swaps[id] = 0xffffffffffffffff; // expiresAt: max, AvailableAt: 0, autoRetrieveFees: 0
    emit swapDepositERC1155ToERC20Event(
      msg.sender,
      to,
      info.token0,
      info.tokenIds0,
      info.values0,
      info.tokenData0,
      info.fees0,
      info.token1,
      info.value1,
      info.fees1,
      info.secretHash
    );
  }

  function swapDepositERC1155ToERC20(
    address payable to,
    SwapBatchERC1155ToERC20Info memory info,
    uint64 availableAt,
    uint64 expiresAt,
    uint128 autoRetrieveFees
  ) external payable {
    require(msg.value == info.fees0, "SafeSwap: value mismatch");
    require(to != msg.sender, "SafeSwap: sender==recipient");
    require(info.fees0 >= autoRetrieveFees,"SafeSwap: autoRetrieveFees exeed fees");
    require(expiresAt > now, "SafeSwap: already expired");
    bytes32 id = keccak256(
      abi.encode(
        msg.sender,
        to,
        info.token0,
        info.tokenIds0,
        info.values0,
        info.tokenData0,
        info.fees0,
        info.token1,
        info.value1,
        info.fees1,
        info.secretHash
      )
    );
    require(s_swaps[id] == 0, "SafeSwap: request exist");
    s_swaps[id] = uint256(expiresAt) + uint256(availableAt << 64) + (uint256(autoRetrieveFees) << 128);
    emit TimedSwapDepositERC1155ToERC20Event(
      msg.sender,
      to,
      info.token0,
      info.tokenIds0,
      info.values0,
      info.tokenData0,
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

  function swapRetrieveERC1155ToERC20(
    address to,
    SwapBatchERC1155ToERC20Info memory info
  ) external {
    bytes32 id = keccak256(
      abi.encode(
        msg.sender,
        to,
        info.token0,
        info.tokenIds0,
        info.values0,
        info.tokenData0,
        info.fees0,
        info.token1,
        info.value1,
        info.fees1,
        info.secretHash
      )
    );
    require(s_swaps[id] > 0, "SafeSwap: request not exist");
    delete s_swaps[id];
    uint256 valueToSend = info.fees0;
    msg.sender.transfer(valueToSend);
    emit swapRetrieveERC1155ToERC20Event(
      msg.sender,
      to,
      info.token0,
      info.tokenIds0,
      info.values0,
      info.tokenData0,
      id
    );
  }

  function swapERC1155ToERC20(
    address payable from,
    SwapBatchERC1155ToERC20Info memory info,
    bytes calldata secret
  ) external payable {
    bytes32 id = keccak256(
      abi.encode(
        from,
        msg.sender,
        info.token0,
        info.tokenIds0,
        info.values0,
        info.tokenData0,
        info.fees0,
        info.token1,
        info.value1,
        info.fees1,
        info.secretHash
      )
    );
    uint256 tr = s_swaps[id];
    require(tr > 0, "SafeSwap: request not exist");
    require(uint64(tr) > now, "SafeSwap: expired");
    require(uint64(tr >> 64) <= now, "SafeSwap: not available yet");
    require(keccak256(secret) == info.secretHash, "SafeSwap: wrong secret");
    require(msg.value == info.fees1, "SafeSwap: value mismatch");
    delete s_swaps[id];
    s_fees = s_fees.add(info.fees0).add(info.fees1);
    IERC1155(info.token0).safeBatchTransferFrom(
      from,
      msg.sender,
      info.tokenIds0,
      info.values0,
      info.tokenData0
    );
    IERC20(info.token1).safeTransferFrom(msg.sender, from, info.value1);
    emit swapERC1155ToERC20Event(
      from,
      msg.sender,
      info.token0,
      info.tokenIds0,
      info.values0,
      info.tokenData0,
      info.token1,
      info.value1,
      id
    );
  }

  function autoSwapRetrieveERC1155ToERC20(
    address payable from,
    address to,
    SwapBatchERC1155ToERC20Info memory info
  ) external {
    bytes32 id = keccak256(
      abi.encode(
        from,
        to,
        info.token0,
        info.tokenIds0,
        info.values0,
        info.tokenData0,
        info.fees0,
        info.token1,
        info.value1,
        info.fees1,
        info.secretHash
      )
    );
    uint256 tr = s_swaps[id];
    require(tr > 0, "SafeSwap: request not exist");
    require(uint64(tr) <= now, "SafeSwap: not expired");
    delete s_swaps[id];
    s_fees = s_fees + (tr >> 128); // autoRetreive fees
    uint256 valueToSend = info.fees0 - (tr >> 128);
    from.transfer(valueToSend);
    emit swapRetrieveERC1155ToERC20Event(
      from,
      to,
      info.token0,
      info.tokenIds0,
      info.values0,
      info.tokenData0,
      id
    );
  }

  // ------------------------ swap ERC20 <-> batch ERC-1155  -----------------

  function swapDepositERC20ToERC1155(
    address payable to,
    SwapERC20ToBatchERC1155Info memory info
  ) external payable {
    require(msg.value == info.fees0, "SafeSwap: value mismatch");
    require(to != msg.sender, "SafeSwap: sender==recipient");
    bytes32 id = keccak256(
      abi.encode(
        msg.sender,
        to,
        info.token0,
        info.value0,
        info.fees0,
        info.token1,
        info.tokenIds1,
        info.values1,
        info.tokenData1,
        info.fees1,
        info.secretHash
      )
    );
    require(s_swaps[id] == 0, "SafeSwap: request exist");
    s_swaps[id] = 0xffffffffffffffff; // expiresAt: max, AvailableAt: 0, autoRetrieveFees: 0
    emit swapDepositERC20ToERC1155Event(
      msg.sender,
      to,
      info.token0,
      info.value0,
      info.fees0,
      info.token1,
      info.tokenIds1,
      info.values1,
      info.tokenData1,
      info.fees1,
      info.secretHash
    );
  }

  function TimedSwapDepositERC20ToERC1155(
    address payable to,
    SwapERC20ToBatchERC1155Info memory info,
    uint64 availableAt,
    uint64 expiresAt,
    uint128 autoRetrieveFees
  ) external payable {
    require(msg.value == info.fees0, "SafeSwap: value mismatch");
    require(to != msg.sender, "SafeSwap: sender==recipient");
    require(info.fees0 >= autoRetrieveFees,"SafeSwap: autoRetrieveFees exeed fees");
    require(expiresAt > now, "SafeSwap: already expired");
    bytes32 id = keccak256(
      abi.encode(
        msg.sender,
        to,
        info.token0,
        info.value0,
        info.fees0,
        info.token1,
        info.tokenIds1,
        info.values1,
        info.tokenData1,
        info.fees1,
        info.secretHash
      )
    );
    require(s_swaps[id] == 0, "SafeSwap: request exist");
    s_swaps[id] = uint256(expiresAt) + uint256(availableAt << 64) + (uint256(autoRetrieveFees) << 128);
    emit TimedSwapDepositERC20ToERC1155Event(
      msg.sender,
      to,
      info.token0,
      info.value0,
      info.fees0,
      info.token1,
      info.tokenIds1,
      info.values1,
      info.tokenData1,
      info.fees1,
      info.secretHash,
      availableAt,
      expiresAt,
      autoRetrieveFees
    );
  }

  function swapRetrieveERC20ToERC1155(
    address to,
    SwapERC20ToBatchERC1155Info memory info
  ) external {
    bytes32 id = keccak256(
      abi.encode(
        msg.sender,
        to,
        info.token0,
        info.value0,
        info.fees0,
        info.token1,
        info.tokenIds1,
        info.values1,
        info.tokenData1,
        info.fees1,
        info.secretHash
      )
    );
    require(s_swaps[id] > 0, "SafeSwap: request not exist");
    delete s_swaps[id];
    uint256 valueToSend = info.fees0;
    msg.sender.transfer(valueToSend);
    emit swapRetrieveERC20ToERC1155Event(
      msg.sender,
      to,
      info.token0,
      info.value0,
      id
    );
  }

  function swapERC20ToERC1155(
    address payable from,
    SwapERC20ToBatchERC1155Info memory info,
    bytes calldata secret
  ) external payable {
    bytes32 id = keccak256(
      abi.encode(
        from,
        msg.sender,
        info.token0,
        info.value0,
        info.fees0,
        info.token1,
        info.tokenIds1,
        info.values1,
        info.tokenData1,
        info.fees1,
        info.secretHash
      )
    );
    uint256 tr = s_swaps[id];
    require(tr > 0, "SafeSwap: request not exist");
    require(uint64(tr) > now, "SafeSwap: expired");
    require(uint64(tr >> 64) <= now, "SafeSwap: not available yet");
    require(keccak256(secret) == info.secretHash, "SafeSwap: wrong secret");
    require(msg.value == info.fees1, "SafeSwap: value mismatch");
    delete s_swaps[id];
    s_fees = s_fees.add(info.fees0).add(info.fees1);
    IERC20(info.token0).safeTransferFrom(from, msg.sender, info.value0);
    IERC1155(info.token1).safeBatchTransferFrom(
      msg.sender,
      from,
      info.tokenIds1,
      info.values1,
      info.tokenData1
    );
    emit swapERC20ToERC1155Event(
      from,
      msg.sender,
      info.token0,
      info.value0,
      info.token1,
      info.tokenIds1,
      info.values1,
      info.tokenData1,
      id
    );
  }

  function autoSwapRetrieveERC20ToERC1155(
    address payable from,
    address to,
    SwapERC20ToBatchERC1155Info memory info
  ) external {
    bytes32 id = keccak256(
      abi.encode(
        from,
        to,
        info.token0,
        info.value0,
        info.fees0,
        info.token1,
        info.tokenIds1,
        info.values1,
        info.tokenData1,
        info.fees1,
        info.secretHash
      )
    );
    uint256 tr = s_swaps[id];
    require(tr > 0, "SafeSwap: request not exist");
    require(uint64(tr) <= now, "SafeSwap: not expired");
    delete s_swaps[id];
    s_fees = s_fees + (tr >> 128); // autoRetreive fees
    uint256 valueToSend = info.fees0 - (tr >> 128);
    from.transfer(valueToSend);
    emit swapRetrieveERC20ToERC1155Event(
      from,
      to,
      info.token0,
      info.value0,
      id
    );
  }

  //------------------- swap ETH <-> batch 1155 ---------------------
/*   function swapDepositETHToERC1155(
    address payable to,
    SwapETHToBatchERC1155Info memory info
  ) external payable {
    //eth to 1155
    require(
      info.token0 != info.token1,
      "SafeSwap: try to swap ether and ether"
    );
    require(
      msg.value == info.value0.add(info.fees0),
      "SafeSwap: value mismatch"
    );
    require(to != msg.sender, "SafeSwap: sender==recipient");
    bytes32 id = keccak256(
      abi.encode(
        msg.sender,
        to,
        info.token0,
        info.tokenId0,
        info.value0,
        info.fees0,
        info.token1,
        info.tokenIds1,
        info.values1,
        info.tokenData1,
        info.fees1,
        info.secretHash
      )
    );
    require(s_swaps[id] == 0, "SafeSwap: request exist");
    s_swaps[id] = 0xffffffffffffffff; // expiresAt: max, AvailableAt: 0, autoRetrieveFees: 0
    emit swapDepositETHToERC1155Event(
      msg.sender,
      to,
      info.token0,
      info.value0,
      info.fees0,
      info.token1,
      info.tokenIds1,
      info.values1,
      info.fees1,
      info.secretHash
    );
  }

  function swapRetrieveETHToERC1155(
    address to,
    SwapETHToBatchERC1155Info memory info
  ) external {
    bytes32 id = keccak256(
      abi.encode(
        msg.sender,
        to,
        info.token0,
        info.tokenId0,
        info.value0,
        info.fees0,
        info.token1,
        info.tokenIds1,
        info.values1,
        info.tokenData1,
        info.fees1,
        info.secretHash
      )
    );
    require(s_swaps[id] > 0, "SafeSwap: request not exist");
    delete s_swaps[id];
    uint256 valueToSend;
    valueToSend = info.value0.add(info.fees0);
    msg.sender.transfer(valueToSend);
    emit Retrieved(msg.sender, to, id, valueToSend);
  }

  function swapETHToERC1155(
    address payable from,
    SwapETHToBatchERC1155Info memory info,
    bytes calldata secret
  ) external payable {
    bytes32 id = keccak256(
      abi.encode(
        from,
        msg.sender,
        info.token0,
        info.tokenId0,
        info.value0,
        info.fees0,
        info.token1,
        info.tokenIds1,
        info.values1,
        info.tokenData1,
        info.fees1,
        info.secretHash
      )
    );
    uint256 tr = s_swaps[id];
    require(tr > 0, "SafeSwap: request not exist");
    require(uint64(tr) > now, "SafeSwap: expired");
    require(uint64(tr >> 64) <= now, "SafeSwap: not available yet");
    require(keccak256(secret) == info.secretHash, "SafeSwap: wrong secret");
    delete s_swaps[id];
    s_fees = s_fees.add(info.fees0).add(info.fees1);
    msg.sender.transfer(info.value0);
    require(msg.value == info.fees1, "SafeSwap: value mismatch");
    IERC1155(info.token1).safeBatchTransferFrom(
      msg.sender,
      from,
      info.tokenIds1,
      info.values1,
      info.tokenData1
    );
    emit swapETHToERC1155Event(
      from,
      msg.sender,
      info.token0,
      info.value0,
      info.token1,
      info.tokenIds1,
      info.values1,
      id
    );
  } */
}

//need to add :
//swap 1155 with 721
//swap 721 with 1155
// to batch1155
//batch swap 1155 to 721
//batch swap 721 to 1155
//batch swap eth to 1155
//swap batch1155 with batch1155
//hidden transfer
//hiddem batch transfer
//hidden swap - eth to 1155
//hidden swap - 11
