'use strict'

const Pool = artifacts.require("Pool")
const Token = artifacts.require("KiroboToken")
const Wallet = artifacts.require("Wallet")
const mlog = require('mocha-logger')

const { assertRevert, assertInvalidOpcode, assertPayable, assetEvent_getArgs } = require('./lib/asserts')
const { advanceBlock, advanceTime, advanceTimeAndBlock } = require('./lib/utils')

contract('Wallet', async accounts => {
  let token, pool, wallet

  const tokenOwner = accounts[1]
  const poolOwner = accounts[2]
  const user1 = accounts[3]
  const user2 = accounts[4]
  const user3 = accounts[5]
  const walletOwner1 = accounts[6]
  const walletOwner2 = accounts[7]
  const walletOwner3 = accounts[8]

  const val1  = web3.utils.toWei('0.5', 'gwei')
  const val2  = web3.utils.toWei('0.4', 'gwei')
  const val3  = web3.utils.toWei('0.3', 'gwei')
  const valBN = web3.utils.toBN('0')

  before('checking constants', async () => {
      assert(typeof walletOwner1  == 'string', 'walletOwner1 should be string')
      assert(typeof walletOwner2  == 'string', 'walletOwner1 should be string')
      assert(typeof walletOwner3  == 'string', 'walletOwner1 should be string')
      assert(typeof tokenOwner    == 'string', 'tokenOwner should be string')
      assert(typeof poolOwner     == 'string', 'poolOwner should be string')
      assert(typeof user1         == 'string', 'user1 should be string')
      assert(typeof user2         == 'string', 'user2 should be string')
      assert(typeof user3         == 'string', 'user3 should be string')
      assert(typeof val1          == 'string', 'val1  should be big number')
      assert(typeof val2          == 'string', 'val2  should be string')
      assert(typeof val3          == 'string', 'val2  should be string')
      assert(valBN instanceof web3.utils.BN, 'valBN should be big number')
  });

  before('setup contract for the test', async () => {
    token = await Token.new({ from: tokenOwner })
    pool = await Pool.new(token.address, { from: poolOwner })
    await token.disableTransfers(false, { from: tokenOwner })
    wallet = await Wallet.new(walletOwner1, walletOwner2, walletOwner3, { from: user1 })
    
    mlog.log('web3           ', web3.version)
    mlog.log('token contract ', token.address)
    mlog.log('pool contract  ', pool.address)
    mlog.log('tokenOwner     ', tokenOwner)
    mlog.log('poolOwner      ', poolOwner)
    mlog.log('walletOwner1   ', walletOwner1)
    mlog.log('walletOwner2   ', walletOwner2)
    mlog.log('walletOwner3   ', walletOwner3)
    mlog.log('user1          ', user1)
    mlog.log('user2          ', user2)
    mlog.log('user3          ', user3)
    mlog.log('val1           ', val1)
    mlog.log('val2           ', val2)
    mlog.log('val3           ', val3)
  });

  it('should create wallet with owners only', async () => {
    assert.ok(await wallet.isOwner({ from: walletOwner1 }))
    assert.ok(await wallet.isOwner({ from: walletOwner2 }))
    assert.ok(await wallet.isOwner({ from: walletOwner3 }))
    assert.notOk(await wallet.isOwner({ from: user1 }))
  });

});
