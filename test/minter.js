'use strict'

const Token = artifacts.require("Token")
const TokenMinter = artifacts.require("TokenMinter")
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

contract('TokenMinter', async accounts => {
  let token, minter

  const tokenOwner = accounts[1]
  const user1 = accounts[2]
  const user2 = accounts[3]
  const user3 = accounts[4]
  const user4 = accounts[5]
  
  const val1  = web3.utils.toWei('0.5', 'gwei')
  const val2  = web3.utils.toWei('0.4', 'gwei')
  const val3  = web3.utils.toWei('0.3', 'gwei')
  const valBN = web3.utils.toBN('0')

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
    minter = await TokenMinter.new(token.address, tokenOwner, { from: user1 })
    
    mlog.log('web3            ', web3.version)
    mlog.log('token contract  ', token.address)
    mlog.log('minter contract  ', minter.address)
    mlog.log('token Owner  ', tokenOwner)
    mlog.log('user1           ', user1)
    mlog.log('user2           ', user2)
    mlog.log('user3           ', user3)
    mlog.log('user4           ', user4)
    mlog.log('val1            ', val1)
    mlog.log('val2            ', val2)
    mlog.log('val3            ', val3)
  })

  it('should create an empty token', async () => {
    assert.equal('0', ''+await token.totalSupply())
    assert.equal('0', ''+await token.balanceOf(tokenOwner))
  })

  it ('only minter can mint tokens', async () => {
    await token.mint(user1, 500, { from: tokenOwner })
    assert.equal('500', ''+await token.totalSupply({ from: tokenOwner }))
    assert.equal('500', ''+await token.balanceOf(user1, { from: tokenOwner }))

    await mustRevert(async ()=> {
      await token.mint(user2, 200, { from: user1 })
    })

  })

  it ('should be transfer tokens', async () => {
  })


})
