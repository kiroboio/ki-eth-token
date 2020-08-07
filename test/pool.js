'use strict'

const Pool = artifacts.require("Pool")
const Token = artifacts.require("KiroboToken")
const mlog = require('mocha-logger')

const {
  assertRevert,
  assertInvalidOpcode,
  assertPayable,
  assetEvent_getArgs,
  assertFunction, 
  mustFail,
  mustRevert,
} = require('./lib/asserts')

const { 
  advanceBlock,
  advanceTime,
  advanceTimeAndBlock,
  parsePaymentMessage,
  parseAcceptTokensMessage,
  parseNonce,
  sleep
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
  const user4 = accounts[6]
  const manager = accounts[7]
  const wallet = accounts[8]

  const val1  = web3.utils.toWei('0.5', 'gwei')
  const val2  = web3.utils.toWei('0.4', 'gwei')
  const val3  = web3.utils.toWei('0.3', 'gwei')
  const valBN = web3.utils.toBN('0')

  before('checking constants', async () => {
      assert(typeof tokenOwner  == 'string', 'tokenOwner should be string')
      assert(typeof poolOwner   == 'string', 'poolOwner should be string')
      assert(typeof manager     == 'string', 'manager should be string')
      assert(typeof wallet      == 'string', 'wallet should be string')
      assert(typeof user1       == 'string', 'user1 should be string')
      assert(typeof user2       == 'string', 'user2 should be string')
      assert(typeof user3       == 'string', 'user3 should be string')
      assert(typeof user4       == 'string', 'user4 should be string')
      assert(typeof val1        == 'string', 'val1  should be string')
      assert(typeof val2        == 'string', 'val2  should be string')
      assert(typeof val3        == 'string', 'val2  should be string')
      assert(valBN instanceof web3.utils.BN, 'valBN should be string')
  })

  before('setup contract for the test', async () => {
    
    mlog.log('web3           ', web3.version)
    mlog.log('tokenOwner     ', tokenOwner)
    mlog.log('poolOwner      ', poolOwner)
    mlog.log('manager        ', manager)
    mlog.log('wallet         ', wallet)
    mlog.log('user1          ', user1)
    mlog.log('user2          ', user2)
    mlog.log('user3          ', user3)
    mlog.log('user4          ', user4)
    mlog.log('val1           ', val1)
    mlog.log('val2           ', val2)
    mlog.log('val3           ', val3)

    token = await Token.deployed()
    pool = await Pool.deployed()

    mlog.log('token contract ', token.address)
    mlog.log('pool contract  ', pool.address)

  })

  it('should create an empty pool', async () => {
    const balance = await web3.eth.getBalance(pool.address)
    assert.equal(balance.toString(10), web3.utils.toBN('0').toString(10))
  })

  it('should not accept ether', async () => {
    await mustFail(async ()=> {
      await web3.eth.sendTransaction({ from: poolOwner, to: pool.address, value: 10 })
    })
  })

  it('should not set manager address on creation', async () => {
    const entities = await pool.entities({ from: poolOwner })
    assert.equal(entities.manager, 0)
  })

  it('should not set wallet address on creation', async () => {
    const entities = await pool.entities({ from: poolOwner })
    assert.equal(entities.wallet, 0)
  })

  it('should set token on creation', async () => {
    const entities = await pool.entities({ from: poolOwner })
    assert.equal(entities.token, token.address)
  })

  it('only owner should be able to replace manager', async () => {
    await mustRevert(async ()=> {
      await pool.setManager(manager, { from: tokenOwner })
    })
    await pool.setManager(manager, { from: poolOwner })
    const entities = await pool.entities({ from: poolOwner })
    assert.equal(entities.manager, manager)    
  })

  it ('should not be able to set manager to pool or token address')

  it('only owner should be able to replace wallet', async () => {
    const nonce = await web3.eth.getTransactionCount(tokenOwner)
    await mustRevert(async ()=> {
      await pool.setWallet(wallet, { from: tokenOwner, nonce })
    }, tokenOwner)

    await pool.setWallet(wallet, { from: poolOwner })
    const entities = await pool.entities({ from: poolOwner })
    assert.equal(entities.wallet, wallet)    
  })

  it ('should not be able to set wallet to pool or token address')

  it('only owner should be able to set the release delay', async () => {
    const nonce = await web3.eth.getTransactionCount(tokenOwner)
    await mustRevert(async ()=> {
      await pool.setReleaseDelay(480, { from: tokenOwner, nonce })
    }, tokenOwner)

    await pool.setReleaseDelay(120, { from: poolOwner })
    const limits = await pool.limits({ from: poolOwner })
    assert.equal(limits.releaseDelay, 120)    
  })

  it ('release delay should not be able to exceed the max release delay')

  it('only owner should be able to set the max tokens per issue', async () => {
    const nonce = await web3.eth.getTransactionCount(tokenOwner)
    await mustRevert(async ()=> {
      await pool.setMaxTokensPerIssue(2000, { from: tokenOwner, nonce })
    }, tokenOwner)

    await pool.setMaxTokensPerIssue(1200, { from: poolOwner })
    const limits = await pool.limits({ from: poolOwner })
    assert.equal(limits.maxTokensPerIssue, 1200)    
  })

  it('pool should be able to accept tokens', async () => {
    const nonce = await web3.eth.getTransactionCount(tokenOwner)
    await pool.resyncTotalSupply({ from: poolOwner })
    const initPoolTokens = await token.balanceOf(pool.address, { from: poolOwner })
    assert.equal(initPoolTokens.toString(), 0)
    await token.mint(pool.address, val1, { from: tokenOwner, nonce })
    await pool.resyncTotalSupply({ from: poolOwner })
    const balance = await web3.eth.getBalance(pool.address)
    assert.equal(balance.toString(10), web3.utils.toBN('0').toString(10))
    const poolTokens = await token.balanceOf(pool.address, { from: poolOwner })
    assert.equal(poolTokens.toString(), val1)
    const totalSupply = await pool.totalSupply({ from: poolOwner })
    assert.equal(totalSupply.toString(), val1)
  })

  it('pool should be able to postpone tokens acceptance', async () => {
    await token.mint(pool.address, val2, { from: tokenOwner })
    const poolTokens = await token.balanceOf(pool.address, { from: poolOwner })
    assert.equal(poolTokens.toString(), (BigInt(val1) + BigInt(val2)).toString())
    const initTotalSupply = await pool.totalSupply({ from: poolOwner })
    assert.equal(initTotalSupply.toString(), val1)
    await pool.resyncTotalSupply({ from: poolOwner })
    const totalSupply = await pool.totalSupply({ from: poolOwner })
    assert.equal(totalSupply.toString(), (BigInt(val1) + BigInt(val2)).toString())
  })

  it('user should be able to deposit tokens', async () => {
    await token.mint(user1, val2, { from: tokenOwner })
    await token.approve(pool.address, val3, { from: user1 })
    await pool.depositTokens(val3, { from: user1 })
    const totalSupply = await pool.totalSupply({ from: poolOwner })
    assert.equal((BigInt(val1) + BigInt(val2) + BigInt(val3)).toString(), totalSupply.toString())
    const availableSupply = await pool.availableSupply({ from: poolOwner })
    assert.equal((BigInt(val1) + BigInt(val2)).toString(), availableSupply.toString())
  })

  it('user should be able to withdraw tokens', async () => {
    await pool.requestWithdrawal(val3, { from: user1 })
    for (let i=0; i<240; ++i) {
      await advanceBlock()
    }
    await pool.withdrawTokens({ from: user1 })
    const totalSupply = await pool.totalSupply({ from: poolOwner })
    assert.equal((BigInt(val1) + BigInt(val2)).toString(), totalSupply.toString())
    const availableSupply = await pool.availableSupply({ from: poolOwner })
    assert.equal((BigInt(val1) + BigInt(val2)).toString(), availableSupply.toString())
  })

  it('only admins should be able to transfer tokens', async () => {
    let nonce = await web3.eth.getTransactionCount(tokenOwner)
    await mustRevert(async ()=> {
      await pool.transferTokens(480, { from: tokenOwner, nonce })
    })
    await mustRevert(async ()=> {
      await pool.transferTokens(480, { from: user1 })
    })
    nonce = await web3.eth.getTransactionCount(poolOwner)
    await pool.transferTokens(100, { from: poolOwner, nonce })
    nonce = await web3.eth.getTransactionCount(manager)
    await pool.transferTokens(200, { from: manager, nonce })
  })
  
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
  })
  
  it ('should not be able to accept when address, value or secretHash do not match')
  
  it('should be able to generate,validate & execute "payment" message', async () => {
    const nonce = await web3.eth.getTransactionCount(tokenOwner)
    await token.mint(user2, val1, { from: tokenOwner, nonce })
    await token.approve(pool.address, val2, { from: user2 })
    await pool.depositTokens(val3, { from: user2 })
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
  })

  it ('should not be able to executing the same payment twice')
  it ('should not be able to executing unused passed payments')


  it('only available supply can be transferred', async () => {
    let availableSupply = await pool.availableSupply({ from: manager })
    await mustRevert(async ()=> {
      await pool.transferTokens((BigInt(availableSupply) + 1n).toString(), { from: manager })
    })
    let nonce = await web3.eth.getTransactionCount(manager)
    await pool.transferTokens(200, { from: manager, nonce })
    assert.equal(BigInt(availableSupply) - 200n, await pool.availableSupply({ from: manager }))
    availableSupply = await pool.availableSupply({ from: manager })
    await pool.transferTokens(availableSupply.toString(), { from: manager})
    availableSupply = await pool.availableSupply({ from: manager })
    assert.equal(0, availableSupply.toString())
  })

  it ('should change account\'s nonce when issuing or depositing tokens if nonce was not initialized yet', async () => {
    let account = await pool.account(user3)
    assert.equal(account.nonce + '', 0)
    await token.mint(user3, val1, { from: tokenOwner })
    await token.approve(pool.address, val2, { from: user3 })
    await pool.depositTokens(val3, { from: user3 })
    account = await pool.account(user3)
    assert.notEqual(account.nonce + '', 0)
    
    account = await pool.account(user4)
    assert.equal(account.nonce + '', 0)
    const secret = 'my secret 2'
    const secretHash = web3.utils.sha3(secret)
    await token.mint(pool.address, val1, { from: tokenOwner })
    await pool.resyncTotalSupply({ from: poolOwner })
    await pool.issueTokens(user4, 600, secretHash, { from: manager })
    await pool.acceptTokens(600, Buffer.from('my secret 2'), { from: user4 })
    account = await pool.account(user4)
    assert.notEqual(account.nonce + '', 0)
  })

  it ('should not change account\'s nonce when issuing or depositing tokens if nonce was set', async () => {
    let account = await pool.account(user3)
    let nonce = account.nonce + ''
    await token.mint(user3, val1, { from: tokenOwner })
    await token.approve(pool.address, val2, { from: user3 })
    await pool.depositTokens(val3, { from: user3 })
    account = await pool.account(user3)
    assert.equal(account.nonce + '', nonce)
    
    account = await pool.account(user4)
    nonce = account.nonce + ''
    const secret = 'my secret 3'
    const secretHash = web3.utils.sha3(secret)
    await pool.issueTokens(user4, 700, secretHash, { from: manager })
    await pool.acceptTokens(700, Buffer.from('my secret 3'), { from: user4 })
    account = await pool.account(user4)
    assert.equal(account.nonce + '', nonce)
  })

  it ('should change account\'s nonce when executing payment')
  it ('should sync pending supply when issuing tokens multiple times')
  it ('should sync pending supply when issuing tokens to multiple account')
  it ('account should not be able to withdraw before release delay has been reached')
  it ('account should always be able to cancel withdrawal')
  it ('account should be able to withdraw all non-pending balance')
  it ('limits should be accurate after extensive usage of the system')
  it ('account\'s info should be accurate after extensive usage of the system')

})
