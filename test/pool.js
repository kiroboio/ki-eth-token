'use strict'

const Pool = artifacts.require("Pool")
const Token = artifacts.require("KiroboToken")
const mlog = require('mocha-logger')

const { assertRevert, assertInvalidOpcode, assertPayable, assetEvent_getArgs } = require('./lib/asserts')
const { 
  advanceBlock,
  advanceTime,
  advanceTimeAndBlock,
  parsePaymentMessage,
  parseAcceptTokensMessage,
  parseNonce,
} = require('./lib/utils')

const { get } = require('lodash')

const getPrivateKey = (address) => {
  const wallet = web3.currentProvider.wallets[address.toLowerCase()]
  return `0x${wallet._privKey.toString('hex')}`
}

// const parseAcceptTokensMessage = (message) => {
//   return {
//     pool: message.slice(2,42),
//     selector: message.slice(42, 42+8),
//     from: message.slice(50, 50+40),
//     value: message.slice(90, 90+64),
//     secretHash: message.slice(154, 154+64)  
//   }
// }


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
    
    mlog.log('web3           ', web3.version)
    mlog.log('tokenOwner     ', tokenOwner)
    mlog.log('poolOwner      ', poolOwner)
    mlog.log('user1          ', user1)
    mlog.log('user2          ', user2)
    mlog.log('user3          ', user3)
    mlog.log('val1           ', val1)
    mlog.log('val2           ', val2)
    mlog.log('val3           ', val3)

    token = await Token.deployed()
    pool = await Pool.deployed()

    mlog.log('token contract ', token.address)
    mlog.log('pool contract  ', pool.address)

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
    await pool.requestWithdrawal(val3, { from: user1 })
    for (let i=0; i<240; ++i) {
      await advanceBlock()
    }
    await pool.withdraw({ from: user1 })
    const totalSupply = await pool.totalSupply({ from: poolOwner })
    assert.equal((BigInt(val1)).toString(), totalSupply.toString())
    const availableSupply = await pool.availableSupply({ from: poolOwner })
    assert.equal(BigInt(val1).toString(), availableSupply.toString())
  });

  it('should be able to generate,validate & execute "accept tokens" message', async () => {
    const tokens = 500
    const secret = 'my secret'
    const secretHash = web3.utils.sha3(secret)
    await pool.issueTokens(user1, tokens, secretHash, { from: poolOwner })
    const message = await pool.generateAcceptTokensMessage(user1, tokens, secretHash, { from: poolOwner })
    mlog.log('message: ', message)
    mlog.log(`parsed message: ${JSON.stringify(parseAcceptTokensMessage(message))}`)
    const messageHash = web3.utils.sha3(message)
    const rlp = await web3.eth.accounts.sign(messageHash.slice(2), getPrivateKey(user1))
    mlog.log('rlp', JSON.stringify(rlp))
    mlog.log('recover', web3.eth.accounts.recover({
        messageHash: rlp.messageHash,
        v: rlp.v,
        r: rlp.r,
        s: rlp.s,
    }))
    assert(await pool.validateAcceptTokens(user1, tokens, secretHash, rlp.v, rlp.r, rlp.s, { from: user1 }), 'invalid signature')
    mlog.log('account info: ', JSON.stringify(await pool.account(user1), {from: user1 }))
    await pool.executeAcceptTokens(user1, tokens, Buffer.from(secret), rlp.v, rlp.r, rlp.s, { from: poolOwner} )
    // assert(await pool.validateAcceptTokensMessage(user1, web3.utils.sha3(secret), rlp.v, rlp.r, rlp.s, { from: user1 }), 'invalid signature')
  });

  it('should be able to generate,validate & execute "payment" message', async () => {
    await token.mint(user2, val1, { from: tokenOwner })
    await token.approve(pool.address, val2, { from: user2 })
    await pool.deposit(val3, { from: user2 })
    const message = await pool.generatePaymentMessage(user2, 200, { from: poolOwner })
    mlog.log('message: ', message)
    mlog.log(`parsed message: ${JSON.stringify(parsePaymentMessage(message))}`)
    const rlp = await web3.eth.accounts.sign(web3.utils.sha3(message).slice(2), getPrivateKey(user2))
    mlog.log('rlp', JSON.stringify(rlp))
    mlog.log('recover', web3.eth.accounts.recover({
        messageHash: rlp.messageHash,
        v: rlp.v,
        r: rlp.r,
        s: rlp.s,
    }))
    assert(await pool.validatePayment(user2, 200, rlp.v, rlp.r, rlp.s, { from: user2 }), 'invalid signature')
    mlog.log('account info: ', JSON.stringify(await pool.account(user2), {from: user2 }))
    mlog.log('nonce: ', JSON.stringify(parseNonce((await pool.account(user2,{from: user2 })).nonce)))  
    await advanceTime(1)
    await pool.executePayment(user2, 200, rlp.v, rlp.r, rlp.s, { from: poolOwner} )
    mlog.log('account info: ', JSON.stringify(await pool.account(user2), {from: user2 }))
    mlog.log('nonce: ', JSON.stringify(parseNonce((await pool.account(user2,{from: user2 })).nonce)))
  });

});
