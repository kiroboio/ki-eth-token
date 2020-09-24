'use strict'

const Token = artifacts.require("Token")
const Staking = artifacts.require("Staking")
const mlog = require('mocha-logger')
const UniswapV2Factory = require('@uniswap/v2-core/output/UniswapV2Factory.json')
const UniswapV2Pair = require('@uniswap/v2-core/output/UniswapV2Pair.json')

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

contract('Staking', async accounts => {
  let factory, pair, uni, token, token2, unipool, nonce, targetSupply, duration, initialSupply, pairAddress

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

  const logUnipoolState = async (user, title='') => {
    mlog.log(`----------------- ${title} ---------------------`)
    mlog.log('total supply', await unipool.totalSupply())
    mlog.log('reward rate', await unipool.rewardRate())
    mlog.log('reward per token', await unipool.rewardPerToken())
    mlog.log('earned(used1)', await unipool.earned(user))
    mlog.log('reward per token paid(used1)', await unipool.userRewardPerTokenPaid(user))
    mlog.log('rewards(used1)', await unipool.rewards(user))
    mlog.log('pair limit(used1)', await unipool.pairLimit(user))
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
    await advanceTimeAndBlock(60000)
    const contract = new web3.eth.Contract(UniswapV2Factory.abi)
    factory = await contract.deploy({
       data: UniswapV2Factory.bytecode,
       arguments: [tokenOwner]}
    ).send({ from: tokenOwner })
    uni = await Token.new({ from: tokenOwner })
    token = await Token.new({ from: tokenOwner })
    await factory.methods.createPair(token.address, uni.address).send({ from: tokenOwner })
    pairAddress = await factory.methods.getPair(token.address, uni.address).call({ from: tokenOwner})
    pair = new web3.eth.Contract(UniswapV2Pair.abi, pairAddress)
    unipool = await Staking.new(pairAddress, token.address, { from: tokenOwner })
    duration = BigInt(2592000) // await unipool.DURATION())
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

  it.skip('check unipool', async () => {
    await token.mint(tokenOwner, 100000000, { from: tokenOwner})
    await token.approve(unipool.address, 100000000, { from: tokenOwner })
    await token.mint(pairAddress, 500000000, { from: tokenOwner })
    await uni.mint(pairAddress, 500000000, { from: tokenOwner })
    await pair.methods.mint(user1).send({ from: user1 })
    await token.mint(pairAddress, 200000000, { from: tokenOwner })
    await uni.mint(pairAddress, 200000000, { from: tokenOwner })
    await pair.methods.mint(user2).send({ from: user2 })    
    await pair.methods.approve(unipool.address, 400000000).send({ from: user1 })
    await pair.methods.approve(unipool.address, 400000000).send({ from: user2 })
    
    await token.mint(user1, 1000000, { from: tokenOwner })
    await uni.mint(user1, 1000000, { from: tokenOwner })
    await pair.methods.sync().send({ from: user1 })
    // await pair.methods.swap(0, 10000, user1, Buffer.from('')).send({ from: user1 })

    await advanceTimeAndBlock(1000)
    await logUnipoolState(user1, 'start')
    await unipool.addReward(tokenOwner, 10000000, duration, { from: tokenOwner })
    await logUnipoolState(user1, 'add reward: 1000')
    await unipool.stake(200, { from: user1 })
    await logUnipoolState(user1, 'user1: stake 200')
    await unipool.addReward(tokenOwner, 20000000, duration/2, { from: tokenOwner })
    await advanceTimeAndBlock(200000)
    await unipool.stake(200, { from: user1 })
    await unipool.stake(400, { from: user2 })
    await advanceTimeAndBlock(200000)
    await logUnipoolState(user1, 'advanced time: 20000')
    await logUnipoolState(user1, 'user1: stake 200')
    await advanceTimeAndBlock(200000)
    // await unipool.stake(1, { from: user1 })
    await advanceTimeAndBlock(200000)
    await logUnipoolState(user1, 'u1-advanced time: 20000')
    await logUnipoolState(user2, 'u2-advanced time: 20000')
    await unipool.exit({ from: user1 })
    await unipool.exit({ from: user2 })
    mlog.log('user1 profit', await token.balanceOf(user1))
    mlog.log('user2 profit', await token.balanceOf(user2))
  })


  it('user must not degrade', async () => {
    await token.mint(tokenOwner, 3e6, { from: tokenOwner})
    await token.approve(unipool.address, 1e10, { from: tokenOwner })
    await token.mint(pairAddress, 1e8, { from: tokenOwner })
    await uni.mint(pairAddress, 1e8, { from: tokenOwner })
    await pair.methods.mint(user1).send({ from: user1 })
    await advanceTimeAndBlock(1000)
    await token.mint(pairAddress, 2e8, { from: tokenOwner })
    await uni.mint(pairAddress, 2e8, { from: tokenOwner })
    await pair.methods.mint(user2).send({ from: user2 })    
    
    await pair.methods.approve(unipool.address, 1e8).send({ from: user1 })
    // await pair.methods.approve(unipool.address, 2e8).send({ from: user2 })
    
    await unipool.addReward(tokenOwner, 1e6, 10000, { from: tokenOwner })
    await unipool.stake(2e5, { from: user1 })
    await advanceTimeAndBlock(6000)
    // await unipool.stake(2e5, { from: user1 })
    await advanceTimeAndBlock(1000)
    // await unipool.exit({ from: user1 })
    await unipool.addReward(tokenOwner, 2e6-1e3, 3000, { from: tokenOwner })
    await advanceTimeAndBlock(2000)
    // await unipool.stake(2e5, { from: user1 })
    await advanceTimeAndBlock(1000000)
    
    // await logUnipoolState(user1, 'start')
    // await logUnipoolState(user1, 'add reward: 1000')
    // await unipool.stake(200, { from: user1 })
    // await logUnipoolState(user1, 'user1: stake 200')
    // await unipool.addReward(tokenOwner, 20000000, duration/2, { from: tokenOwner })
    // await advanceTimeAndBlock(200000)
    // await unipool.stake(200, { from: user1 })
    // await unipool.stake(400, { from: user2 })
    // await advanceTimeAndBlock(200000)
    // await logUnipoolState(user1, 'advanced time: 20000')
    // await logUnipoolState(user1, 'user1: stake 200')
    // await advanceTimeAndBlock(200000)
    // // await unipool.stake(1, { from: user1 })
    // await advanceTimeAndBlock(200000)
    // await logUnipoolState(user1, 'u1-advanced time: 20000')
    // await logUnipoolState(user2, 'u2-advanced time: 20000')
    await unipool.exit({ from: user1 })
    await unipool.collectLeftover({ from: tokenOwner })
    // await unipool.exit({ from: user2 })
    mlog.log('user1 profit', await token.balanceOf(user1))
    mlog.log('user2 profit', await token.balanceOf(user2))
    mlog.log('owner balance', await token.balanceOf(tokenOwner))
    mlog.log('pool balance', await token.balanceOf(unipool.address))
  })
})
