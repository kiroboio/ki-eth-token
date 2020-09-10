'use strict'

const Token = artifacts.require("Token")
const Unipool = artifacts.require("Unipool")
const mlog = require('mocha-logger')

const {
  advanceBlock,
  advanceTime,
  advanceTimeAndBlock,
  trNonce,
} = require('./lib/utils')

const {
  assertRevert,
  assertInvalidOpcode,
  assertPayable,
  assetEvent_getArgs,
  assertFunction, 
  mustFail,
  mustRevert,
} = require('./lib/asserts')

contract('Unipool', async accounts => {
  let uni, token, unipool, nonce, targetSupply, duration, initialSupply

  const tokenOwner = accounts[1]
  const user1 = accounts[2]
  const user2 = accounts[3]
  const user3 = accounts[4]
  const user4 = accounts[5]
  
  const val1  = web3.utils.toWei('0.5', 'gwei')
  const val2  = web3.utils.toWei('0.4', 'gwei')
  const val3  = web3.utils.toWei('0.3', 'gwei')
  const valBN = web3.utils.toBN('0')

  const startValue = 500n * 1000n * 10n ** 18n

  const logUnipoolState = async (user) => {
    mlog.log('total supply', await unipool.totalSupply())
    mlog.log('reward rate', await unipool.rewardRate())
    mlog.log('reward per token', await unipool.rewardPerToken())
    mlog.log('earned(used1)', await unipool.earned(user))
    mlog.log('reward per token paid(used1)', await unipool.userRewardPerTokenPaid(user))
    mlog.log('rewards(used1)', await unipool.rewards(user))
  }
  
  before('checking constants', async () => {
      assert(typeof user1         == 'string', 'user1 should be string')
      assert(typeof user2         == 'string', 'user2 should be string')
      assert(typeof user3         == 'string', 'user3 should be string')
      assert(typeof user4         == 'string', 'user4 should be string')
      assert(typeof val1          == 'string', 'val1  should be big number')
      assert(typeof val2          == 'string', 'val2  should be string')
      assert(typeof val3          == 'string', 'val2  should be string')
      assert(valBN instanceof web3.utils.BN, 'valBN should be big number')
  })

  before('setup contract for the test', async () => {
    uni = await Token.new({ from: tokenOwner })
    token = await Token.new({ from: tokenOwner })
    unipool = await Unipool.new(uni.address, token.address, { from: tokenOwner })
    duration = BigInt(await unipool.DURATION())
    mlog.log('web3                ', web3.version)
    mlog.log('uni contract        ', uni.address)
    mlog.log('token contract      ', token.address)
    mlog.log('unipool contract    ', unipool.address)
    mlog.log('token owner         ', tokenOwner)
    mlog.log('user1               ', user1)
    mlog.log('user2               ', user2)
    mlog.log('user3               ', user3)
    mlog.log('user4               ', user4)
    mlog.log('unipool duration    ', duration)
    mlog.log('val1                ', val1)
    mlog.log('val2                ', val2)
    mlog.log('val3                ', val3)
  })

  it('check unipool', async () => {
    await uni.mint(user1, 5000, { from: tokenOwner })
    await token.mint(tokenOwner, 1000, { from: tokenOwner})
    await uni.approve(unipool.address, 4000, { from: user1})
    await token.approve(unipool.address, 1000, { from: tokenOwner})
    await unipool.addReward(tokenOwner, 1000, { from: tokenOwner })
    await unipool.stake(200, { from: user1 })
    await logUnipoolState(user1)
    await advanceTimeAndBlock(200000)
    await logUnipoolState(user1)
    await unipool.stake(200, { from: user1 })
    await logUnipoolState(user1)
    await advanceTimeAndBlock(200000)
    await logUnipoolState(user1)
  })


})
