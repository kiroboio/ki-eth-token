// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Token.sol";
import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";

contract TokenMinter {
    using SafeMath for uint256;
    Token private s_token;

    uint256 constant public END_VALUE = 1_200_000_000 * 10 ** 18;
    uint256 private s_startValue;
    uint256 private s_startTime;
    uint256 private s_endTime;
    uint256 private s_minted;
    address private s_beneficiary;
    bool private s_started;

    modifier onlyBeneficiary() {
      require(msg.sender == s_beneficiary, "not beneficiary");
      _;
    }

    constructor (Token token, address beneficiary) public {
        s_token = token;
        s_beneficiary = beneficiary;
    }

    function start(uint256 endTime) public onlyBeneficiary() {
        // solhint-disable-next-line not-rely-on-time
        require(endTime > block.timestamp, "TokenMinter: release time is before current time");
        require(s_started == false, "TokenMinter: already started");
        require(s_token.getRoleMemberCount(s_token.MINTER_ADMIN_ROLE()) == 0, "TokenMinter: can change minter roles");
        minterRoleValidation();
        s_started = true;
        s_startValue = s_token.totalSupply();
        s_endTime = endTime;
    }

    function minterRoleValidation() public view {
        require(s_token.getRoleMemberCount(s_token.MINTER_ROLE()) == 1, "TokenMinter: only one should have minter role");
        require(s_token.hasRole(s_token.MINTER_ROLE(), address(this)), "TokenMinter: do not have minter role");
    }

    function started() public view returns (bool) {
        return s_started;
    }

    function token() public view returns (Token) {
        return s_token;
    }

    function beneficiary() public view returns (address) {
        return s_beneficiary;
    }

    function startTime() public view returns (uint256) {
        return s_startTime;
    }

    function endTime() public view returns (uint256) {
        return s_endTime;
    }

    function maxValue() public view returns (uint256) {
        uint256 maxAmount = END_VALUE.sub(s_startValue);
        uint256 maxduration = s_endTime.sub(s_startTime);
        // solhint-disable-next-line not-rely-on-time
        uint256 effectiveTime = block.timestamp > s_endTime ? s_endTime : block.timestamp;
        uint256 duration =  effectiveTime.sub(s_startTime);
        return maxAmount.mul(duration).sub(maxduration);
    }

    function mint(uint256 value) public {
        require(value <= maxValue(), "TokenMinter: value too high");
        s_minted = s_minted.add(value);
        s_token.mint(s_beneficiary, value);
    }
}
