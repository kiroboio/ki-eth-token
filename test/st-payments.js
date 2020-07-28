'use strict';

const SafeTransferPayments = artifacts.require("SafeTransferPayments");
const Token = artifacts.require("Token");
const mlog = require('mocha-logger');
const {
  assertRevert,
  assertInvalidOpcode,
  assertPayable,
  assetEvent_getArgs
} = require('./lib/asserts');

contract('SafeTransferPayments', async accounts => {
  let token, pool;

  const tokenOwner = accounts[0];
  const poolOwner = accounts[1];
  const user1 = accounts[2];
  const user2 = accounts[3];
  const user3 = accounts[4];

  const val1  = web3.utils.toWei('0.5', 'gwei');
  const val2  = web3.utils.toWei('0.4', 'gwei');
  const val3  = web3.utils.toWei('0.6', 'gwei');
  const valBN = web3.utils.toBN('0'); //val1).add(web3.utils.toBN(val2)).add(web3.utils.toBN(val3));

  before('checking constants', async () => {
      assert(typeof tokenOwner  == 'string', 'tokenOwner should be string');
      assert(typeof poolOwner   == 'string', 'poolOwner should be string');
      assert(typeof user1       == 'string', 'user1 should be string');
      assert(typeof user2       == 'string', 'user2 should be string');
      assert(typeof user3       == 'string', 'user3 should be string');
      assert(typeof val1        == 'string', 'val1  should be string');
      assert(typeof val2        == 'string', 'val2  should be string');
      assert(typeof val3        == 'string', 'val2  should be string');
      assert(valBN instanceof web3.utils.BN, 'valBN should be big number');
  });

  before('setup contract for the test', async () => {
    token = await Token.new({ from: tokenOwner });
    pool = await SafeTransferPayments.new(token.address, { from: poolOwner });
    
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

  it('should create empty pool', async () => {
    const balance = await web3.eth.getBalance(pool.address)
    assert.equal(balance.toString(10), web3.utils.toBN('0').toString(10))
  });

  it('should be able accept tokens', async () => {
    await token.issue(pool.address, val1, { from: tokenOwner })
    const balance = await web3.eth.getBalance(pool.address)
    assert.equal(balance.toString(10), web3.utils.toBN('0').toString(10))
    const totalSupply = await token.totalSupply({ from: poolOwner })
    assert.equal(totalSupply, val1)
  });

  
});
