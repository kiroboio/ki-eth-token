'use strict'

const Token = artifacts.require("Token")
const ERC1155Token = artifacts.require("myERC1155")
const SafeForERC1155 = artifacts.require('SafeForERC1155')
const ERC721Token = artifacts.require("ERC721Token")
const mlog = require('mocha-logger')

const { ethers } = require('ethers')
const { defaultAbiCoder, keccak256, toUtf8Bytes } = ethers.utils
const { TypedDataUtils } = require('ethers-eip712')

const sha3 = web3.utils.sha3
const NFT3 = 23456
const NFT4 = 86543
const NFT6 = 12345
const NFT7 = 45678
const NFT8 = 45633
const NFT9 = 43399
const NFT10 = 63422
const NFT11 = 86432
const NFT12 = 53345
const NFT13 = 34555

const {
  ZERO_ADDRESS,
} = require('./lib/consts')

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

contract('SafeForERC1155', async accounts => {
  let token, token1155, tokenSymbol, st, nonce, targetSupply, duration, initialSupply

  const tokenOwner = accounts[1]
  const user1 = accounts[2]
  const user2 = accounts[3]
  const user3 = accounts[4]
  const user4 = accounts[5]

  const val1  = web3.utils.toWei('0.5', 'gwei')
  const val2  = web3.utils.toWei('0.4', 'gwei')
  const val3  = web3.utils.toWei('0.3', 'gwei')
  const valBN = web3.utils.toBN('0')
  let token721;

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
    //token = await Token.new({ from: tokenOwner })
    st = await SafeForERC1155.new(user1, { from: user1 })
    mlog.log('web3                    ', web3.version)
    //mlog.log('token contract          ', token.address)
    mlog.log('safeForERC1155 contract  ', st.address)
    mlog.log('token Owner             ', tokenOwner)
    mlog.log('user1                   ', user1)
    mlog.log('user2                   ', user2)
    mlog.log('user3                   ', user3)
    mlog.log('user4                   ', user4)
    mlog.log('val1                    ', val1)
    mlog.log('val2                    ', val2)
    mlog.log('val3                    ', val3)

    token1155 = await ERC1155Token.new({from: tokenOwner});
    token1155.setApprovalForAll(st.address,true, {from:tokenOwner})
    token1155.setApprovalForAll(st.address,true, {from:user1})
    token721 = await ERC721Token.new('Kirobo ERC721 Token', 'KBF', {from: tokenOwner});
    await token721.selfMint(NFT3, { from: user3 })
    await token721.selfMint(NFT4, { from: user4 })
    await token721.approve(st.address, NFT3, { from: user3 })
    await token721.approve(st.address, NFT4, { from: user4 })

    mlog.log('token721                 ',   token721.address);
    mlog.log('token1155                ',   token1155.address);
  })

  it('should create an empty contract', async () => {
    assert.equal('0', ''+await await web3.eth.getBalance(st.address))
  })

  //single transfer
  it('should be able to make a transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const tokenId = 1
    const value = 100
    const tokenData = "0x00"
    const fees = 20
    await st.depositERC1155(token1155.address, user1, tokenId, value, tokenData, fees, secretHash, { from: tokenOwner, value: 20 })
  })

  it('should be able to retrieve a transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const tokenId = 1
    const value = 100
    const tokenData = "0x00"
    const fees = 20
    await st.retrieveERC1155(token1155.address, user1, tokenId, value, tokenData, fees, secretHash, { from: tokenOwner })
  })

  it('should be able to collect a transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const tokenId = 1
    const value = 100
    const tokenData = "0x00"
    const fees = 20
    await st.depositERC1155(token1155.address, user1, tokenId, value, tokenData, fees, secretHash, { from: tokenOwner, value: 20 })
    await st.collectERC1155(token1155.address, tokenOwner, user1, tokenId, value, tokenData, fees, secretHash, Buffer.from(secret), { from: user1 })
  })

  // batch transfer

  it('should be able to make a batch transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const tokenIds = [0,1]
    const values = [100,200]
    const tokenData = "0x00"
    const fees = 20
    await st.depositBatchERC1155(token1155.address, user1, tokenIds, values, tokenData, fees, secretHash, { from: tokenOwner, value: 20 })
  })

  it('should be able to retrieve a batch transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const tokenIds = [0,1]
    const values = [100,200]
    const tokenData = "0x00"
    const fees = 20
    await st.retrieveBatchERC1155(token1155.address, user1, tokenIds, values, tokenData, fees, secretHash, { from: tokenOwner })
  })

  it('should be able to collect a batch transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const tokenIds = [0,1]
    const values = [100,200]
    const tokenData = "0x00"
    const fees = 20
    await st.depositBatchERC1155(token1155.address, user1, tokenIds, values, tokenData, fees, secretHash, { from: tokenOwner, value: 20 })
    await st.collectBatchERC1155(user1, tokenOwner, {token: token1155.address ,tokenIds: tokenIds, values: values, tokenData: tokenData, fees: fees, 
                                  secretHash: secretHash, secret: Buffer.from(secret)}, { from: user1 })
  })

  //  swap 1155 to ETH

  it('should be able to deposit a swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const secretHash = sha3(secret)
    const tokenId0 = [0,1]
    const value0 = [100,200]
    const tokenData0 = "0x00"
    const fees0 = 20
    const token1 = ZERO_ADDRESS
    const tokenId1 = [0]
    const value1 = [100000000000]
    const tokenData1 = "0x00"
    const fees1 = 40
    await st.swapDepositERC1155(user1, {token0, tokenId0, value0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash}, {from:tokenOwner, value:fees0})
  })

  it('should be able to retrieve a swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const secretHash = sha3(secret)
    const tokenId0 = [0,1]
    const value0 = [100,200]
    const tokenData0 = "0x00"
    const fees0 = 20
    const token1 = ZERO_ADDRESS
    const tokenId1 = [0]
    const value1 = [100000000000]
    const tokenData1 = "0x00"
    const fees1 = 40
    await st.swapRetrieveERC1155(user1, {token0, tokenId0, value0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash}, {from:tokenOwner})
  })

  it('should be able to collect a swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const secretHash = sha3(secret)
    const tokenId0 = [0,1]
    const value0 = [100,200]
    const tokenData0 = "0x00"
    const fees0 = 20
    const token1 = ZERO_ADDRESS
    const tokenId1 = [0]
    const value1 = [100000000000]
    const tokenData1 = "0x00"
    const fees1 = 40
    const trxValue = value1[0]+fees1
    await st.swapDepositERC1155(user1, {token0, tokenId0, value0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash}, {from:tokenOwner, value:fees0})
    await st.swapERC1155(tokenOwner, {token0, tokenId0, value0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash}, Buffer.from(secret), {from:user1, value: trxValue})
  })

  //  swap ETH to 1155

  it('should be able to deposit a swap request', async () => {
    const secret = 'my secret'
    const token1 = token1155.address
    const secretHash = sha3(secret)
    const tokenId0 = [0]
    const value0 = [100000000000]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token0 = ZERO_ADDRESS
    const tokenId1 = [0,3]
    const value1 = [100,200]
    const tokenData1 = "0x00"
    const fees1 = 20
    const trxValue = value0[0]+fees0
    await st.swapDepositERC1155(tokenOwner, {token0, tokenId0, value0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash}, {from:user1, value:trxValue})
  })

  it('should be able to retrieve a swap request', async () => {
    const secret = 'my secret'
    const token1 = token1155.address
    const secretHash = sha3(secret)
    const tokenId0 = [0]
    const value0 = [100000000000]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token0 = ZERO_ADDRESS
    const tokenId1 = [0,3]
    const value1 = [100,200]
    const tokenData1 = "0x00"
    const fees1 = 20
    const trxValue = value0[0]+fees0
    await st.swapRetrieveERC1155(tokenOwner, {token0, tokenId0, value0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash}, {from:user1})
  })

  it('should be able to collect a swap request', async () => {
    const secret = 'my secret'
    const token1 = token1155.address
    const secretHash = sha3(secret)
    const tokenId0 = [0]
    const value0 = [100000000000]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token0 = ZERO_ADDRESS
    const tokenId1 = [0,3]
    const value1 = [100,200]
    const tokenData1 = "0x00"
    const fees1 = 20
    const trxValue = value0[0]+fees0
    await st.swapDepositERC1155(tokenOwner, {token0, tokenId0, value0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash}, {from:user1, value:trxValue})
    await st.swapERC1155(user1, {token0, tokenId0, value0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash}, Buffer.from(secret), {from:tokenOwner, value: fees1})
  })


  //  swap 721 to 1155

  it('should be able to deposit a swap request', async () => {
    const secret = 'my secret'
    const token1 = token1155.address
    const secretHash = sha3(secret)
    const tokenId0 = [NFT3]
    const value0 = [0]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token0 = token721.address
    const tokenId1 = [0,3]
    const value1 = [100,200]
    const tokenData1 = "0x00"
    const fees1 = 20
    await st.swapDepositERC1155(tokenOwner, {token0, tokenId0, value0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash}, {from:user3, value:fees0})
  })

  it('should be able to retrieve a swap request', async () => {
    const secret = 'my secret'
    const token1 = token1155.address
    const secretHash = sha3(secret)
    const tokenId0 = [NFT3]
    const value0 = [0]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token0 = token721.address
    const tokenId1 = [0,3]
    const value1 = [100,200]
    const tokenData1 = "0x00"
    const fees1 = 20
    await st.swapRetrieveERC1155(tokenOwner, {token0, tokenId0, value0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash}, {from:user3})
  })

  it('should be able to collect a swap request', async () => {
    const secret = 'my secret'
    const token1 = token1155.address
    const secretHash = sha3(secret)
    const tokenId0 = [NFT3]
    const value0 = [0]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token0 = token721.address
    const tokenId1 = [0,3]
    const value1 = [100,200]
    const tokenData1 = "0x00"
    const fees1 = 20
    await st.swapDepositERC1155(tokenOwner, {token0, tokenId0, value0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash}, {from:user3, value:fees0})
    await st.swapERC1155(user3, {token0, tokenId0, value0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash}, Buffer.from(secret), {from:tokenOwner, value: fees1})
  }) 

  // swap 1155 with 1155

  it('should be able to deposit a swap request', async () => {
    const secret = 'my secret'
    const token1 = token1155.address
    const secretHash = sha3(secret)
    const tokenId0 = [0,1]
    const value0 = [10, 20]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token0 = token1155.address
    const tokenId1 = [0,3]
    const value1 = [100,200]
    const tokenData1 = "0x00"
    const fees1 = 20
    await st.swapDepositERC1155(tokenOwner, {token0, tokenId0, value0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash}, {from:user1, value:fees0})
  })

  it('should be able to retrieve a swap request', async () => {
    const secret = 'my secret'
    const token1 = token1155.address
    const secretHash = sha3(secret)
    const tokenId0 = [0,1]
    const value0 = [10, 20]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token0 = token1155.address
    const tokenId1 = [0,3]
    const value1 = [100,200]
    const tokenData1 = "0x00"
    const fees1 = 20
    await st.swapRetrieveERC1155(tokenOwner, {token0, tokenId0, value0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash}, {from:user1})
  })

  it('should be able to collect a swap request', async () => {
    const secret = 'my secret'
    const token1 = token1155.address
    const secretHash = sha3(secret)
    const tokenId0 = [0,1]
    const value0 = [10, 20]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token0 = token1155.address
    const tokenId1 = [0,3]
    const value1 = [100,200]
    const tokenData1 = "0x00"
    const fees1 = 20
    await st.swapDepositERC1155(tokenOwner, {token0, tokenId0, value0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash}, {from:user1, value:fees0})
    await st.swapERC1155(user1, {token0, tokenId0, value0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash}, Buffer.from(secret), {from:tokenOwner, value: fees1})
  }) 
  
  })

