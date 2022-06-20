// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ISafeForERC1155.sol";

contract SafeForERC1155 is AccessControl {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  //keccak256("HIDDEN_SWAP_ERC1155_TYPEHASH(address from,address to,bytes memory sideA,bytes memory sideB,bytes32 secretHash)");
  bytes32 public constant HIDDEN_SWAP_ERC1155_TYPEHASH = 0x5def028ebfda9e7c902eeb540d78a84b6b40defc4aa193fb9039fdd8d09255a4;

  //keccak256("HIDDEN_SWAP_ERC1155_TYPEHASH(address from,address to,address token0,uint256 value0,uint256 fees0,address token1,uint256[] tokenIds1,uint256[] values1,bytes tokenData1,uint256 fees1,bytes32 secretHash)");
  bytes32 public constant HIDDEN_ERC20_TO_ERC1155_SWAP = 0x5c63c8b83e3cbed2a40bd68b993c3f69622c8b52ff80ef2eb730c1891ab70bfa;

  //keccak256("HIDDEN_ERC1155_TO_ERC20_SWAP(address from,address to,address token0,uint256[] tokenIds0,uint256[] values0,bytes tokenData0,uint256 fees0,address token1,uint256 value1,uint256 fees1,bytes32 secretHash)");
  bytes32 public constant HIDDEN_ERC1155_TO_ERC20_SWAP = 0x445e79546b82e242bfb84f5a7c4f59342a0c9e8b523e6e7b8c9dcd4c5ca272d0;

  
  bytes32 public DOMAIN_SEPARATOR;
  uint256 public CHAIN_ID;
  bytes32 s_uid;
  uint256 s_fees;

  mapping(bytes32 => uint256) s_swaps;
  mapping(bytes32 => uint256) s_hswaps;

  string public constant NAME = "Kirobo Safe Transfer";
  string public constant VERSION = "1";
  uint8 public constant VERSION_NUMBER = 0x1;
  //address public immutable SAFE_FOR_ERC_1155_CORE;

  event ERC721Retrieved(
    address indexed token,
    address indexed from,
    address indexed to,
    bytes32 id
  );

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

  event Retrieved(
      address indexed from,
      address indexed to,
      bytes32 indexed id,
      uint256 value
  );

  event HiddenERC1155SwapDeposited(
    address indexed from,
    uint256 value,
    bytes32 indexed id1
  );

  event HiddenERC1155SwapTimedDeposited(
        address indexed from,
        uint256 value,
        bytes32 indexed id1,
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
    );

  event HiddenERC1155SwapRetrieved(
        address indexed from,
        bytes32 indexed id1,
        uint256 value
    );

  constructor(address core) public {
  // SAFE_FOR_ERC_1155_CORE = core;

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

  function totalFees() external view returns (uint256) {
    return s_fees;
  }

  function uid() view external returns (bytes32) {
        return s_uid;
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

  // ----------------------- swap - batch ERC1155 <--> ETH/721//batch 1155 -------------------------------------------
  function swapDepositERC1155(address payable to, SwapERC1155Info memory info)
    external
    payable
  {
    if (info.token0 == address(0)) {
      //eth to 1155
      require(info.token0 != info.token1,"SafeSwap: try to swap ether and ether");
      require(msg.value == info.values0[0].add(info.fees0),"SafeSwap: value mismatch");
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

  function timedSwapDepositERC1155(
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
        msg.sender,
        from,
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

  function hiddenBatchERC1155SwapDeposit(bytes32 id1) payable external
  {
      bytes32 id = keccak256(abi.encode(msg.sender, msg.value, id1));
      require(s_hswaps[id] == 0, "SafeSwap: request exist"); 
      s_hswaps[id] = 0xffffffffffffffff;
      emit HiddenERC1155SwapDeposited(msg.sender, msg.value, id1);
  }

  function hiddenERC1155TimedSwapDeposit(
        bytes32 id1,
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
    ) 
        payable external
    {
        require(msg.value >= autoRetrieveFees, "SafeSwap: autoRetrieveFees exeed value");
        bytes32 id = keccak256(abi.encode(msg.sender, msg.value, id1));
        require(s_hswaps[id] == 0, "SafeSwap: request exist");
        require(expiresAt > now, "SafeSwap: already expired"); 
        s_hswaps[id] = uint256(expiresAt) + (uint256(availableAt) << 64) + (uint256(autoRetrieveFees) << 128);
        emit HiddenERC1155SwapTimedDeposited(msg.sender, msg.value, id1, availableAt, expiresAt, autoRetrieveFees);
    }

    function hiddenBatchERC1155SwapRetrieve(
        bytes32 id1,
        uint256 value
    )   
        external 
    {
        bytes32 id = keccak256(abi.encode(msg.sender, value, id1));
        require(s_hswaps[id]  > 0, "SafeTransfer: request not exist");
        delete s_hswaps[id];
        msg.sender.transfer(value);
        emit HiddenERC1155SwapRetrieved(msg.sender, id1, value);
    }

    function hiddenSwapERC1155(
    address payable from,
    SwapERC1155Info memory info,
    bytes calldata secret
  ) external payable {
    bytes32 id1 = keccak256(
      abi.encode(
        HIDDEN_SWAP_ERC1155_TYPEHASH,
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
    bytes32 id = keccak256(abi.encode(from, id1));
    uint256 tr = s_hswaps[id];
    require(tr > 0, "SafeSwap: request not exist");
    require(uint64(tr) > now, "SafeSwap: expired");
    require(uint64(tr >> 64) <= now, "SafeSwap: not available yet");
    require(keccak256(secret) == info.secretHash, "SafeSwap: wrong secret");
    delete s_hswaps[id];
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
        msg.sender,
        from,
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

  function timedSwapDepositERC1155ToERC20(
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

  function hiddenBatchERC1155ToERC20SwapDeposit(bytes32 id1) payable external
  {
      bytes32 id = keccak256(abi.encode(msg.sender, msg.value, id1));
      require(s_hswaps[id] == 0, "SafeSwap: request exist"); 
      s_hswaps[id] = 0xffffffffffffffff;
      emit HiddenERC1155SwapDeposited(msg.sender, msg.value, id1);
  }

  function hiddenERC1155ToERC20TimedSwapDeposit(
        bytes32 id1,
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
    ) 
        payable external
    {
        require(msg.value >= autoRetrieveFees, "SafeSwap: autoRetrieveFees exeed value");
        bytes32 id = keccak256(abi.encode(msg.sender, msg.value, id1));
        require(s_hswaps[id] == 0, "SafeSwap: request exist");
        require(expiresAt > now, "SafeSwap: already expired"); 
        s_hswaps[id] = uint256(expiresAt) + (uint256(availableAt) << 64) + (uint256(autoRetrieveFees) << 128);
        emit HiddenERC1155SwapTimedDeposited(msg.sender, msg.value, id1, availableAt, expiresAt, autoRetrieveFees);
    }

    function hiddenBatchERC1155ToERC20SwapRetrieve(
        bytes32 id1,
        uint256 value
    )   
        external 
    {
        bytes32 id = keccak256(abi.encode(msg.sender, value, id1));
        require(s_hswaps[id]  > 0, "SafeTransfer: request not exist");
        delete s_hswaps[id];
        msg.sender.transfer(value);
        emit HiddenERC1155SwapRetrieved(msg.sender, id1, value);
    }

    function hiddenSwapERC1155ToERC20(
    address payable from,
    SwapBatchERC1155ToERC20Info memory info,
    bytes calldata secret
  ) external payable {
    bytes32 id1 = keccak256(
      abi.encode(
        HIDDEN_ERC1155_TO_ERC20_SWAP,
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
    bytes32 id = keccak256(abi.encode(from, info.fees0, id1));
    uint256 tr = s_hswaps[id];
    require(tr > 0, "SafeSwap: request not exist");
    require(uint64(tr) > now, "SafeSwap: expired");
    require(uint64(tr >> 64) <= now, "SafeSwap: not available yet");
    require(keccak256(secret) == info.secretHash, "SafeSwap: wrong secret");
    require(msg.value == info.fees1, "SafeSwap: value mismatch");
    delete s_hswaps[id];
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

  function timedSwapDepositERC20ToERC1155(
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

  function hiddenERC20ToBatchERC1155SwapDeposit(bytes32 id1) payable external
  {
      bytes32 id = keccak256(abi.encode(msg.sender, msg.value, id1));
      require(s_hswaps[id] == 0, "SafeSwap: request exist"); 
      s_hswaps[id] = 0xffffffffffffffff;
      emit HiddenERC1155SwapDeposited(msg.sender, msg.value, id1);
  }

  function hiddenERC20ToERC1155TimedSwapDeposit(
        bytes32 id1,
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
    ) 
        payable external
    {
        require(msg.value >= autoRetrieveFees, "SafeSwap: autoRetrieveFees exeed value");
        bytes32 id = keccak256(abi.encode(msg.sender, msg.value, id1));
        require(s_hswaps[id] == 0, "SafeSwap: request exist");
        require(expiresAt > now, "SafeSwap: already expired"); 
        s_hswaps[id] = uint256(expiresAt) + (uint256(availableAt) << 64) + (uint256(autoRetrieveFees) << 128);
        emit HiddenERC1155SwapTimedDeposited(msg.sender, msg.value, id1, availableAt, expiresAt, autoRetrieveFees);
    }

    function hiddenERC20ToBatchERC1155SwapRetrieve(
        bytes32 id1,
        uint256 value
    )   
        external 
    {
        bytes32 id = keccak256(abi.encode(msg.sender, value, id1));
        require(s_hswaps[id]  > 0, "SafeTransfer: request not exist");
        delete s_hswaps[id];
        msg.sender.transfer(value);
        emit HiddenERC1155SwapRetrieved(msg.sender, id1, value);
    }

    function hiddenSwapERC20ToERC1155(
    address payable from,
    SwapERC20ToBatchERC1155Info memory info,
    bytes calldata secret
  ) external payable {
    bytes32 id1 = keccak256(
      abi.encode(
        HIDDEN_ERC20_TO_ERC1155_SWAP,
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
    bytes32 id = keccak256(abi.encode(from, info.fees0, id1));
    uint256 tr = s_hswaps[id];
    require(tr > 0, "SafeSwap: request not exist");
    require(uint64(tr) > now, "SafeSwap: expired");
    require(uint64(tr >> 64) <= now, "SafeSwap: not available yet");
    require(keccak256(secret) == info.secretHash, "SafeSwap: wrong secret");
    require(msg.value == info.fees1, "SafeSwap: value mismatch");
    delete s_hswaps[id];
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
}
