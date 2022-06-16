// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/* import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol"; */
import "./ISafeForERC1155.sol";

contract SafeForERC1155 is AccessControl {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  bytes32 public DOMAIN_SEPARATOR;
  uint256 public CHAIN_ID;
  bytes32 s_uid;
  uint256 s_fees;

  mapping(bytes32 => uint256) s_erc1155Transfers;
  mapping(bytes32 => uint256) s_swaps;
  mapping(bytes32 => uint256) s_htransfers;
  mapping(bytes32 => uint256) s_hswaps;

  string public constant NAME = "Kirobo Safe Transfer";
  string public constant VERSION = "1";
  uint8 public constant VERSION_NUMBER = 0x1;
  address public immutable SAFE_FOR_ERC_1155_CORE;

  event ERC721Retrieved(
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

  constructor(address core) public {
   SAFE_FOR_ERC_1155_CORE = core;

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
