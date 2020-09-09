// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../node_modules/@openzeppelin/contracts/math/Math.sol";
import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./Ownable.sol";

contract LPTokenWrapper {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // Uniswap v2 KIRO/ETH pair
  IERC20 public UNI = IERC20(0xd0fd23E6924a7A34d34BC6ec6b97fadD80BE255F);

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  function stake(uint256 amount) public virtual {
    _totalSupply = _totalSupply.add(amount);
    _balances[msg.sender] = _balances[msg.sender].add(amount);
    UNI.safeTransferFrom(msg.sender, address(this), amount);
  }

  function withdraw(uint256 amount) public virtual {
    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    UNI.safeTransfer(msg.sender, amount);
  }
}

contract Unipool is LPTokenWrapper, Ownable {
  uint256 public constant DURATION = 30 days;
  // Kirobo Token on Rinkeby
  IERC20 public KIRO = IERC20(0xDc7988DC2fA23EA82d73B21B63Da5B905Fb52074);

  uint256 public periodFinish;
  uint256 public rewardRate;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;
  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;

  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

  constructor () public {
  }

  receive() external payable {
    require(false, "Unipool: not aceepting ether");
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    return Math.min(block.timestamp, periodFinish);
  }

  function rewardPerToken() public view returns (uint256) {
    if (totalSupply() == 0) {
      return rewardPerTokenStored;
    }
    return
      rewardPerTokenStored.add(
        lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(totalSupply())
      );
  }

  function earned(address account) public view returns (uint256) {
    return
      balanceOf(account).mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(
        rewards[account]
      );
  }

  // stake visibility is public as overriding LPTokenWrapper's stake() function
  function stake(uint256 amount) public updateReward(msg.sender) override {
    require(amount > 0, 'Cannot stake 0');
    super.stake(amount);
    emit Staked(msg.sender, amount);
  }

  function withdraw(uint256 amount) public updateReward(msg.sender) override {
    require(amount > 0, 'Cannot withdraw 0');
    super.withdraw(amount);
    emit Withdrawn(msg.sender, amount);
  }

  function exit() external {
    withdraw(balanceOf(msg.sender));
    getReward();
  }

  function getReward() public updateReward(msg.sender) {
    uint256 reward = earned(msg.sender);
    if (reward > 0) {
      rewards[msg.sender] = 0;
      KIRO.safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, reward);
    }
  }

  function addReward(
    address _from,
    uint256 _amount
  ) external onlyOwner() updateReward(address(0)) {
    require(_amount > 0, 'Cannot approve 0');

    if (block.timestamp >= periodFinish) {
      rewardRate = _amount.div(DURATION);
    } else {
      uint256 remaining = periodFinish.sub(block.timestamp);
      uint256 leftover = remaining.mul(rewardRate);
      rewardRate = _amount.add(leftover).div(DURATION);
    }
    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp.add(DURATION);

    KIRO.safeTransferFrom(_from, address(this), _amount);

    emit RewardAdded(_amount);
  }
}
