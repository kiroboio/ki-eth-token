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
  let token, minter, nonce, targetSupply, duration, initialSupply

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
    minter = await TokenMinter.new(token.address, tokenOwner, { from: user1 })
    targetSupply = BigInt(await minter.TARGET_SUPPLY())
    duration = BigInt(await minter.DURATION())
    mlog.log('web3                ', web3.version)
    mlog.log('token contract      ', token.address)
    mlog.log('minter contract     ', minter.address)
    mlog.log('token Owner         ', tokenOwner)
    mlog.log('user1               ', user1)
    mlog.log('user2               ', user2)
    mlog.log('user3               ', user3)
    mlog.log('user4               ', user4)
    mlog.log('start value         ', startValue)
    mlog.log('target supply       ', targetSupply)
    mlog.log('minter duration     ', duration)
    mlog.log('val1                ', val1)
    mlog.log('val2                ', val2)
    mlog.log('val3                ', val3)
  })

  it('should create an empty token', async () => {
    assert.equal('0', ''+await token.totalSupply())
    assert.equal('0', ''+await token.balanceOf(tokenOwner))
  })

  it ('only minter can mint tokens', async () => {
    await token.mint(user1, ''+startValue, { from: tokenOwner })
    assert.equal(startValue, ''+await token.totalSupply({ from: tokenOwner }))
    assert.equal(startValue, ''+await token.balanceOf(user1, { from: tokenOwner }))

    await mustRevert(async ()=> {
      await token.mint(user2, 200, { from: user1 })
    })

  })

  it ('should not start if minter do not have MINTER_ROLE', async () => {
    assert.equal(await token.hasRole(await token.MINTER_ROLE(), minter.address), false)
    
    await mustRevert(async ()=> {
      await minter.start({ from: tokenOwner })
    })

  })

  it ('should not start if minter is not the only one that has MINTER_ROLE', async () => {
    nonce = await trNonce(web3, tokenOwner)
    await token.grantRole(await token.MINTER_ROLE(), minter.address, { from: tokenOwner, nonce })
    assert.equal(await token.hasRole(await token.MINTER_ROLE(), minter.address), true)
    
    await mustRevert(async ()=> {
      await minter.start({ from: tokenOwner })
    })
  })

  it ('should start if minter is the only one that has MINTER_ROLE and there is no MINTER admin', async () => {
    nonce = await trNonce(web3, tokenOwner)
    await token.revokeRole(await token.MINTER_ROLE(), tokenOwner, { from: tokenOwner, nonce })
    assert.equal(await token.hasRole(await token.MINTER_ROLE(), minter.address), true)
    assert.equal(1, ''+await token.getRoleMemberCount(await token.MINTER_ROLE()))
    
    await mustRevert(async ()=> {
      await minter.start({ from: tokenOwner })
    })
    
    nonce = await trNonce(web3, tokenOwner)
    await token.renounceRole(await token.MINTER_ADMIN_ROLE(), tokenOwner, { from: tokenOwner, nonce })
    await minter.start({ from: tokenOwner })
  })

  it ('should', async () => {
    initialSupply = BigInt(await minter.initialSupply())
    const time = 2000n
    await advanceTimeAndBlock(+(''+time))
    assert.equal(''+((targetSupply-startValue) * time / duration), ''+await minter.mintLimit())
    mlog.log('start time', ''+await minter.startTime())
    mlog.log('end time', ''+await minter.endTime())
    mlog.log('minted', ''+await minter.minted())
    mlog.log('left', ''+await minter.left())
    mlog.log('max', ''+await minter.maxCap())
    mlog.log('mint limit', ''+await minter.mintLimit())
    await advanceTimeAndBlock(+(''+ (duration-time-10n)))
    assert.notEqual(''+(BigInt(await minter.TARGET_SUPPLY())-initialSupply), ''+await minter.mintLimit())
    await advanceTimeAndBlock(10)
    assert.equal(''+(BigInt(await minter.TARGET_SUPPLY())-initialSupply), ''+await minter.mintLimit())
  })

})
