// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";


  
  struct CollectBatchERC1155Info {
      address token;
      uint256[] tokenIds;
      uint256[] values;
      bytes tokenData;
      uint256 fees;
      bytes32 secretHash;
      bytes secret;
    }

  struct TimedDepositBatchERC1155Info {
      address token;
      uint256[] tokenIds;
      uint256[] values;
      uint256 fees;
      bytes32 secretHash;
      uint64 availableAt;
      uint64 expiresAt;
      uint128 autoRetrieveFees;
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
    
interface ISafeForERC1155 {
  function getS_swaps(bytes32) external returns (uint256);
  function setS_swaps(bytes32, uint256) external;
}

