// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ISafeForERC1155.sol";

contract SafeForERC1155Core is AccessControl {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // keccak256("ACTIVATOR_ROLE");
  bytes32 public constant ACTIVATOR_ROLE =
    0xec5aad7bdface20c35bc02d6d2d5760df981277427368525d634f4e2603ea192;
  // keccak256("hiddenCollectERC1155(address from,address to,address token,uint256 tokenId,uint256 value,bytes tokenData,uint256 fees,bytes32 secretHash)");
  bytes32 public constant HIDDEN_ERC1155_COLLECT_TYPEHASH = 0x52305613f25d3721d925f16075dae9fc93bca4de629d7a176387fcddedf84bbe;

  // keccak256("hiddenCollectBatchERC1155(address from,address to,address token,uint256[] tokenIds,uint256[] values,bytes tokenData,uint256 fees,bytes32 secretHash)");
  bytes32 public constant HIDDEN_BATCH_ERC1155_COLLECT_TYPEHASH = 0xd51361a3e93bdd2b87d77c397f90c65da2916cfbeeef526d8d1ce71bc4817726;

  bytes32 public DOMAIN_SEPARATOR;
  uint256 public CHAIN_ID;
  bytes32 s_uid;
  uint256 s_fees;

  mapping(bytes32 => uint256) s_erc1155Transfers;
  mapping(bytes32 => uint256) s_htransfers;

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

  function uid() view external returns (bytes32) {
    return s_uid;
  }

  // ------------------------------- ERC-1155 transfer single--------------------------------
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
    require(uint64(tr) > now, "SafeTranfer: expired");
    require(uint64(tr >> 64) <= now, "SafeTranfer: not available yet");
    require(keccak256(secret) == secretHash, "SafeTransfer: wrong secret");
    delete s_erc1155Transfers[id];
    s_fees = s_fees.add(fees);
    IERC1155(token).safeTransferFrom(from, to, tokenId, value, tokenData);
    emit ERC1155Collected(token, from, to, id);
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

    function hiddenERC1155Collect(
      address token,
      address from,
      address payable to,
      uint256 tokenId,
      uint256 value,
      bytes memory tokenData,
      uint256 fees,
      bytes32 secretHash,
      bytes memory secret
    ) external onlyActivator {
      bytes32 id1 = keccak256(abi.encode(HIDDEN_ERC1155_COLLECT_TYPEHASH, from, to, token, tokenId, value, tokenData, fees, secretHash));
      bytes32 id = keccak256(abi.encode(from, value, id1));
      uint256 tr = s_htransfers[id];
      require(tr > 0, "SafeTransfer: request not exist");
      require(uint64(tr) > now, "SafeTranfer: expired");
      require(uint64(tr >> 64) <= now, "SafeTranfer: not available yet");
      require(keccak256(secret) == secretHash, "SafeTransfer: wrong secret");
      delete s_htransfers[id];
      s_fees = s_fees.add(fees);
      IERC1155(token).safeTransferFrom(from, to, tokenId, value, tokenData);
      emit ERC1155Collected(token, from, to, id);
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
    address to,
    TimedDepositBatchERC1155Info memory info,
    bytes calldata tokenData
  ) external payable {
    if(info.tokenIds.length == 1 && info.values.length == 1){
      timedDepositERC1155(info.token, to, info.tokenIds[0], info.values[0], tokenData, 
                info.fees, info.secretHash, info.availableAt, info.expiresAt, info.autoRetrieveFees);
    }
    else{
      require(msg.value == info.fees, "SafeTransfer: msg.value must match fees");
      require(info.fees >= info.autoRetrieveFees, "SafeTransfer: autoRetrieveFees exeed fees");
      require(to != msg.sender, "SafeTransfer: sender==recipient");
      require(info.expiresAt > now, "SafeTransfer: already expired");
      bytes32 id = keccak256(
        abi.encode(
          info.token,
          msg.sender,
          to,
          info.tokenIds,
          info.values,
          tokenData,
          info.fees,
          info.secretHash
        )
      );
      require(s_erc1155Transfers[id] == 0, "SafeTransfer: request exist");
      s_erc1155Transfers[id] = uint256(info.expiresAt) + uint256(info.availableAt << 64) + (uint256(info.autoRetrieveFees) << 128);
      emit TimedERC1155BatchTransferDeposited(
        info.token,
        msg.sender,
        to,
        info.tokenIds,
        info.values,
        info.fees,
        info.secretHash,
        info.availableAt,
        info.expiresAt,
        info.autoRetrieveFees
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

  function hiddenBatchERC1155Deposit(bytes32 id1) payable external
  {
      bytes32 id = keccak256(abi.encode(msg.sender, msg.value, id1));
      require(s_htransfers[id] == 0, "SafeTransfer: request exist"); 
      s_htransfers[id] = 0xffffffffffffffff;
      emit HiddenERC1155Deposited(msg.sender, msg.value, id1);
  }

  function hiddenBatchERC1155TimedDeposit(
        bytes32 id1,
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
    ) 
        payable external
    {
        require(msg.value >= autoRetrieveFees, "SafeTransfers: autoRetrieveFees exceed value");
        bytes32 id = keccak256(abi.encode(msg.sender, msg.value, id1));
        require(s_htransfers[id] == 0, "SafeTransfer: request exist");
        require(expiresAt > now, "SafeTransfer: already expired"); 
        s_htransfers[id] = uint256(expiresAt) + (uint256(availableAt) << 64) + (uint256(autoRetrieveFees) << 128);
        emit HiddenERC1155TimedDeposited(msg.sender, msg.value, id1, availableAt, expiresAt, autoRetrieveFees);
    }

    function hiddenBatchERC1155Retrieve(
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

    function hiddenBatchERC1155Collect(
      address payable to,
      address from,
      CollectBatchERC1155Info memory info
    ) external onlyActivator {
      bytes32 id1 = keccak256(abi.encode(HIDDEN_BATCH_ERC1155_COLLECT_TYPEHASH, from, to, info.token, info.tokenIds, info.values, info.tokenData, info.fees, info.secretHash));
      bytes32 id = keccak256(abi.encode(from, info.fees, id1));
      uint256 tr = s_htransfers[id];
      require(tr > 0, "SafeTransfer: request not exist");
      require(uint64(tr) > now, "SafeTranfer: expired");
      require(uint64(tr >> 64) <= now, "SafeTranfer: not available yet");
      require(keccak256(info.secret) == info.secretHash, "SafeTransfer: wrong secret");
      delete s_htransfers[id];
      s_fees = s_fees.add(info.fees);
      IERC1155(info.token).safeBatchTransferFrom(
        from,
        to,
        info.tokenIds,
        info.values,
        info.tokenData
      );
      emit ERC1155Collected(info.token, from, to, id);
    }
}