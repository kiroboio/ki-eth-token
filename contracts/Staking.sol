// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

contract Staking is AccessControl {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 public constant DURATION = 30 days;
  // Uniswap v2 KIRO/WETH pair
  IERC20 public UNI;
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
  mapping(address => uint256) private s_balances;
  mapping(address => uint256) private s_userRewardPerTokenPaid;
  mapping(address => uint256) private s_rewards;

  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);

  modifier updateReward(address account) {
    s_rewardPerTokenStored = rewardPerToken();
    s_lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      s_rewards[account] = earned(account);
      s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;
    }
    _;
  }

  modifier onlyDistributer() {
    require(hasRole(DISTRIBUTER_ROLE, msg.sender), "Unipool: Caller is not a distributer");    
    _;
  }

  constructor (address uni, address kiro) public {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(DISTRIBUTER_ROLE, msg.sender);
    UNI = IERC20(uni);
    KIRO = IERC20(kiro);
    s_stakingLimit = 3e18;
    require(address(UNI).isContract(), "Unipool: uni is not a contract");
    require(address(KIRO).isContract(), "Unipool: kiro is not a contract");
    require(address(UNI) != address(KIRO), "Unipool: uni and kiro are the same");
  }

  receive() external payable {
    require(false, "Unipool: not aceepting ether");
  }

  function setStakingLimit(uint limit) external onlyDistributer() {
    s_stakingLimit = limit;
  }

  function addReward(address from, uint256 amount) external onlyDistributer() updateReward(address(0)) {
    require(amount > DURATION, 'Unipool: Cannot approve less than 1');
    uint256 newRate = amount.div(DURATION);
    require(newRate >= s_rewardRate, "Unipool: degragration is not allowed");
    s_rewardRate = newRate;
    if(now < s_periodFinish)
      amount = amount.sub(s_periodFinish.sub(now).mul(s_rewardRate));
    s_lastUpdateTime = now;
    s_periodFinish = now.add(DURATION);
    KIRO.safeTransferFrom(from, address(this), amount);
    emit RewardAdded(amount);
  }

  function stake(uint256 amount) external updateReward(msg.sender) {
    require(amount > 0, 'Unipool: cannot stake 0');
    uint newBalance = s_balances[msg.sender].add(amount);
    require(newBalance <= pairLimit(msg.sender));
    s_totalSupply = s_totalSupply.add(amount);
    s_balances[msg.sender] = newBalance;
    UNI.safeTransferFrom(msg.sender, address(this), amount);
    emit Staked(msg.sender, amount);
  }

  function exit() external {
    withdraw(s_balances[msg.sender]);
    getReward();
  }

  function withdraw(uint256 amount) public updateReward(msg.sender) {
    require(amount > 0, 'Unipool: cannot withdraw 0');
    s_totalSupply = s_totalSupply.sub(amount);
    s_balances[msg.sender] = s_balances[msg.sender].sub(amount);
    UNI.safeTransfer(msg.sender, amount);
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
    return Math.min(block.timestamp, s_periodFinish);
  }

  function pairLimit(address account) public view returns (uint256) {
    (, uint eth, uint totalSupply) = pairInfo();
    uint limit = totalSupply.mul(s_stakingLimit).div(eth);
    uint balance = s_balances[account];
    return limit > balance ? limit - balance : 0;    
  }

  function pairInfo() public view returns (uint256 kiro, uint256 eth, uint256 totalSupply) {
    IUniswapV2Pair pair = IUniswapV2Pair(address(UNI));
    totalSupply = pair.totalSupply();
    (uint reserves0, uint reserves1,) = pair.getReserves();
    (kiro, eth) = address(KIRO) == pair.token0() ? (reserves0, reserves1) : (reserves1, reserves0);
  }

  function pairEthBalance(uint amount) public view returns (uint256) {
    (, uint eth, uint totalSupply) = pairInfo();
    return eth.mul(amount).div(totalSupply);
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

}
