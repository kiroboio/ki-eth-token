'use strict'

const Token = artifacts.require("Token")
const SafeTransfer = artifacts.require('SafeTransfer')
const mlog = require('mocha-logger')

const { ethers } = require('ethers')
const { defaultAbiCoder, keccak256, toUtf8Bytes } = ethers.utils
const { TypedDataUtils } = require('ethers-eip712')

const sha3 = web3.utils.sha3

const {
  advanceBlock,
  advanceTime,
  advanceTimeAndBlock,
  trNonce,
  getLatestBlockTimestamp,
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

const getPrivateKey = (address) => {
  const wallet = web3.currentProvider.wallets[address.toLowerCase()]
  return `0x${wallet._privKey.toString('hex')}`
}

contract('SafeTransfer', async accounts => {
  let token, tokenSymbol, st, nonce, targetSupply, duration, initialSupply

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
    st = await SafeTransfer.new(user1, { from: user1 })
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

    await token.mint(user1, 1e10, { from: tokenOwner })
    await token.mint(user2, 1e10, { from: tokenOwner })
    await token.mint(user3, 1e10, { from: tokenOwner })
    tokenSymbol = await token.symbol()
  })

  it('should create an empty contract', async () => {
    assert.equal('0', ''+await await web3.eth.getBalance(st.address))
  })

  it('should be able to make a transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    await st.deposit(user3, 600, 100, secretHash, { from: user2, value: 700 })
  })

  it('should be able to retrieve a transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    await st.retrieve(user3, 600, 100, secretHash, { from: user2 })
  })

  it('should be able to collect a transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    await st.deposit(user3, 600, 100, secretHash, { from: user2, value: 700 })
    await st.collect(user2, user3, 600, 100, secretHash, Buffer.from(secret), { from: user1 })
  })

  it('should be able to collect a transfer timed request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const now = await getLatestBlockTimestamp()
    await st.timedDeposit(user3, 600, 100, secretHash, 0, now+10000, 0, { from: user2, value: 700 })
    await st.collect(user2, user3, 600, 100, secretHash, Buffer.from(secret), { from: user1 })
  })

  it('should be able to auto retrieve a transfer timed request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const now = await getLatestBlockTimestamp()
    await st.timedDeposit(user3, 600, 100, secretHash, 0, now+10000, 0, { from: user2, value: 700 })
    advanceTimeAndBlock(10000)
    await st.autoRetrieve(user2, user3, 600, 100, secretHash, { from: user1 })
  })

  it('should be able to make an erc20 transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    await token.approve(st.address, 1e12, { from: user2 })
    await st.depositERC20(token.address, tokenSymbol, user3, 600, 100, secretHash, { from: user2, value: 100 })
  })

  it('should be able to retrieve an erc20 transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    await st.retrieveERC20(token.address, tokenSymbol, user3, 600, 100, secretHash, { from: user2 })
  })

  it('should be able to collect an erc20 transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    await st.depositERC20(token.address, tokenSymbol, user3, 600, 100, secretHash, { from: user2, value: 100 })
    await st.collectERC20(token.address, tokenSymbol, user2, user3, 600, 100, secretHash, Buffer.from(secret), { from: user1 })
  })

  it('should be able to collect an erc20 transfer timed request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const now = await getLatestBlockTimestamp()
    await st.timedDepositERC20(token.address, tokenSymbol, user3, 600, 100, secretHash, 0, now+10000, 0, { from: user2, value: 100 })
    await st.collectERC20(token.address, tokenSymbol, user2, user3, 600, 100, secretHash, Buffer.from(secret), { from: user1 })
  })

  it('should be able to make a hidden transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const id1 = sha3('1234')
    await st.hiddenDeposit(id1, { from: user2, value: 100 })
  })

  it('should be able to retrieve a hidden transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const id1 = sha3('1234')
    await st.hiddenRetrieve(id1, 100, { from: user2 })
  })

  it('should be able to collect a hidden transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const id1 = sha3(defaultAbiCoder.encode(
      ['bytes32', 'address', 'address', 'uint256', 'uint256', 'bytes32'],
      [await st.HIDDEN_COLLECT_TYPEHASH(), user2, user3, '600', '100', secretHash]
    ))

    mlog.log('id1', id1)

    const typedData = {
      types: {
        EIP712Domain: [
          { name: "name",               type: "string" },
          { name: "version",            type: "string" },
          { name: "chainId",            type: "uint256" },
          { name: "verifyingContract",  type: "address" },
          { name: "salt",               type: "bytes32" }
        ],
        hiddenCollect: [
          { name: 'from',               type: 'address' },
          { name: 'to',                 type: 'address' },
          { name: 'value',              type: 'uint256' },
          { name: 'fees',               type: 'uint256' },
          { name: 'secretHash',         type: 'bytes32' },
        ]
      },
      primaryType: 'hiddenCollect',
      domain: {
        name: await st.NAME(),
        version: await st.VERSION(),
        chainId: '0x' + web3.utils.toBN(await st.CHAIN_ID()).toString('hex'), // await web3.eth.getChainId(),
        verifyingContract: st.address,
        salt: await st.uid(),
      },
      message: {
        from: user2,
        to: user3,
        value: '0x' + web3.utils.toBN('600').toString('hex'),
        fees: '0x' + web3.utils.toBN('100').toString('hex'),
        secretHash,
      }
    }

    mlog.log('typedData: ', JSON.stringify(typedData, null, 2))
    mlog.log('CHAIN_ID', await st.CHAIN_ID())
    mlog.log('DOMAIN_SEPARATOR', await st.DOMAIN_SEPARATOR())
    const domainHash = TypedDataUtils.hashStruct(typedData, 'EIP712Domain', typedData.domain)
    const domainHashHex = ethers.utils.hexlify(domainHash)
    mlog.log('DOMAIN_SEPARATOR (calculated)', domainHashHex)
    
    const messageDigest = TypedDataUtils.encodeDigest(typedData)

    const messageHash = TypedDataUtils.hashStruct(typedData, typedData.primaryType, typedData.message)
    const messageHashHex = ethers.utils.hexlify(messageHash)
    mlog.log('messageHash (calculated)', messageHashHex)
    
    let signingKey = new ethers.utils.SigningKey(getPrivateKey(user2));
    const sig = signingKey.signDigest(messageDigest)
    const rlp = ethers.utils.splitSignature(sig)
    rlp.v = '0x' + rlp.v.toString(16)

    mlog.log('rlp', JSON.stringify(rlp))
    mlog.log('recover', ethers.utils.recoverAddress(messageDigest, sig))

    await st.hiddenDeposit(id1, { from: user2, value: 700 })
    await st.hiddenCollect(user2, user3, 600, 100, secretHash, Buffer.from(secret), rlp.v, rlp.r, rlp.s, { from: user1 })
  })

})
