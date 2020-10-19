'use strict'

const Token = artifacts.require("Token")
const SafeTransfer = artifacts.require('SafeTransfer')
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

contract('SafeTransfer', async accounts => {
  let token, st, nonce, targetSupply, duration, initialSupply

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
    token = await Token.new({ from: tokenOwner })
    st = await SafeTransfer.new({ from: user1 })
    mlog.log('web3                    ', web3.version)
    mlog.log('token contract          ', token.address)
    mlog.log('safe transfer contract  ', st.address)
    mlog.log('token Owner             ', tokenOwner)
    mlog.log('user1                   ', user1)
    mlog.log('user2                   ', user2)
    mlog.log('user3                   ', user3)
    mlog.log('user4                   ', user4)
    mlog.log('val1                    ', val1)
    mlog.log('val2                    ', val2)
    mlog.log('val3                    ', val3)
  })

  it('should create an empty contract', async () => {
    assert.equal('0', ''+await await web3.eth.getBalance(st.address))
  })

  it('should be able to make a transfer request', async () => {
    const secret = 'my secret'
    const secretHash = web3.utils.sha3(secret)
    await st.deposit(user3, 600, 100, secretHash, { from: user2, value: 700 })
  })

  it('should be able to retrieve a transfer request', async () => {
    const secret = 'my secret'
    const secretHash = web3.utils.sha3(secret)
    await st.retrieve(user3, 600, 100, secretHash, { from: user2 })
  })

  it('should be able to collect a transfer request', async () => {
    const secret = 'my secret'
    const secretHash = web3.utils.sha3(secret)
    await st.deposit(user3, 600, 100, secretHash, { from: user2, value: 700 })
    await st.collect(user2, user3, 600, 100, secretHash, Buffer.from(secret), { from: user1 })
  })

})
