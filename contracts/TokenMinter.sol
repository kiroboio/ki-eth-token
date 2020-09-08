// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "./Token.sol";

contract TokenMinter {
    using SafeMath for uint256;

    uint256 constant public TARGET_SUPPLY = 2_200_000_000 * 10 ** 18; // 2.2B tokens
    uint256 constant public DURATION = 155_520_000; // 1800 days in seconds
    uint256 private s_initialSupply;
    uint256 private s_startTime;
    uint256 private s_minted;
    address private s_beneficiary;
    Token private s_token;
    bool private s_started;

    event Created(address sender, address token, address beneficiary);
    event Started(uint256 initialSupply, uint256 timestamp);
    event Minted(uint256 amount, uint256 timestamp);

    modifier onlyBeneficiary() {
      require(msg.sender == s_beneficiary, "not beneficiary");
      _;
    }

    constructor (Token token, address beneficiary) public {
        s_token = token;
        s_beneficiary = beneficiary;
        emit Created(msg.sender, address(token), beneficiary);
    }

    function start() external onlyBeneficiary() {
        require(s_started == false, "TokenMinter: already started");
        require(s_token.getRoleMemberCount(s_token.MINTER_ADMIN_ROLE()) == 0, "TokenMinter: minter roles are not final");
        minterRoleValidation();
        s_started = true;
        s_initialSupply = s_token.totalSupply();
        s_startTime = block.timestamp;
        emit Started(s_initialSupply, block.timestamp);
    }
    
    function mint(uint256 amount) public onlyBeneficiary() {
        require(s_started == true, "TokenMinter: not started");
        require(amount > 0, "TokenMinter: nothing to mint");
        s_minted = s_minted.add(amount);
        require(s_minted <= mintLimit(), "TokenMinter: amount too high");
        s_token.mint(s_beneficiary, amount);
        emit Minted(amount, block.timestamp);
    }

    function mintAll() external {
        mint(mintLimit().sub(s_minted));
    }

    function minterRoleValidation() public view {
        require(s_token.hasRole(s_token.MINTER_ROLE(), address(this)), "TokenMinter: do not have a minter role");
        require(s_token.getRoleMemberCount(s_token.MINTER_ROLE()) == 1, "TokenMinter: minter role is not exclusive");
    }

    function mintLimit() public view returns (uint256) {
        uint256 maxMinting = TARGET_SUPPLY.sub(s_initialSupply);
        uint256 currentDuration = block.timestamp.sub(s_startTime);
        uint256 effectiveDuration = currentDuration < DURATION ? currentDuration : DURATION;
        return maxMinting.mul(effectiveDuration).div(DURATION);
    }

    function initialSupply() public view returns (uint256) {
        return s_initialSupply;
    }

    function startTime() public view returns (uint256) {
        return s_startTime;
    }

    function endTime() public view returns (uint256) {
        return s_startTime.add(DURATION);
    }

    function minted() public view returns (uint256) {
        return s_minted;
    }

    function beneficiary() public view returns (address) {
        return s_beneficiary;
    }

    function token() public view returns (Token) {
        return s_token;
    }

    function started() public view returns (bool) {
        return s_started;
    }

    function left() public view returns (uint256) {
        return TARGET_SUPPLY.sub(s_initialSupply).sub(s_minted);
    }

    function maxCap() public view returns (uint256) {
        return s_token.totalSupply().add(left());
    }

}
