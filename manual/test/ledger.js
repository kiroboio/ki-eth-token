'use strict'

const Pool = artifacts.require("Pool")
const Token = artifacts.require("KiroboToken")
const mlog = require('mocha-logger')

const { assertRevert, assertInvalidOpcode, assertPayable, assetEvent_getArgs } = require('../../test/lib/asserts')
const { advanceBlock, advanceTime, advanceTimeAndBlock } = require('../../test/lib/utils')

contract('Ledger Test', async accounts => {
  let token, pool

  const tokenOwner = accounts[1]
  const poolOwner = accounts[2]
  const user1 = accounts[3]
  const user2 = accounts[4]
  const user3 = accounts[5]

  const val1  = web3.utils.toWei('0.5', 'gwei')
  const val2  = web3.utils.toWei('0.4', 'gwei')
  const val3  = web3.utils.toWei('0.3', 'gwei')
  const valBN = web3.utils.toBN('0')

  before('checking constants', async () => {
      assert(typeof tokenOwner  == 'string', 'tokenOwner should be string')
      assert(typeof poolOwner   == 'string', 'poolOwner should be string')
      assert(typeof user1       == 'string', 'user1 should be string')
      assert(typeof user2       == 'string', 'user2 should be string')
      assert(typeof user3       == 'string', 'user3 should be string')
      assert(typeof val1        == 'string', 'val1  should be big number')
      assert(typeof val2        == 'string', 'val2  should be string')
      assert(typeof val3        == 'string', 'val2  should be string')
      assert(valBN instanceof web3.utils.BN, 'valBN should be big number')
  });

  before('setup contract for the test', async () => {
    token = await Token.new({ from: tokenOwner });
    pool = await Pool.new(token.address, { from: poolOwner });
    await token.disableTransfers(false, { from: tokenOwner });
    
    mlog.log('web3           ', web3.version);
    mlog.log('token contract ', token.address);
    mlog.log('pool contract  ', pool.address);
    mlog.log('tokenOwner     ', tokenOwner);
    mlog.log('poolOwner      ', poolOwner);
    mlog.log('user1          ', user1);
    mlog.log('user2          ', user2);
    mlog.log('user3          ', user3);
    mlog.log('val1           ', val1);
    mlog.log('val2           ', val2);
    mlog.log('val3           ', val3);
  });

  it('should be able to generate message', async () => {
    await token.mint(pool.address, val1, { from: tokenOwner })
    await token.mint(user1, val2, { from: tokenOwner })
    await token.approve(pool.address, val3, { from: user1 })
    await pool.deposit(val3, { from: user1 })
    const message = await pool.generatePaymentMessage(user1, 200, { from: user1 })
    mlog.log(message)
  });


});
