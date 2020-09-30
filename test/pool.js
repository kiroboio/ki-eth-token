'use strict'

const Pool = artifacts.require("Pool")
const Token = artifacts.require("Token")
const mlog = require('mocha-logger')

const { ethers } = require('ethers')
const { TypedDataUtils } = require('ethers-eip712')

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
  sleep,
  pollCondition,
  trNonce,
  sender,
  signTypedMessage,
} = require('./lib/utils')

const { get } = require('lodash')
const { unpadHexString } = require('ethereumjs-util')

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
  let token, pool, DOMAIN_SEPARATOR
  const tokenOwner = accounts[1]
  const poolOwner = accounts[2]
  const user1 = accounts[3]
  const user2 = accounts[4]
  const user3 = accounts[5]
  const user4 = accounts[6]
  const user5 = accounts[7]
  const manager = accounts[8]
  const wallet = accounts[9]

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
      assert(typeof user5       == 'string', 'user4 should be string')
      assert(typeof val1        == 'string', 'val1  should be string')
      assert(typeof val2        == 'string', 'val2  should be string')
      assert(typeof val3        == 'string', 'val2  should be string')
      assert(valBN instanceof web3.utils.BN, 'valBN should be string')
  })

  before('setup contract for the test', async () => {
    
    mlog.log('web3           ', web3.version)

    token = await Token.deployed()
    pool = await Pool.deployed()
    DOMAIN_SEPARATOR = (await pool.DOMAIN_SEPARATOR()).slice(2)

    mlog.log('DOMAIN_SEPARATOR ', DOMAIN_SEPARATOR)
    mlog.log('token contract   ', token.address)
    mlog.log('pool contract    ', pool.address)
    mlog.log('tokenOwner       ', tokenOwner)
    mlog.log('poolOwner        ', poolOwner)
    mlog.log('manager          ', manager)
    mlog.log('wallet           ', wallet)
    mlog.log('user1            ', user1)
    mlog.log('user2            ', user2)
    mlog.log('user3            ', user3)
    mlog.log('user4            ', user4)
    mlog.log('user5            ', user5)
    mlog.log('val1             ', val1)
    mlog.log('val2             ', val2)
    mlog.log('val3             ', val3)

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
    await mustRevert(async ()=> {
      await pool.setManager(user1, { from: manager })
    })
    const entities = await pool.entities({ from: poolOwner })
    assert.equal(entities.manager, manager)    
  })

  it ('should not be able to set manager to pool or token address', async () => {
    let nonce = await trNonce(web3, poolOwner)
    await mustRevert(async ()=> {
      await pool.setManager(token.address, { from: poolOwner, nonce })
    })
    nonce = await trNonce(web3, poolOwner)
    await mustRevert(async ()=> {
      await pool.setManager(pool.address, { from: poolOwner, nonce })
    })
  })

  it('only owner should be able to replace wallet', async () => {
    let nonce = await trNonce(web3, tokenOwner)
    await mustRevert(async ()=> {
      await pool.setWallet(wallet, { from: tokenOwner, nonce})
    })

    nonce = await trNonce(web3, manager)
    await mustRevert(async ()=> {
      await pool.setWallet(wallet, { from: manager, nonce})
    })

    nonce = await trNonce(web3, poolOwner)
    await pool.setWallet(wallet, { from: poolOwner, nonce })
    const entities = await pool.entities({ from: poolOwner })
    assert.equal(entities.wallet, wallet)    
  })

  it ('should not be able to set wallet to pool or token address', async () => {
    let nonce = await trNonce(web3, poolOwner)
    await mustRevert(async ()=> {
      await pool.setWallet(token.address, { from: poolOwner, nonce })
    })
    nonce = await trNonce(web3, poolOwner)
    await mustRevert(async ()=> {
      await pool.setWallet(pool.address, { from: poolOwner, nonce })
    })
  })

  it('only owner should be able to set the release delay', async () => {
    let nonce = await web3.eth.getTransactionCount(tokenOwner)
    await mustRevert(async ()=> {
      await pool.setReleaseDelay(480, { from: tokenOwner, nonce })
    })

    nonce = await web3.eth.getTransactionCount(manager)
    await mustRevert(async ()=> {
      await pool.setReleaseDelay(480, { from: manager, nonce })
    })

    nonce = await trNonce(web3, poolOwner)
    await pool.setReleaseDelay(120, { from: poolOwner, nonce })
    const limits = await pool.limits({ from: poolOwner })
    assert.equal(limits.releaseDelay, 120)    
  })

  it ('release delay should not be able to exceed the max release delay', async () => {
    const maxReleaseDelay = await pool.MAX_RELEASE_DELAY()
    let nonce = await trNonce(web3, poolOwner)
    await mustRevert(async ()=> {
      await pool.setReleaseDelay(maxReleaseDelay+1, { from: poolOwner, nonce })
    })
    nonce = await trNonce(web3, poolOwner)
    await pool.setReleaseDelay(maxReleaseDelay, { from: poolOwner, nonce })
    await pool.setReleaseDelay(120, { from: poolOwner })
  })

  it('only owner should be able to set the max tokens per issue', async () => {
    let nonce = await trNonce(web3, tokenOwner)
    await mustRevert(async ()=> {
      await pool.setMaxTokensPerIssue(2000, { from: tokenOwner, nonce })
    })
    nonce = await trNonce(web3, manager)
    await mustRevert(async ()=> {
      await pool.setMaxTokensPerIssue(2000, { from: manager, nonce })
    })
    await pool.setMaxTokensPerIssue(1200, { from: poolOwner })
    const limits = await pool.limits({ from: poolOwner })
    assert.equal(limits.maxTokensPerIssue, 1200)    
  })

  it('pool should be able to accept tokens', async () => {
    await pool.resyncTotalSupply(await pool.ownedTokens(), { from: poolOwner })
    const initPoolTokens = await token.balanceOf(pool.address, { from: poolOwner })
    assert.equal(initPoolTokens.toString(), 0)
    const nonce = await web3.eth.getTransactionCount(tokenOwner)
    await token.mint(pool.address, val1, { from: tokenOwner, nonce })
    await pool.resyncTotalSupply(await pool.ownedTokens(), { from: poolOwner })
    const balance = await web3.eth.getBalance(pool.address)
    assert.equal(balance.toString(10), web3.utils.toBN('0').toString(10))
    const poolTokens = await token.balanceOf(pool.address, { from: poolOwner })
    assert.equal(poolTokens.toString(), val1)
    const totalSupply = await pool.totalSupply({ from: poolOwner })
    assert.equal(totalSupply.toString(), val1)
  })

  it ('should be able to resync any value as long as (total_supply <= value <= total_tokens) holds', async () => {
    await pool.resyncTotalSupply(await pool.ownedTokens(), { from: poolOwner })
    const initialTokens = +await token.balanceOf(pool.address, { from: poolOwner })
    const initialTotalSupply = +(await pool.supply({ from: poolOwner })).total
    assert.equal(initialTokens, initialTotalSupply)
    await token.mint(pool.address, 500, { from: tokenOwner })
    await mustRevert(async ()=> {
      await pool.resyncTotalSupply(initialTotalSupply-1, { from: poolOwner })
    })
    let nonce = await trNonce(web3, poolOwner)
    await mustRevert(async ()=> {
      await pool.resyncTotalSupply(initialTokens+501, { from: poolOwner, nonce })
    })
    nonce = await trNonce(web3, poolOwner)
    await pool.resyncTotalSupply(initialTokens+200, { from: poolOwner, nonce })
    let totalSupply = +(await pool.supply({ from: poolOwner })).total
    assert.equal(totalSupply, initialTokens+200)
    await pool.transferTokens(200, { from: poolOwner })
    await pool.resyncTotalSupply(initialTokens+300, { from: poolOwner })
    totalSupply = +(await pool.supply({ from: poolOwner })).total
    assert.equal(totalSupply, initialTokens+300)
    await pool.transferTokens(300, { from: poolOwner })
  })

  it('pool should be able to postpone tokens acceptance', async () => {
    await token.mint(pool.address, val2, { from: tokenOwner })
    const poolTokens = await token.balanceOf(pool.address, { from: poolOwner })
    assert.equal(poolTokens.toString(), (BigInt(val1) + BigInt(val2)).toString())
    const initTotalSupply = await pool.totalSupply({ from: poolOwner })
    assert.equal(initTotalSupply.toString(), val1)
    await pool.resyncTotalSupply(await pool.ownedTokens(), { from: poolOwner })
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
    const releaseDelay = +(await pool.limits()).releaseDelay
    await pool.requestWithdrawal(val3, { from: user1 })
    for (let i=0; i<releaseDelay-1; ++i) {
      await advanceBlock()
    }
    await pool.withdrawTokens({ from: user1 })
    const totalSupply = await pool.totalSupply({ from: poolOwner })
    assert.equal((BigInt(val1) + BigInt(val2)).toString(), totalSupply.toString())
    const availableSupply = await pool.availableSupply({ from: poolOwner })
    assert.equal((BigInt(val1) + BigInt(val2)).toString(), availableSupply.toString())
  })

  it('only admins should be able to transfer tokens', async () => {
    let nonce = await trNonce(web3, tokenOwner)
    await mustRevert(async ()=> {
      await pool.transferTokens(480, { from: tokenOwner, nonce })
    })
    await mustRevert(async ()=> {
      await pool.transferTokens(480, { from: user1 })
    })
    nonce = await trNonce(web3, poolOwner)
    await pool.transferTokens(100, { from: poolOwner, nonce })
    nonce = await trNonce(web3, manager)
    await pool.transferTokens(200, { from: manager, nonce })
  })

  it('only admins should be able to distribute tokens', async () => {
    const initialSupply = await pool.supply()
    const initialUser5Balance = +(await pool.account(user5)).balance
    let nonce = await trNonce(web3, tokenOwner)
    await mustRevert(async ()=> {
      await pool.distributeTokens(user5, 480, { from: tokenOwner, nonce })
    })
    nonce = await trNonce(web3, user1)
    await mustRevert(async ()=> {
      await pool.distributeTokens(user5, 480, { from: user1, nonce })
    })
    nonce = await trNonce(web3, poolOwner)
    await pool.distributeTokens(user5, 100, { from: poolOwner, nonce })
    nonce = await trNonce(web3, manager)
    await pool.distributeTokens(user5, 200, { from: manager, nonce })
    const supply = await pool.supply()
    const user5Balance = +(await pool.account(user5)).balance
    assert.equal(+supply.minimum, initialSupply.minimum + 300)
    assert.equal(+user5Balance, initialUser5Balance + 300)
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
    mlog.log('message Hash: ', messageHash.slice(2))
    mlog.log('to sign: ', DOMAIN_SEPARATOR + messageHash.slice(2))
    const rlp = await web3.eth.accounts.sign(DOMAIN_SEPARATOR + messageHash.slice(2), getPrivateKey(user1))
    mlog.log('rlp', JSON.stringify(rlp))
    mlog.log('recover', web3.eth.accounts.recover({
      messageHash: rlp.messageHash,
      v: rlp.v,
      r: rlp.r,
      s: rlp.s,
    }))
    assert(await pool.validateAcceptTokens(user1, tokens, secretHash, rlp.v, rlp.r, rlp.s, false, { from: user1 }), 'invalid signature')
    mlog.log('account info: ', JSON.stringify(await pool.account(user1), {from: user1 }))
    await pool.executeAcceptTokens(user1, tokens, Buffer.from(secret), rlp.v, rlp.r, rlp.s, false, { from: poolOwner} )
  })
  
  it ('should not be able to accept when address, value or secretHash do not match', async () => {
    const secret = 'my secret'
    const secretHash = web3.utils.sha3(secret)
    let nonce = await web3.eth.getTransactionCount(manager)
    await pool.issueTokens(user1, 500, secretHash, { from: manager, nonce })
    nonce = await web3.eth.getTransactionCount(user1)
    await mustRevert(async () => {
      await pool.acceptTokens(100, Buffer.from(secret), { from: user1, nonce } )
    })
    nonce = await web3.eth.getTransactionCount(user1)
    await mustRevert(async () => {
      await pool.acceptTokens(500, Buffer.from(secret+'x'), { from: user1, nonce } )
    })
    nonce = await web3.eth.getTransactionCount(manager)
    await mustRevert(async () => {
      await pool.generateAcceptTokensMessage(user1, 200, secretHash, { from: manager, nonce })
    })
    nonce = await web3.eth.getTransactionCount(manager)
    await mustRevert(async () => {
      await pool.generateAcceptTokensMessage(user2, 500, secretHash, { from: manager, nonce })
    })
    nonce = await web3.eth.getTransactionCount(manager)
    await mustRevert(async () => {
      await pool.generateAcceptTokensMessage(user1, 500, web3.utils.sha3(secret+'x'), { from: manager, nonce })
    })
    nonce = await web3.eth.getTransactionCount(user1)
    await pool.acceptTokens(500, Buffer.from(secret), { from: user1, nonce } )
  })
  
  it('should be able to generate,validate & execute "payment" message', async () => {
    const nonce = await web3.eth.getTransactionCount(tokenOwner)
    await token.mint(user2, val1, { from: tokenOwner, nonce })
    await token.approve(pool.address, val2, { from: user2 })
    await pool.depositTokens(val3, { from: user2 })
    const message = await pool.generatePaymentMessage(user2, 200, { from: poolOwner })
    mlog.log('message: ', message)
    mlog.log(`parsed message: ${JSON.stringify(parsePaymentMessage(message))}`)
    const rlp = await web3.eth.accounts.sign(DOMAIN_SEPARATOR + web3.utils.sha3(message).slice(2), getPrivateKey(user2))
    mlog.log('rlp', JSON.stringify(rlp))
    mlog.log('recover', web3.eth.accounts.recover({
        messageHash: rlp.messageHash,
        v: rlp.v,
        r: rlp.r,
        s: rlp.s,
    }))
    assert(await pool.validatePayment(user2, 200, rlp.v, rlp.r, rlp.s, false, { from: user2 }), 'invalid signature')
    mlog.log('account info: ', JSON.stringify(await pool.account(user2), {from: user2 }))
    mlog.log('nonce: ', JSON.stringify(parseNonce((await pool.account(user2,{from: user2 })).nonce)))  
    await advanceTime(1)
    await pool.executePayment(user2, 200, rlp.v, rlp.r, rlp.s, false, { from: poolOwner} )
    mlog.log('account info: ', JSON.stringify(await pool.account(user2), {from: user2 }))
    mlog.log('nonce: ', JSON.stringify(parseNonce((await pool.account(user2,{from: user2 })).nonce)))
  })

  it ('should not be able to executing the same payment twice', async () => {
    const message = await pool.generatePaymentMessage(user2, 100, { from: manager })
    const rlp = await web3.eth.accounts.sign(DOMAIN_SEPARATOR + web3.utils.sha3(message).slice(2), getPrivateKey(user2))
    assert(await pool.validatePayment(user2, 100, rlp.v, rlp.r, rlp.s, false, { from: user2 }), 'invalid signature')
    const prevNonce = parseNonce((await pool.account(user2,{from: user2 })).nonce)
    await advanceTime(1)
    await pool.executePayment(user2, 100, rlp.v, rlp.r, rlp.s, false, { from: manager} )
    assert.equal(await pool.validatePayment(user2, 100, rlp.v, rlp.r, rlp.s, false, { from: manager }), false)
    await mustRevert(async () => {
      await pool.executePayment(user2, 100, rlp.v, rlp.r, rlp.s, false, { from: manager} )
    })
    let nonce = await web3.eth.getTransactionCount(manager)
    await advanceTime(1)
    assert.equal(await pool.validatePayment(user2, 100, rlp.v, rlp.r, rlp.s, false, { from: manager }), false)
    await mustRevert(async () => {
      await pool.executePayment(user2, 100, rlp.v, rlp.r, rlp.s, false, { from: manager, nonce} )
    })
  })

  it ('should not be able to executing unused passed payments', async () => {
    let nonce = await web3.eth.getTransactionCount(manager)
    const message = await pool.generatePaymentMessage(user2, 700, { from: manager })
    const rlp = await web3.eth.accounts.sign(DOMAIN_SEPARATOR + web3.utils.sha3(message).slice(2), getPrivateKey(user2))
    assert(await pool.validatePayment(user2, 700, rlp.v, rlp.r, rlp.s, false, { from: user2 }), 'invalid signature')
    const newMessage = await pool.generatePaymentMessage(user2, 800, { from: manager })
    const newRlp = await web3.eth.accounts.sign(DOMAIN_SEPARATOR + web3.utils.sha3(newMessage).slice(2), getPrivateKey(user2))
    assert(await pool.validatePayment(user2, 800, newRlp.v, newRlp.r, newRlp.s, false, { from: manager }), 'invalid signature')
    await pool.executePayment(user2, 800, newRlp.v, newRlp.r, newRlp.s, false, { from: manager, nonce} )
    await mustRevert(async () => {
      await pool.executePayment(user2, 700, rlp.v, rlp.r, rlp.s, false, { from: manager} )
    })
    await advanceTime(1)
    nonce = await web3.eth.getTransactionCount(manager)
    assert.equal(await pool.validatePayment(user2, 700, rlp.v, rlp.r, rlp.s, false, { from: manager }), false)
    await mustRevert(async () => {
      await pool.executePayment(user2, 700, rlp.v, rlp.r, rlp.s, false, { from: manager, nonce} )
    })
  })

  it('only available supply can be transferred', async () => {
    let nonce = await web3.eth.getTransactionCount(manager)
    let availableSupply = await pool.availableSupply({ from: manager })
    await mustRevert(async ()=> {
      await pool.transferTokens((BigInt(availableSupply) + 1n).toString(), { from: manager, nonce })
    })
    nonce = await web3.eth.getTransactionCount(manager)
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
    await pool.resyncTotalSupply(await pool.ownedTokens(), { from: poolOwner })
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

  it ('should change account\'s nonce when executing payment', async() => {
    const message = await pool.generatePaymentMessage(user2, 500, { from: poolOwner })
    const rlp = await web3.eth.accounts.sign(DOMAIN_SEPARATOR + web3.utils.sha3(message).slice(2), getPrivateKey(user2))
    assert(await pool.validatePayment(user2, 500, rlp.v, rlp.r, rlp.s, false, { from: user2 }), 'invalid signature')
    mlog.log('nonce: ', JSON.stringify(parseNonce((await pool.account(user2,{from: user2 })).nonce)))  
    const prevNonce = parseNonce((await pool.account(user2,{from: user2 })).nonce)
    await advanceTime(1)
    await pool.executePayment(user2, 500, rlp.v, rlp.r, rlp.s, false, { from: poolOwner} )
    const newNonce = parseNonce((await pool.account(user2,{from: user2 })).nonce)
    assert.notEqual(prevNonce.count, newNonce.count)
    assert.notEqual(prevNonce.salt, newNonce.salt)
    assert.notEqual(prevNonce.timestamp, newNonce.timestamp)
  })

  it ('should sync pending supply when issuing tokens multiple times', async () => {
    const initPendingSupply = +(await pool.supply({ from: manager })).pending
    const secret = 'my secret 3'
    const secretHash = web3.utils.sha3(secret)
    await pool.issueTokens(user4, 600, secretHash, { from: manager })
    assert.equal(initPendingSupply + 600, +(await pool.supply({ from: manager })).pending)
    await pool.issueTokens(user4, 100, secretHash, { from: manager })
    assert.equal(initPendingSupply + 100, +(await pool.supply({ from: manager })).pending)
    await pool.issueTokens(user4, 300, secretHash, { from: manager })
    assert.equal(initPendingSupply + 300, +(await pool.supply({ from: manager })).pending)
    await pool.acceptTokens(300, Buffer.from(secret), { from: user4 })
    assert.equal(initPendingSupply, +(await pool.supply({ from: manager })).pending)
    await pool.issueTokens(user4, 400, secretHash, { from: manager })
    assert.equal(initPendingSupply + 400, +(await pool.supply({ from: manager })).pending)
    await pool.issueTokens(user4, 700, secretHash, { from: manager })
    assert.equal(initPendingSupply + 700, +(await pool.supply({ from: manager })).pending)
    await pool.issueTokens(user4, 200, secretHash, { from: manager })
    assert.equal(initPendingSupply + 200, +(await pool.supply({ from: manager })).pending)
    const message = await pool.generateAcceptTokensMessage(user4, 200, secretHash, { from: manager })
    const messageHash = web3.utils.sha3(message)
    const rlp = await web3.eth.accounts.sign(DOMAIN_SEPARATOR + messageHash.slice(2), getPrivateKey(user4))
    assert(await pool.validateAcceptTokens(user4, 200, secretHash, rlp.v, rlp.r, rlp.s, false, { from: manager }), 'invalid signature')
    await pool.executeAcceptTokens(user4, 200, Buffer.from(secret), rlp.v, rlp.r, rlp.s, false, { from: manager} )
    assert.equal(initPendingSupply, +(await pool.supply({ from: manager })).pending)
  })

  it ('should sync pending supply when issuing tokens to multiple accounts', async () => {
    const initPendingSupply = +(await pool.supply({ from: manager })).pending
    const secret = 'my secret 3'
    const secretHash = web3.utils.sha3(secret)
    await pool.issueTokens(user4, 600, secretHash, { from: manager })
    assert.equal(initPendingSupply + 600, +(await pool.supply({ from: manager })).pending)
    await pool.issueTokens(user2, 100, secretHash, { from: manager })
    assert.equal(initPendingSupply + 700, +(await pool.supply({ from: manager })).pending)
    await pool.issueTokens(user4, 300, secretHash, { from: manager })
    assert.equal(initPendingSupply + 400, +(await pool.supply({ from: manager })).pending)
    await pool.issueTokens(user3, 400, secretHash, { from: manager })
    assert.equal(initPendingSupply + 800, +(await pool.supply({ from: manager })).pending)
    await pool.issueTokens(user2, 0, secretHash, { from: manager })
    assert.equal(initPendingSupply + 700, +(await pool.supply({ from: manager })).pending)
    const message = await pool.generateAcceptTokensMessage(user4, 300, secretHash, { from: manager })
    const messageHash = web3.utils.sha3(message)
    const rlp = await web3.eth.accounts.sign(DOMAIN_SEPARATOR + messageHash.slice(2), getPrivateKey(user4))
    assert(await pool.validateAcceptTokens(user4, 300, secretHash, rlp.v, rlp.r, rlp.s, false, { from: manager }), 'invalid signature')
    await pool.executeAcceptTokens(user4, 300, Buffer.from(secret), rlp.v, rlp.r, rlp.s, false, { from: manager} )
    assert.equal(initPendingSupply + 400, +(await pool.supply({ from: manager })).pending)
    await pool.acceptTokens(400, Buffer.from(secret), { from: user3 })
    assert.equal(initPendingSupply, +(await pool.supply({ from: manager })).pending)
  })

  it ('should not be able to accept past pending tokens', async () => {
    const initPendingSupply = +(await pool.supply({ from: manager })).pending
    const secret = 'my secret 3'
    const secretHash = web3.utils.sha3(secret)
    await pool.issueTokens(user4, 600, secretHash, { from: manager })
    const message = await pool.generateAcceptTokensMessage(user4, 600, secretHash, { from: manager })
    await pool.issueTokens(user4, 100, secretHash, { from: manager })
    await mustRevert(async ()=> {
      await pool.generateAcceptTokensMessage(user4, 600, secretHash, { from: manager })
    })
    let nonce = await web3.eth.getTransactionCount(manager)
    const messageHash = web3.utils.sha3(message)
    const rlp = await web3.eth.accounts.sign(DOMAIN_SEPARATOR + messageHash.slice(2), getPrivateKey(user4))
    await mustRevert(async ()=> {
      assert(await pool.validateAcceptTokens(user4, 600, secretHash, rlp.v, rlp.r, rlp.s, false, { from: manager, nonce }), 'invalid signature')
    })
    nonce = await web3.eth.getTransactionCount(manager)
    await mustRevert(async ()=> {
      await pool.executeAcceptTokens(user4, 600, Buffer.from(secret), rlp.v, rlp.r, rlp.s, false, { from: manager, nonce} )
    })
    nonce = await web3.eth.getTransactionCount(manager)
    await mustRevert(async ()=> {
      await pool.acceptTokens(600, Buffer.from(secret), { from: user4 })
    })
    nonce = await web3.eth.getTransactionCount(user4)
    await pool.acceptTokens(100, Buffer.from(secret), { from: user4, nonce })
  })

  it ('account should not be able to withdraw before release delay has been reached', async () => {
    const userInitTokens = +await token.balanceOf(user5)
    const releaseDelay = +(await pool.limits()).releaseDelay
    const secret = 'my secret 4'
    const secretHash = web3.utils.sha3(secret)
    const user5InitialBalance = +(await pool.account(user5)).balance
    let nonce = await web3.eth.getTransactionCount(manager)
    await token.mint(user5, 500, { from: tokenOwner })
    await token.approve(pool.address, 400, { from: user5 })
    await pool.depositTokens(300, { from: user5 })
    await pool.issueTokens(user5, 100, secretHash, { from: manager, nonce })
    await pool.acceptTokens(100, Buffer.from(secret), { from: user5 })
    let account = await pool.account(user5)
    assert.equal(+account.balance, 400 + user5InitialBalance)
    await pool.requestWithdrawal(300, { from: user5 })
    nonce = await web3.eth.getTransactionCount(user5)
    await mustRevert(async ()=> {
      await pool.withdrawTokens({ from: user5, nonce }) // 1
    })
    for (let i=0; i<releaseDelay-1; ++i) {
      await advanceBlock()
    }
    nonce = await web3.eth.getTransactionCount(user5)
    await pool.requestWithdrawal(200, { from: user5, nonce })
    await mustRevert(async ()=> {
      await pool.withdrawTokens({ from: user5 }) // 2
    })
    for (let i=0; i<releaseDelay-3; ++i) {
      await advanceBlock()
    }
    nonce = await web3.eth.getTransactionCount(user5)
    await mustRevert(async ()=> {
      await pool.withdrawTokens({ from: user5, nonce }) // 3 
    })
    nonce = await web3.eth.getTransactionCount(user5)
    await pool.withdrawTokens({ from: user5, nonce })
    const userTokens = +await token.balanceOf(user5)
    assert.equal(userTokens, userInitTokens+500-300+200)
  })

  it ('account should always be able to cancel withdrawal', async () => {
    const releaseDelay = +(await pool.limits()).releaseDelay
    await pool.requestWithdrawal(200, { from: user5 })
    await pool.cancelWithdrawal({ from: user5 })
    let account = await pool.account(user5)
    assert.equal(account.withdrawal, 0)
    await mustRevert(async ()=> {
      await pool.withdrawTokens({ from: user5 }) // 1
    })
    let nonce = await web3.eth.getTransactionCount(user5)
    await pool.requestWithdrawal(200, { from: user5, nonce })
    for (let i=0; i<releaseDelay-1; ++i) {
      await advanceBlock()
    }
    await pool.cancelWithdrawal({ from: user5 })
    account = await pool.account(user5)
    assert.equal(account.withdrawal, 0)
    await mustRevert(async ()=> {
      await pool.withdrawTokens({ from: user5 }) // 2
    })
  })

  it ('request for a withdrawal cancels former requests', async () => {
    const secret = 'my secret 5'
    const secretHash = web3.utils.sha3(secret)
    let nonce = await web3.eth.getTransactionCount(user5)
    await pool.issueTokens(user5, 1000, secretHash, { from: manager })
    await pool.acceptTokens(1000, Buffer.from(secret), { from: user5, nonce })
    await pool.requestWithdrawal(200, { from: user5 })
    await pool.requestWithdrawal(700, { from: user5 })
    await pool.requestWithdrawal(100, { from: user5 })
    await pool.requestWithdrawal(300, { from: user5 })
    let balance = +(await pool.account(user5)).balance
    const releaseDelay = +(await pool.limits()).releaseDelay
    for (let i=0; i<releaseDelay-1; ++i) {
      await advanceBlock()
    }
    await pool.withdrawTokens({ from: user5 })
    assert.equal(balance-300, +(await pool.account(user5)).balance)
  })

  it ('setting the release delay does not affect existing withdrawal requests', async () => {
    const userInitTokens = +await token.balanceOf(user5)
    let balance = +(await pool.account(user5)).balance
    let releaseDelay = +(await pool.limits()).releaseDelay
    await pool.requestWithdrawal(300, { from: user5 })
    await pool.setReleaseDelay(240, { from: poolOwner })
    for (let i=0; i<releaseDelay-1; ++i) {
      await advanceBlock()
    }
    await pool.withdrawTokens({ from: user5 })
    assert.equal(balance-300, +(await pool.account(user5)).balance)
    await pool.setReleaseDelay(120, { from: poolOwner })
    releaseDelay = +(await pool.limits()).releaseDelay
    await pool.requestWithdrawal(300, { from: user5 })
    await pool.setReleaseDelay(100, { from: poolOwner })
    for (let i=0; i<100-1; ++i) {
      await advanceBlock()
    }
    await mustRevert(async ()=> {
      await pool.withdrawTokens({ from: user5 })
    })
    for (let i=0; i<20-1; ++i) {
      await advanceBlock()
    }
    let nonce = await web3.eth.getTransactionCount(user5)
    await pool.withdrawTokens({ from: user5, nonce })
    assert.equal(balance-600, +(await pool.account(user5)).balance)
    const userTokens = +await token.balanceOf(user5)
    assert.equal(userTokens, userInitTokens + 600)
  })

  it ('account should be able to withdraw all non-pending balance', async () => {    
    await pool.issueTokens(user5, 600, web3.utils.sha3('secret'), { from: manager })
    await pool.acceptTokens(600, Buffer.from('secret'), { from: user5 })
    const user5InitTokens = +await token.balanceOf(user5)
    const user5InitBalance = +(await pool.account(user5)).balance
    await pool.requestWithdrawal(user5InitBalance, { from: user5 })
    const releaseDelay = +(await pool.limits()).releaseDelay
    for (let i=0; i<releaseDelay-1; ++i) {
      await advanceBlock()
    }
    await pool.issueTokens(user5, 235, web3.utils.sha3('secret'), { from: manager})
    const message = await pool.generatePaymentMessage(user5, 20, { from: manager })
    const rlp = await web3.eth.accounts.sign(DOMAIN_SEPARATOR + web3.utils.sha3(message).slice(2), getPrivateKey(user5))
    assert(await pool.validatePayment(user5, 20, rlp.v, rlp.r, rlp.s, false, { from: manager }), 'invalid signature')
    await advanceTime(1)
    await pool.executePayment(user5, 20, rlp.v, rlp.r, rlp.s, false, { from: manager } )  
    await pool.withdrawTokens({ from: user5 })
    const user5Balance = +(await pool.account(user5)).balance
    assert.equal(user5Balance, 0) 
    const user5Tokens = +await token.balanceOf(user5)
    assert.equal(user5Tokens, user5InitTokens + user5InitBalance - 20) 
  })

  it('supply & accounts info should be accurate after extensive use of the system', async () => {
    await pool.issueTokens(user5, 235, web3.utils.sha3('secret'), { from: manager})
    const initSupply = await pool.supply()
    const user1InitAccount = await pool.account(user1)
    const user2InitAccount = await pool.account(user2)
    const user3InitAccount = await pool.account(user3)
    const user4InitAccount = await pool.account(user4)
    const user5InitAccount = await pool.account(user5)
    const user1InitTokens = +await token.balanceOf(user1)
    const user2InitTokens = +await token.balanceOf(user2)
    const user3InitTokens = +await token.balanceOf(user3)
    const user4InitTokens = +await token.balanceOf(user4)
    const user5InitTokens = +await token.balanceOf(user5)
    await pool.issueTokens(user1, 600, web3.utils.sha3('secret1'), { from: manager })
    await pool.acceptTokens(600, Buffer.from('secret1'), { from: user1 })
    await pool.issueTokens(user1, 100, web3.utils.sha3('secret1'), { from: manager })
    await pool.requestWithdrawal(200, { from: user1 })
    await pool.issueTokens(user2, 300, web3.utils.sha3('secret2'), { from: manager })
    await pool.acceptTokens(300, Buffer.from('secret2'), { from: user2 })
    await token.mint(user3, 700, { from: tokenOwner })
    await token.approve(pool.address, 200, { from: user3 })
    await pool.depositTokens(100, { from: user3 })
    await pool.issueTokens(user4, 700, web3.utils.sha3('secret4'), { from: manager })
    let message = await pool.generateAcceptTokensMessage(user4, 700, web3.utils.sha3('secret4'), { from: manager })
    let messageHash = web3.utils.sha3(message)
    let rlp = await web3.eth.accounts.sign(DOMAIN_SEPARATOR + messageHash.slice(2), getPrivateKey(user4))
    assert(await pool.validateAcceptTokens(user4, 700, web3.utils.sha3('secret4'), rlp.v, rlp.r, rlp.s, false, { from: user1 }), 'invalid signature')
    await pool.executeAcceptTokens(user4, 700, Buffer.from('secret4'), rlp.v, rlp.r, rlp.s, false, { from: poolOwner} )
    await pool.issueTokens(user4, 100, web3.utils.sha3('secret4'), { from: manager })
    const releaseDelay = +(await pool.limits()).releaseDelay
    await pool.requestWithdrawal(200, { from: user4 })
    await token.mint(user4, 500, { from: tokenOwner })
    await token.approve(pool.address, 500, { from: user4 })
    await pool.depositTokens(500, { from: user4 })
    await pool.transferTokens(300, { from: manager})
    for (let i=0; i<releaseDelay-1; ++i) {
      await advanceBlock()
    }
    await pool.withdrawTokens({ from: user4 })
    await token.mint(user5, 200, { from: tokenOwner })
    await token.approve(pool.address, 200, { from: user5 })
    await pool.depositTokens(200, { from: user5 })
    message = await pool.generatePaymentMessage(user5, 120, { from: manager })
    rlp = await web3.eth.accounts.sign(DOMAIN_SEPARATOR + web3.utils.sha3(message).slice(2), getPrivateKey(user5))
    assert(await pool.validatePayment(user5, 120, rlp.v, rlp.r, rlp.s, false, { from: manager }), 'invalid signature')
    await advanceTime(1)
    await pool.executePayment(user5, 120, rlp.v, rlp.r, rlp.s, false, { from: manager } )  
    await pool.issueTokens(user5, 800, web3.utils.sha3('secret5'), { from: manager })
    message = await pool.generateAcceptTokensMessage(user5, 800, web3.utils.sha3('secret5'), { from: manager })
    messageHash = web3.utils.sha3(message)
    rlp = await web3.eth.accounts.sign(DOMAIN_SEPARATOR + messageHash.slice(2), getPrivateKey(user5))
    assert(await pool.validateAcceptTokens(user5, 800, web3.utils.sha3('secret5'), rlp.v, rlp.r, rlp.s, false, { from: user5 }), 'invalid signature')
    await pool.executeAcceptTokens(user5, 800, Buffer.from('secret5'), rlp.v, rlp.r, rlp.s, false, { from: poolOwner} )
    const supply = await pool.supply()
    const user1Account = await pool.account(user1)
    const user2Account = await pool.account(user2)
    const user3Account = await pool.account(user3)
    const user4Account = await pool.account(user4)
    const user5Account = await pool.account(user5)
    const user1Tokens = +await token.balanceOf(user1)
    const user2Tokens = +await token.balanceOf(user2)
    const user3Tokens = +await token.balanceOf(user3)
    const user4Tokens = +await token.balanceOf(user4)
    const user5Tokens = +await token.balanceOf(user5)
    assert.equal(+supply.total, +initSupply.total + 300) 
    assert.equal(+supply.minimum, +initSupply.minimum + 2880) 
    assert.equal(+supply.pending, +initSupply.pending - 35) 
    assert.equal(+supply.available, +initSupply.available - 2545) 
    assert.equal(+user1Account.balance, +user1InitAccount.balance + 600)
    assert.equal(+user1Account.pending, +user1InitAccount.pending + 100) 
    assert.equal(+user1Account.withdrawal, +user1InitAccount.withdrawal + 200)
    assert.equal(+user2Account.balance, +user2InitAccount.balance + 300) 
    assert.equal(+user2Account.pending, +user2InitAccount.pending) 
    assert.equal(+user2Account.withdrawal, +user2InitAccount.withdrawal) 
    assert.equal(+user3Account.balance, +user3InitAccount.balance + 100) 
    assert.equal(+user3Account.pending, +user3InitAccount.pending) 
    assert.equal(+user3Account.withdrawal, +user3InitAccount.withdrawal) 
    assert.equal(+user4Account.balance, +user4InitAccount.balance + 1000)
    assert.equal(+user4Account.pending, +user4InitAccount.pending + 100) 
    assert.equal(+user4Account.withdrawal, +user4InitAccount.withdrawal) 
    assert.equal(+user5Account.balance, +user5InitAccount.balance + 880) 
    assert.equal(+user5Account.pending, +user5InitAccount.pending - 235) 
    assert.equal(+user5Account.withdrawal, +user5InitAccount.withdrawal) 
    assert.equal(user1Tokens, +user1Account.externalBalance) 
    assert.equal(user2Tokens, +user2Account.externalBalance) 
    assert.equal(user3Tokens, +user3Account.externalBalance) 
    assert.equal(user4Tokens, +user4Account.externalBalance) 
    assert.equal(user5Tokens, +user5Account.externalBalance) 
    assert.equal(user1Tokens, user1InitTokens) 
    assert.equal(user2Tokens, user2InitTokens) 
    assert.equal(user3Tokens, user3InitTokens + 600) 
    assert.equal(user4Tokens, user4InitTokens + 200) 
    assert.equal(user5Tokens, user5InitTokens) 
  })

  it('eip712: should be able to generate,validate & execute "accept tokens" message', async () => {
    const tokens = 500
    const secret = 'my secret'
    const secretHash = web3.utils.sha3(secret)
    await pool.issueTokens(user1, tokens, secretHash, { from: poolOwner })
    const message = await pool.generateAcceptTokensMessage(user1, tokens, secretHash, { from: poolOwner })
    mlog.log('message: ', message)
    const typedData = {
      types: {
        EIP712Domain: [
          { name: "name",               type: "string" },
          { name: "version",            type: "string" },
          { name: "chainId",            type: "uint256" },
          { name: "verifyingContract",  type: "address" },
          { name: "salt",               type: "uint256" }
        ],
        AcceptTokens: [
          { name: 'ACCEPT_TYPEHASH',    type: 'bytes32' },
          { name: 'recipient',          type: 'address' },
          { name: 'value',              type: 'uint256' },
          { name: 'secretHash',         type: 'bytes32' },
        ]
      },
      primaryType: 'AcceptTokens',
      domain: {
        name: await pool.NAME(),
        version: await pool.VERSION(),
        chainId: await web3.eth.net.getId(),
        verifyingContract: pool.address,
        salt: await pool.uid(),
      },
      message: {
        ACCEPT_TYPEHASH: await pool.ACCEPT_TYPEHASH(),
        recipient: user1,
        value: tokens,
        secretHash,
      }
    }
    
    const messageDigest = TypedDataUtils.encodeDigest(typedData)
    const messageDigestHex = ethers.utils.hexlify(messageDigest)
    const wallet = new ethers.Wallet(getPrivateKey(user1))
    const sig = await wallet.signMessage(messageDigest)
    const rlp = ethers.utils.splitSignature(sig)
    rlp.v = '0x' + rlp.v.toString(16)
    const messageHash = messageDigestHex.slice(2)
    mlog.log('messageHash', messageHash)
    mlog.log('rlp', JSON.stringify(rlp))
    mlog.log('recover', ethers.utils.recoverAddress(messageDigest, sig))
    assert(await pool.validateAcceptTokens(user1, tokens, secretHash, rlp.v, rlp.r, rlp.s, true, { from: user1 }), 'invalid signature')
    mlog.log('account info: ', JSON.stringify(await pool.account(user1), {from: user1 }))
    await pool.executeAcceptTokens(user1, tokens, Buffer.from(secret), rlp.v, rlp.r, rlp.s, true, { from: poolOwner} )
  })
  
  
})
