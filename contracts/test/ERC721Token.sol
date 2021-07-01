// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
//pragma abicoder v1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract ERC721Token is ERC721URIStorage {
    uint256 private s_tokenId;

    constructor(string memory name, string memory symbol)
        public
        ERC721(name, symbol)
    {}

    function createTimeframe(string memory tokenURI) public returns (bool) {
        s_tokenId += 1;
        _mint(msg.sender, s_tokenId);
        _setTokenURI(s_tokenId, tokenURI);
        return true;
    }
}
