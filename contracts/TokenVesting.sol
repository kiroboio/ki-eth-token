// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenVesting {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 private s_token;

    // beneficiary of tokens after they are released
    address private s_beneficiary;

    // timestamp when token release is enabled
    uint256 private s_releaseTime;

    address private s_issuer;

    constructor (IERC20 token, address beneficiary, uint256 releaseTime, address issuer) public {
        // solhint-disable-next-line not-rely-on-time
        require(releaseTime > block.timestamp, "TokenVesting: release time is before current time");
        s_token = token;
        s_beneficiary = beneficiary;
        s_releaseTime = releaseTime;
        s_issuer = issuer;
    }

    /**
     * @return the token being held.
     */
    function token() public view returns (IERC20) {
        return s_token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return s_beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view returns (uint256) {
        return s_releaseTime;
    }

    function issuer() public view returns (address) {
        return s_issuer;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= s_releaseTime, "TokenVesting: current time is before release time");

        uint256 amount = s_token.balanceOf(address(this));
        require(amount > 0, "TokenVesting: no tokens to release");

        s_token.safeTransfer(s_beneficiary, amount);
    }

    function cancel() public virtual {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp < s_releaseTime, "TokenVesting: current time is after release time");
        require(msg.sender == s_issuer, "TokenVesting: not issuer");
        
        uint256 amount = s_token.balanceOf(address(this));
        require(amount > 0, "TokenVesting: no tokens to release");
        
        s_token.safeTransfer(s_issuer, amount);
    }

}
