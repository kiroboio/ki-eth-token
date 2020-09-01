'use strict'

const Pool = artifacts.require("Pool")
const Token = artifacts.require("Token")
const Wallet = artifacts.require("Wallet")
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

contract('Token', async accounts => {
  let token, tokenAdmin, wallet

  const user1 = accounts[2]
  const user2 = accounts[3]
  const user3 = accounts[4]
  const user4 = accounts[5]
  const walletOwner1 = accounts[6]
  const walletOwner2 = accounts[7]
  const walletOwner3 = accounts[8]
  
  const val1  = web3.utils.toWei('0.5', 'gwei')
  const val2  = web3.utils.toWei('0.4', 'gwei')
  const val3  = web3.utils.toWei('0.3', 'gwei')
  const valBN = web3.utils.toBN('0')

  before('checking constants', async () => {
      assert(typeof walletOwner1  == 'string', 'walletOwner1 should be string')
      assert(typeof walletOwner2  == 'string', 'walletOwner2 should be string')
      assert(typeof walletOwner3  == 'string', 'walletOwner3 should be string')
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
    wallet = await Wallet.deployed() /// new(walletOwner1, walletOwner2, walletOwner3, { from: user1 })

    const contract = new web3.eth.Contract(Token.abi)
    const bytecode = contract.deploy({arguments: [], data: Token.bytecode}).encodeABI()
    await wallet.deployContract_(bytecode, { from: walletOwner1 })
    const tokenReceipt = await wallet.deployContract_(bytecode, { from: walletOwner2 })
    const tokenAddress = tokenReceipt.logs[1].args[0]
    await wallet.setOwnTarget_(tokenAddress, { from: walletOwner1 })
    await wallet.setOwnTarget_(tokenAddress, { from: walletOwner2 }) 
    tokenAdmin = await Token.at(wallet.address)
    token = await Token.at(tokenAddress)
    
    mlog.log('web3            ', web3.version)
    mlog.log('token contract  ', token.address)
    mlog.log('wallet contract ', wallet.address)
    mlog.log('walletOwner1    ', walletOwner1)
    mlog.log('walletOwner2    ', walletOwner2)
    mlog.log('walletOwner3    ', walletOwner3)
    mlog.log('user1           ', user1)
    mlog.log('user2           ', user2)
    mlog.log('user3           ', user3)
    mlog.log('user4           ', user4)
    mlog.log('val1            ', val1)
    mlog.log('val2            ', val2)
    mlog.log('val3            ', val3)
  })

  it('should create an empty token', async () => {
    assert.equal('0', ''+await token.totalSupply({ from: walletOwner1 }))
    assert.equal('0', ''+await token.balanceOf(wallet.address, { from: walletOwner1 }))
  })

  it ('only minter can mint tokens', async () => {
    await tokenAdmin.mint(user1, 500, { from: walletOwner1 })
    await tokenAdmin.mint(user1, 500, { from: walletOwner2 })
    await tokenAdmin.mint(user2, 300, { from: walletOwner1 })
    await tokenAdmin.mint(user2, 300, { from: walletOwner2 })
    assert.equal('800', ''+await token.totalSupply({ from: walletOwner1 }))
    assert.equal('500', ''+await token.balanceOf(user1, { from: walletOwner1 }))
    assert.equal('300', ''+await token.balanceOf(user2, { from: walletOwner1 }))

    await mustRevert(async ()=> {
      await token.mint(user2, 200, { from: user1 })
    })

  })

  it ('should be transfer tokens', async () => {
    const nonce = await trNonce(web3, user1)
    await token.transfer(user2, 50, { from: user1, nonce })
    await token.transfer(wallet.address, 50, { from: user1 })
    await tokenAdmin.transfer(user3, 20, { from: walletOwner2 })
    await tokenAdmin.transfer(user3, 20, { from: walletOwner3 })
    assert.equal('30', ''+await token.balanceOf(wallet.address, { from: walletOwner1 }))
    assert.equal('400', ''+await token.balanceOf(user1, { from: walletOwner1 }))
    assert.equal('350', ''+await token.balanceOf(user2, { from: walletOwner1 }))
    assert.equal('20', ''+await token.balanceOf(user3, { from: walletOwner1 }))
  })

  it ('should be able to transfer tokens from another account when there is an allowance', async () => {
    await token.approve(user2, 50, { from: user1 })
    assert.equal('50', ''+await token.allowance(user1, user2))
    await token.transferFrom(user1, user3, 50, { from: user2 })
    assert.equal('350', ''+await token.balanceOf(user1, { from: walletOwner1 }))
    assert.equal('350', ''+await token.balanceOf(user2, { from: walletOwner1 }))
    assert.equal('70', ''+await token.balanceOf(user3, { from: walletOwner1 }))

    await tokenAdmin.approve(user1, 10, { from: walletOwner1 })
    await tokenAdmin.approve(user1, 10, { from: walletOwner2 })
    await tokenAdmin.approve(user2, 5, { from: walletOwner3 })
    await tokenAdmin.approve(user2, 5, { from: walletOwner1 })
    assert.equal('10', ''+await token.allowance(wallet.address, user1))
    assert.equal('5', ''+await token.allowance(wallet.address, user2))
    await token.transferFrom(wallet.address, user4, 8, { from: user1 })
    await token.transferFrom(wallet.address, user4, 4, { from: user2 })
    assert.equal('18', ''+await token.balanceOf(wallet.address, { from: user1 }))
    assert.equal('12', ''+await token.balanceOf(user4, { from: user1 }))

    await token.approve(wallet.address, 60, { from: user1 })
    assert.equal('60', ''+await token.allowance(user1, wallet.address))
    await tokenAdmin.transferFrom(user1, wallet.address, 20, { from: walletOwner1 })
    await tokenAdmin.transferFrom(user1, wallet.address, 20, { from: walletOwner2 })
    assert.equal('40', ''+await token.allowance(user1, wallet.address))
    await tokenAdmin.transferFrom(user1, user4, 30, { from: walletOwner2 })
    await tokenAdmin.transferFrom(user1, user4, 30, { from: walletOwner1 })
    assert.equal('10', ''+await token.allowance(user1, wallet.address))
    assert.equal('300', ''+await token.balanceOf(user1, { from: user1 }))
    assert.equal('38', ''+await token.balanceOf(wallet.address, { from: user1 }))
    assert.equal('42', ''+await token.balanceOf(user4, { from: user1 }))
  })

  it ('should be able to burn tokens only when has burner role', async () => {
    await tokenAdmin.burn(8, { from: walletOwner1 })
    await tokenAdmin.burn(8, { from: walletOwner2 })
    assert.equal('792', ''+await token.totalSupply({ from: walletOwner1 }))
    assert.equal('30', ''+await token.balanceOf(wallet.address, { from: user1 }))

    await mustRevert(async ()=> {
      await token.burn(30, { from: user1 })
    })

  })

  it ('should be able to grant burner role when has admin role', async () => {
    await tokenAdmin.grantRole(await token.BURNER_ROLE(), user1, { from: walletOwner1 })
    await tokenAdmin.grantRole(await token.BURNER_ROLE(), user1, { from: walletOwner2 })
    const nonce = await trNonce(web3, user1)
    await token.burn(10, { from: user1, nonce })
    assert.equal('782', ''+await token.totalSupply({ from: walletOwner1 }))
    assert.equal('290', ''+await token.balanceOf(user1), { from: user1 })
    await mustRevert(async ()=> {
      await token.grantRole(await token.BURNER_ROLE(), user2, { from: user1 })
    })
  })

  it ('should be able to revoke burner role when has admin role', async () => {
    let nonce = await trNonce(web3, user1)
    await mustRevert(async ()=> {
      await token.revokeRole(await token.BURNER_ROLE(), wallet.address, { from: user1, nonce })
    })
    await tokenAdmin.revokeRole(await token.BURNER_ROLE(), user1, { from: walletOwner1 })
    await tokenAdmin.revokeRole(await token.BURNER_ROLE(), user1, { from: walletOwner2 })
    nonce = await trNonce(web3, user1)
    await mustRevert(async ()=> {
      await token.burn(30, { from: user1, nonce })
    })
  })

  it ('should be able to grant admin role when has admin role', async () => {
    await tokenAdmin.grantRole(await token.MINTER_ADMIN_ROLE(), user2, { from: walletOwner1 })
    await tokenAdmin.grantRole(await token.MINTER_ADMIN_ROLE(), user2, { from: walletOwner2 })
    await token.grantRole(await token.MINTER_ROLE(), user3, { from: user2 })
    await token.mint(user4, 200, { from: user3 })
  })

  it ('should be able to revoke own admin role when has admin role', async () => {
    await tokenAdmin.revokeRole(await token.BURNER_ADMIN_ROLE(), wallet.address, { from: walletOwner1 })
    await tokenAdmin.revokeRole(await token.BURNER_ADMIN_ROLE(), wallet.address, { from: walletOwner2 })
    await tokenAdmin.burn(10, { from: walletOwner1 })
    await tokenAdmin.burn(10, { from: walletOwner2 })
    await tokenAdmin.grantRole(await token.BURNER_ROLE(), user1, { from: walletOwner1 })
    await mustRevert(async ()=> {
      await tokenAdmin.grantRole(await token.BURNER_ROLE(), user1, { from: walletOwner2 })
    })
  })

})
