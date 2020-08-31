'use strict'

const Pool = artifacts.require("Pool")
const Token = artifacts.require("Token")
const Wallet = artifacts.require("Wallet")
const mlog = require('mocha-logger')

const { assertRevert, assertInvalidOpcode, assertPayable, assetEvent_getArgs } = require('./lib/asserts')
const { advanceBlock, advanceTime, advanceTimeAndBlock } = require('./lib/utils')

contract('Wallet', async accounts => {
  let token, pool, wallet, tx, args, nonce

  const tokenOwner = accounts[1]
  const poolOwner = accounts[2]
  const user1 = accounts[3]
  const user2 = accounts[4]
  const user3 = accounts[5]
  const walletOwner1 = accounts[6]
  const walletOwner2 = accounts[7]
  const walletOwner3 = accounts[8]
  const walletOwner4 = accounts[9]

  const val1  = web3.utils.toWei('0.5', 'gwei')
  const val2  = web3.utils.toWei('0.4', 'gwei')
  const val3  = web3.utils.toWei('0.3', 'gwei')
  const valBN = web3.utils.toBN('0')

  before('checking constants', async () => {
      assert(typeof walletOwner1  == 'string', 'walletOwner1 should be string')
      assert(typeof walletOwner2  == 'string', 'walletOwner2 should be string')
      assert(typeof walletOwner3  == 'string', 'walletOwner3 should be string')
      assert(typeof walletOwner4  == 'string', 'walletOwner4 should be string')
      assert(typeof tokenOwner    == 'string', 'tokenOwner should be string')
      assert(typeof poolOwner     == 'string', 'poolOwner should be string')
      assert(typeof user1         == 'string', 'user1 should be string')
      assert(typeof user2         == 'string', 'user2 should be string')
      assert(typeof user3         == 'string', 'user3 should be string')
      assert(typeof val1          == 'string', 'val1  should be big number')
      assert(typeof val2          == 'string', 'val2  should be string')
      assert(typeof val3          == 'string', 'val2  should be string')
      assert(valBN instanceof web3.utils.BN, 'valBN should be big number')
  })

  before('setup contract for the test', async () => {
    token = await Token.deployed() // new({ from: tokenOwner })
    pool = await Pool.deployed() // new(token.address, { from: poolOwner })
    // await token.disableTransfers(false, { from: tokenOwner })
    wallet = await Wallet.deployed() /// new(walletOwner1, walletOwner2, walletOwner3, { from: user1 })
    
    mlog.log('web3           ', web3.version)
    mlog.log('token contract ', token.address)
    mlog.log('pool contract  ', pool.address)
    mlog.log('tokenOwner     ', tokenOwner)
    mlog.log('poolOwner      ', poolOwner)
    mlog.log('walletOwner1   ', walletOwner1)
    mlog.log('walletOwner2   ', walletOwner2)
    mlog.log('walletOwner3   ', walletOwner3)
    mlog.log('walletOwner4   ', walletOwner4)
    mlog.log('user1          ', user1)
    mlog.log('user2          ', user2)
    mlog.log('user3          ', user3)
    mlog.log('val1           ', val1)
    mlog.log('val2           ', val2)
    mlog.log('val3           ', val3)
  })

  it('should create a wallet with owners only', async () => {
    assert.ok(await wallet.isOwner({ from: walletOwner1 }))
    assert.ok(await wallet.isOwner({ from: walletOwner2 }))
    assert.ok(await wallet.isOwner({ from: walletOwner3 }))
    assert.notOk(await wallet.isOwner({ from: user1 }))
  })

  it('should be able to change owner', async () => {
    assert.notOk(await wallet.isOwner({ from: walletOwner4 }))
    tx = await wallet.replaceOwner(walletOwner3, walletOwner4, { from: walletOwner1 })
    args = assetEvent_getArgs(tx.logs, 'MultiSigReplaceOwnerCall');
    assert.equal(args.by, walletOwner1, '..(by, .., ..)');
    assert.equal(args.from, walletOwner3, '..(.., from, ..)');
    assert.equal(args.to, walletOwner4, '..(.., .., to)');
    args = assetEvent_getArgs(tx.logs, 'MultiSigRequest');
    assert.equal(args.from, walletOwner1, '..(by, .., .., ..)');
    assert.equal(
      args.selector.slice(0,10),
      web3.eth.abi.encodeFunctionSignature('replaceOwner(address,address)'), '..(.., selector, .., ..)'
    )
    assert.equal(args.value, 0, '..(.., .., value, ..)');
    assert.ok(await wallet.isOwner({ from: walletOwner3 }))
    assert.notOk(await wallet.isOwner({ from: walletOwner4 }))
    tx = await wallet.replaceOwner(walletOwner3, walletOwner4, { from: walletOwner2 })
    args = assetEvent_getArgs(tx.logs, 'MultiSigReplaceOwnerCall');
    assert.equal(args.by, walletOwner2, '..(by, .., ..)');
    assert.equal(args.from, walletOwner3, '..(.., from, ..)');
    assert.equal(args.to, walletOwner4, '..(.., .., to)');
    args = assetEvent_getArgs(tx.logs, 'MultiSigExecute');
    assert.equal(args.from, walletOwner2, '..(by, .., .., ..)');
    assert.equal(
      args.selector.slice(0,10),
      web3.eth.abi.encodeFunctionSignature('replaceOwner(address,address)'), '..(.., selector, .., ..)'
    )
    assert.equal(args.value, 0, '..(.., .., value, ..)');
    assert.notOk(await wallet.isOwner({ from: walletOwner3 }))
    assert.ok(await wallet.isOwner({ from: walletOwner4 }))
    assert.ok(await wallet.isOwner({ from: walletOwner1 }))
    assert.ok(await wallet.isOwner({ from: walletOwner2 }))
  })

  it('should be able to transfer tokens', async () => {
    await token.mint(wallet.address, val1, { from: tokenOwner })
    await wallet.setOwnTarget_(token.address, { from: walletOwner1 })
    await wallet.setOwnTarget_(token.address, { from: walletOwner2 })
    assert.equal(val1, (await token.balanceOf(wallet.address)).toString())
    assert.equal('0', (await token.balanceOf(user1)).toString())
    await (await Token.at(wallet.address)).transfer(user1, val2, { from: walletOwner1 })
    await (await Token.at(wallet.address)).transfer(user1, val2, { from: walletOwner2 })
    assert.equal((BigInt(val1)-BigInt(val2)).toString(), (await token.balanceOf(wallet.address)).toString())
    assert.equal(val2, (await token.balanceOf(user1)).toString())
  })

  it('should be able to transfer all received ether', async () => {
    assert.equal(0, +(await web3.eth.getBalance(wallet.address)))
    await web3.eth.sendTransaction({from: user3, to: wallet.address, value: 20000 })
    assert.equal(20000, +(await web3.eth.getBalance(wallet.address)))
    await wallet.transferOwnEther_(user2, 5000, { from: walletOwner1 })
    await wallet.transferOwnEther_(user2, 5000, { from: walletOwner2 })
    assert.equal(15000, +(await web3.eth.getBalance(wallet.address)))
    await wallet.transferOwnEther_(user2, 15000, { from: walletOwner1 })
    await wallet.transferOwnEther_(user2, 15000, { from: walletOwner2 })
    assert.equal(0, +(await web3.eth.getBalance(wallet.address)))
  })

  it('should be able to create token from wallet', async () => {
    const contract = new web3.eth.Contract(Token.abi)
    const bytecode = contract.deploy({arguments: [], data: Token.bytecode}).encodeABI()
    tx = await wallet.deployContract_(bytecode, { from: walletOwner1 })
    args = assetEvent_getArgs(tx.logs, 'MultiSigRequest');
    assert.equal(args.from, walletOwner1, '..(by, .., .., ..)');
    assert.equal(
      args.selector.slice(0,10),
      web3.eth.abi.encodeFunctionSignature('deployContract_(bytes)'), '..(bytecode)'
    )
    const token2Receipt = await wallet.deployContract_(bytecode, { from: walletOwner2 })
    args = assetEvent_getArgs(token2Receipt.logs, 'MultiSigExecute');
    assert.equal(args.from, walletOwner2, '..(by, .., .., ..)');
    assert.equal(
      args.selector.slice(0,10),
      web3.eth.abi.encodeFunctionSignature('deployContract_(bytes)'), '..(bytecode)'
    )
    const token2Address = token2Receipt.logs[1].args[0]
    await wallet.setOwnTarget_(token2Address, { from: walletOwner1 })
    await wallet.setOwnTarget_(token2Address, { from: walletOwner2 }) 
    const token2 = await Token.at(wallet.address)
    await token2.mint(user1, 2000, { from: walletOwner1 })
    await token2.mint(user1, 2000, { from: walletOwner2 })
    const token2Instance = await Token.at(token2Address) 
    assert.equal(2000, await token2Instance.balanceOf(user1, { from: walletOwner1 }))
  })

  it('should be able to create pool from wallet', async () => {
    const contract = new web3.eth.Contract(Pool.abi)
    const bytecode = contract.deploy({arguments: [token.address], data: Pool.bytecode}).encodeABI()
    await wallet.deployContract_(bytecode, { from: walletOwner1 })
    const pool2Receipt = await wallet.deployContract_(bytecode, { from: walletOwner2 })
    const pool2Address = pool2Receipt.logs[1].args[0]
    await wallet.setOwnTarget_(pool2Address, { from: walletOwner1 })
    await wallet.setOwnTarget_(pool2Address, { from: walletOwner2 }) 
    const pool2 = await Pool.at(wallet.address)
    await token.mint(pool2Address, 2000, { from: tokenOwner })
    await pool2.resyncTotalSupply(2000, { from: walletOwner1 })
    await pool2.resyncTotalSupply(2000, { from: walletOwner2 })
    await pool2.distributeTokens(user1, 250, { from: walletOwner1 })
    await pool2.distributeTokens(user1, 250, { from: walletOwner2 })
    const pool2Instance = await Pool.at(pool2Address) 
    assert.equal(250, (await pool2Instance.account(user1, { from: walletOwner2 })).balance)
  })

  it('should be able to create token from wallet using salt', async () => {
    const contract = new web3.eth.Contract(Token.abi)
    const bytecode = contract.deploy({arguments: [], data: Token.bytecode}).encodeABI()
    const salt = web3.utils.sha3('1234')
    tx = await wallet.deployContract2_(bytecode, salt, { from: walletOwner1 })
    const token2Receipt = await wallet.deployContract2_(bytecode, salt, { from: walletOwner2 })
    const token2Address = token2Receipt.logs[1].args[0]
    await wallet.setOwnTarget_(token2Address, { from: walletOwner1 })
    await wallet.setOwnTarget_(token2Address, { from: walletOwner2 }) 
    const token2 = await Token.at(wallet.address)
    await token2.mint(user2, 500, { from: walletOwner1 })
    await token2.mint(user2, 500, { from: walletOwner2 })
    const token2Instance = await Token.at(token2Address) 
    assert.equal(500, await token2Instance.balanceOf(user2, { from: user2 }))
  })

  it('should be able to create pool from wallet using salt', async () => {
    const contract = new web3.eth.Contract(Pool.abi)
    const bytecode = contract.deploy({arguments: [token.address], data: Pool.bytecode}).encodeABI()
    const salt = web3.utils.sha3('1234')
    await wallet.deployContract2_(bytecode, salt, { from: walletOwner1 })
    const pool2Receipt = await wallet.deployContract2_(bytecode, salt, { from: walletOwner2 })
    const pool2Address = pool2Receipt.logs[1].args[0]
    await wallet.setOwnTarget_(pool2Address, { from: walletOwner1 })
    await wallet.setOwnTarget_(pool2Address, { from: walletOwner2 }) 
    const pool2 = await Pool.at(wallet.address)
    await token.mint(pool2Address, 2000, { from: tokenOwner })
    await pool2.resyncTotalSupply(2000, { from: walletOwner1 })
    await pool2.resyncTotalSupply(2000, { from: walletOwner2 })
    await pool2.distributeTokens(user2, 400, { from: walletOwner1 })
    await pool2.distributeTokens(user2, 400, { from: walletOwner2 })
    const pool2Instance = await Pool.at(pool2Address) 
    assert.equal(400, (await pool2Instance.account(user2, { from: user2 })).balance)
  })

})
