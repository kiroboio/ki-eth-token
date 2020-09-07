// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Token.sol";
import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";

contract TokenMinter {
    using SafeMath for uint256;
    Token private s_token;

    uint256 constant public END_VALUE = 2_200_000_000 * 10 ** 18; // 2.2B tokens
    uint256 constant public DURATION = 155_520_000; // 1800 days in seconds
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

    function start() public onlyBeneficiary() {
        // solhint-disable-next-line not-rely-on-time
        require(s_started == false, "TokenMinter: already started");
        require(s_token.getRoleMemberCount(s_token.MINTER_ADMIN_ROLE()) == 0, "TokenMinter: can change minter roles");
        minterRoleValidation();
        s_started = true;
        s_startValue = s_token.totalSupply();
        s_startTime = block.timestamp;
        s_endTime = block.timestamp.add(DURATION);
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

    function startValue() public view returns (uint256) {
        return s_startValue;
    }

    function minted() public view returns (uint256) {
        return s_minted;
    }

    function left() public view returns (uint256) {
        return END_VALUE.sub(s_startValue).sub(s_minted);
    }

    function maxCap() public view returns (uint256) {
        return s_token.totalSupply().add(left());
    }

    function maxCurrentSupply() public view returns (uint256) {
        uint256 maxAmount = END_VALUE.sub(s_startValue);
        uint256 maxDuration = s_endTime.sub(s_startTime);
        // solhint-disable-next-line not-rely-on-time
        uint256 effectiveTime = block.timestamp > s_endTime ? s_endTime : block.timestamp;
        uint256 duration = effectiveTime.sub(s_startTime);
        return maxAmount.mul(duration).div(maxDuration);
    }

    function mint(uint256 value) public onlyBeneficiary() {
        require(value > 0, "TokenMinter: nothing to mint");
        s_minted = s_minted.add(value);
        require(s_minted <= maxCurrentSupply(), "TokenMinter: value too high");
        s_token.mint(s_beneficiary, value);
    }

    function mintAll() public onlyBeneficiary() {
        mint(maxCurrentSupply().sub(s_minted));
    }

}
