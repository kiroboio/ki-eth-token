// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract TokenVesting {
    using SafeERC20 for IERC20;

    IERC20 private s_token;
    address private s_beneficiary;
    uint256 private s_releaseTime;
    address private s_issuer;
    uint256 private s_retrieveTime;

    constructor (IERC20 token, address beneficiary, uint256 releaseTime, address issuer, uint256 retrieveTime) public {
        require(releaseTime > block.timestamp, "TokenVesting: release time is before current time");
        s_token = token;
        s_beneficiary = beneficiary;
        s_releaseTime = releaseTime;
        s_retrieveTime = retrieveTime;
        s_issuer = issuer;
    }

    function release(uint256 amount) public {
        require(block.timestamp >= s_releaseTime, "TokenVesting: current time is before release time");
        require(amount > 0, "TokenVesting: no tokens to release");
        s_token.safeTransfer(s_beneficiary, amount);
    }

    function releaseAll() public {
        release(s_token.balanceOf(address(this)));
    }

    function retrieve(uint256 amount) public {
        require(msg.sender == s_issuer, "TokenVesting: not issuer");
        require(block.timestamp <= s_retrieveTime, "TokenVesting: current time is after retrieve time");
        require(amount > 0, "TokenVesting: no tokens to retrieve");
        s_token.safeTransfer(s_issuer, amount);
    }

    function retrieveAll() public {
        retrieve(s_token.balanceOf(address(this)));
    }

    function token() public view returns (IERC20) {
        return s_token;
    }

    function beneficiary() public view returns (address) {
        return s_beneficiary;
    }

    function releaseTime() public view returns (uint256) {
        return s_releaseTime;
    }

    function issuer() public view returns (address) {
        return s_issuer;
    }

    function retrieveTime() public view returns (uint256) {
        return s_retrieveTime;
    }

}
