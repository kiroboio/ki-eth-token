'use strict'

const Pool = artifacts.require("Pool")
const Token = artifacts.require("KiroboToken")
const mlog = require('mocha-logger')

const { assertRevert, assertInvalidOpcode, assertPayable, assetEvent_getArgs } = require('./lib/asserts')
const { advanceBlock, advanceTime, advanceTimeAndBlock } = require('./lib/utils')

contract('Pool', async accounts => {
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

  it('should create empty pool', async () => {
    const balance = await web3.eth.getBalance(pool.address)
    assert.equal(balance.toString(10), web3.utils.toBN('0').toString(10))
  });

  it('pool should accept tokens', async () => {
    await token.mint(pool.address, val1, { from: tokenOwner })
    const balance = await web3.eth.getBalance(pool.address)
    assert.equal(balance.toString(10), web3.utils.toBN('0').toString(10))
    const poolTokens = await token.balanceOf(pool.address, { from: poolOwner })
    assert.equal(poolTokens.toString(), val1)
    const totalSupply = await pool.totalSupply({ from: poolOwner })
    assert.equal(totalSupply.toString(), val1)
  });

  it('user should be able to deposit tokens', async () => {
    await token.mint(user1, val2, { from: tokenOwner })
    await token.approve(pool.address, val3, { from: user1 })
    await pool.deposit(val3, { from: user1 })
    const totalSupply = await pool.totalSupply({ from: poolOwner })
    assert.equal((BigInt(val1) + BigInt(val3)).toString(), totalSupply.toString())
    const availableSupply = await pool.availableSupply({ from: poolOwner })
    assert.equal(BigInt(val1).toString(), availableSupply.toString())
  });

  it('user should be able to withdraw tokens', async () => {
    await pool.postWithdraw(val3, { from: user1 })
    for (let i=0; i<240; ++i) {
      await advanceBlock()
    }
    await pool.withdraw({ from: user1 })
    const totalSupply = await pool.totalSupply({ from: poolOwner })
    assert.equal((BigInt(val1)).toString(), totalSupply.toString())
    const availableSupply = await pool.availableSupply({ from: poolOwner })
    assert.equal(BigInt(val1).toString(), availableSupply.toString())
  });

  it('should be able to generate & validate accept tokens message', async () => {
    const account = web3.eth.accounts.privateKeyToAccount('0x348ce564d427a3311b6536bbcff9390d69395b03ed6c486954e971d960fe8709');
    await token.mint(pool.address, val1, { from: tokenOwner })
    await token.mint(user1, val2, { from: tokenOwner })
    await token.approve(pool.address, val3, { from: user1 })
    await pool.deposit(val3, { from: user1 })
    const message = await pool.generateAcceptTokensMessage(account.address, 200, { from: poolOwner })
    mlog.log('address: ', account.address)
    mlog.log('message: ', message)
    const rlp = await web3.eth.accounts.sign(web3.utils.sha3(message).slice(2), account.privateKey)
    mlog.log('rlp', JSON.stringify(rlp))
    mlog.log('recover', web3.eth.accounts.recover({
        messageHash: rlp.messageHash,
        v: rlp.v,
        r: rlp.r,
        s: rlp.s,
    }))
    assert(await pool.validateAcceptTokensMessage(account.address, 200, rlp.v, rlp.r, rlp.s, { from: account.address }), 'invalid signature')
  });


});
