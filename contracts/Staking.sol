// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import "../node_modules/@openzeppelin/contracts/math/Math.sol";
import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import '../node_modules/@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

contract Staking is AccessControl {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // Uniswap v2 KIRO/Other pair
  IUniswapV2Pair public PAIR;
  // Kirobo Token
  IERC20 public KIRO;
  // keccak256("DISTRIBUTER_ROLE")
  bytes32 public constant DISTRIBUTER_ROLE = 0x09630fffc1c31ed9c8dd68f6e39219ed189b07ff9a25e1efc743b828f69d555e;

  uint256 private s_totalSupply;
  uint256 private s_periodFinish;
  uint256 private s_rewardRate;
  uint256 private s_lastUpdateTime;
  uint256 private s_rewardPerTokenStored;
  uint256 private s_stakingLimit;
  uint256 private s_leftover;
  mapping(address => uint256) private s_balances;
  mapping(address => uint256) private s_userRewardPerTokenPaid;
  mapping(address => uint256) private s_rewards;

  event RewardAdded(address indexed distributer, uint256 reward, uint256 duration);
  event LeftoverCollected(address indexed distributer, uint256 amount);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);

  modifier updateReward(address account) {
    s_rewardPerTokenStored = rewardPerToken();
    uint256 lastTimeRewardApplicable = lastTimeRewardApplicable(); 
    if (s_totalSupply == 0) {
      s_leftover = s_leftover.add(lastTimeRewardApplicable.sub(s_lastUpdateTime).mul(s_rewardRate));
    }
    s_lastUpdateTime = lastTimeRewardApplicable;
    if (account != address(0)) {
      s_rewards[account] = earned(account);
      s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;
    }
    _;
  }

  modifier onlyDistributer() {
    require(hasRole(DISTRIBUTER_ROLE, msg.sender), "Staking: Caller is not a distributer");    
    _;
  }

  constructor (address pair, address kiro) public {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(DISTRIBUTER_ROLE, msg.sender);
    PAIR = IUniswapV2Pair(pair);
    KIRO = IERC20(kiro);
    s_stakingLimit = 7e18;
    require(address(PAIR).isContract(), "Staking: pair is not a contract");
    require(address(KIRO).isContract(), "Staking: kiro is not a contract");
    require(address(PAIR) != address(KIRO), "Staking: pair and kiro are the same");
  }

  receive() external payable {
    require(false, "Staking: not aceepting ether");
  }

  function setStakingLimit(uint256 other) external onlyDistributer() {
    s_stakingLimit = other;
  }

  function addReward(address from, uint256 amount, uint256 duration) external onlyDistributer() updateReward(address(0)) {
    require(amount > duration, 'Staking: Cannot approve less than 1');
    uint256 newRate = amount.div(duration);
    require(newRate >= s_rewardRate, "Staking: degragration is not allowed");
    if(now < s_periodFinish)
      amount = amount.sub(s_periodFinish.sub(now).mul(s_rewardRate));
    s_rewardRate = newRate;
    s_lastUpdateTime = now;
    s_periodFinish = now.add(duration);
    KIRO.safeTransferFrom(from, address(this), amount);
    emit RewardAdded(msg.sender, amount, duration);
  }

  function collectLeftover() external onlyDistributer() updateReward(address(0)) {
    uint256 balance = KIRO.balanceOf(address(this));
    uint256 amount = Math.min(s_leftover, balance);
    s_leftover = 0;
    KIRO.safeTransfer(msg.sender, amount);
    emit LeftoverCollected(msg.sender, amount);
  }

  function stake(uint256 amount) external updateReward(msg.sender) {
    require(amount > 0, "Staking: cannot stake 0");
    require(amount <= pairLimit(msg.sender), "Staking: amount exceeds limit");
    s_balances[msg.sender] = s_balances[msg.sender].add(amount);
    s_totalSupply = s_totalSupply.add(amount);
    IERC20(address(PAIR)).safeTransferFrom(msg.sender, address(this), amount);
    emit Staked(msg.sender, amount);
  }

  function exit() external {
    withdraw(s_balances[msg.sender]);
    getReward();
  }

  function withdraw(uint256 amount) public updateReward(msg.sender) {
    require(amount > 0, 'Staking: cannot withdraw 0');
    s_totalSupply = s_totalSupply.sub(amount);
    s_balances[msg.sender] = s_balances[msg.sender].sub(amount);
    IERC20(address(PAIR)).safeTransfer(msg.sender, amount);
    emit Withdrawn(msg.sender, amount);
  }

  function getReward() public updateReward(msg.sender) {
    uint256 reward = earned(msg.sender);
    if (reward > 0) {
      s_rewards[msg.sender] = 0;
      KIRO.safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, reward);
    }
  }

  function earned(address account) public view returns (uint256) {
    return
    (
      s_balances[account]
      .mul
      (
        rewardPerToken()
        .sub(s_userRewardPerTokenPaid[account])
      )
      .div(1e18)
      .add(s_rewards[account])
    );
  }

  function rewardPerToken() public view returns (uint256) {
    if (s_totalSupply == 0) {
      return s_rewardPerTokenStored;
    }
    return
      s_rewardPerTokenStored
      .add
      (
        lastTimeRewardApplicable()
        .sub(s_lastUpdateTime)
        .mul(s_rewardRate)
        .mul(1e18)
        .div(s_totalSupply)
      );
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    return Math.min(now, s_periodFinish);
  }

  function pairLimit(address account) public view returns (uint256) {
    (, uint256 other, uint256 totalSupply) = pairInfo();
    uint256 limit = totalSupply.mul(s_stakingLimit).div(other);
    uint256 balance = s_balances[account];
    return limit > balance ? limit - balance : 0;    
  }

  function pairInfo() public view returns (uint256 kiro, uint256 other, uint256 totalSupply) {
    totalSupply = PAIR.totalSupply();
    (uint256 reserves0, uint256 reserves1,) = PAIR.getReserves();
    (kiro, other) = address(KIRO) == PAIR.token0() ? (reserves0, reserves1) : (reserves1, reserves0);
  }

  function pairOtherBalance(uint256 amount) external view returns (uint256) {
    (, uint256 other, uint256 totalSupply) = pairInfo();
    return other.mul(amount).div(totalSupply);
  }

  function pairKiroBalance(uint256 amount) external view returns (uint256) {
    (uint256 kiro, , uint256 totalSupply) = pairInfo();
    return kiro.mul(amount).div(totalSupply);
  }

  function totalSupply() external view returns (uint256) {
    return s_totalSupply;
  }

  function periodFinish() external view returns (uint256) {
    return s_periodFinish;
  }

  function rewardRate() external view returns (uint256) {
    return s_rewardRate;
  }

  function lastUpdateTime() external view returns (uint256) {
    return s_lastUpdateTime;
  }

  function rewardPerTokenStored() external view returns (uint256) {
    return s_rewardPerTokenStored;
  }

  function balanceOf(address account) external view returns (uint256) {
    return s_balances[account];
  }

  function userRewardPerTokenPaid(address account) external view returns (uint256) {
    return s_userRewardPerTokenPaid[account];
  }

  function rewards(address account) external view returns (uint256) {
    return s_rewards[account];
  }

  function stakingLimit() external view returns (uint256) {
    return s_stakingLimit;
  }

  function leftover() external view returns (uint256) {
    return s_leftover;
  }

}
