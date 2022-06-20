'use strict'

const Token = artifacts.require("Token")
const ERC1155Token = artifacts.require("MyERC1155")
const SafeForERC1155Core = artifacts.require('SafeForERC1155Core')
const SafeForERC1155 = artifacts.require('SafeForERC1155')
const ERC721Token = artifacts.require("ERC721Token")
const mlog = require('mocha-logger')

const { ethers } = require('ethers')
const { defaultAbiCoder, keccak256, toUtf8Bytes } = ethers.utils
const { TypedDataUtils } = require('ethers-eip712')

const sha3 = web3.utils.sha3
const NFT3 = 23456
const NFT4 = 86543
const NFT5 = 76543
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
const { zeroAddress } = require('ethereumjs-util')

const getPrivateKey = (address) => {
  const wallet = web3.currentProvider.wallets[address.toLowerCase()]
  return `0x${wallet._privKey.toString('hex')}`
}

contract('SafeForERC1155', async accounts => {
  let token20, core,token1155, tokenSymbol, st, nonce, targetSupply, duration, initialSupply

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
      //assert(valBN instanceof web3.utils.BN, 'valBN should be big number')
  })

  before('setup contract for the test', async () => {
    token20 = await Token.new({ from: tokenOwner })
    core = await SafeForERC1155Core.new(user1, { from: user1 })
    st = await SafeForERC1155.new(core.address, { from: user1 })
    mlog.log('web3                    ', web3.version)
    mlog.log('token contract          ', token20.address)
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
    await token1155.setApprovalForAll(st.address,true, {from:tokenOwner})
    await token1155.setApprovalForAll(core.address,true, {from:tokenOwner})
    await token1155.setApprovalForAll(st.address,true, {from:user1})
    await token1155.setApprovalForAll(core.address,true, {from:user1})
    token721 = await ERC721Token.new('Kirobo ERC721 Token', 'KBF', {from: tokenOwner, nonce: await trNonce(web3, tokenOwner)});
    await token721.selfMint(NFT3, { from: user3 })
    await token721.selfMint(NFT4, { from: user4 })
    await token721.selfMint(NFT5, { from: tokenOwner })
    await token721.approve(st.address, NFT3, { from: user3 })
    await token721.approve(st.address, NFT4, { from: user4 })
    await token721.approve(st.address, NFT5, { from: tokenOwner })
    await token20.mint(tokenOwner, 1e10, { from: tokenOwner })
    await token20.mint(user1, 1e10, { from: tokenOwner })
    await token20.mint(user2, 1e10, { from: tokenOwner })
    await token20.mint(user3, 1e10, { from: tokenOwner })
    await token20.approve(st.address, 1e12, { from: tokenOwner })
    await token20.approve(st.address, 1e12, { from: user1 })
    await token20.approve(core.address, 1e12, { from: tokenOwner })
    await token20.approve(core.address, 1e12, { from: user1 })

    mlog.log('token721                 ',   token721.address);
    mlog.log('token1155                ',   token1155.address);
    mlog.log('token20                  ',   token20.address);
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
    await core.depositERC1155(token1155.address, user1, tokenId, value, tokenData, fees, secretHash, { from: tokenOwner, value: 20 })
  })

  it('should be able to retrieve a transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const tokenId = 1
    const value = 100
    const tokenData = "0x00"
    const fees = 20
    await core.retrieveERC1155(token1155.address, user1, tokenId, value, tokenData, fees, secretHash, { from: tokenOwner })
  })

  it('should be able to collect a transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const tokenId = 1
    const value = 100
    const tokenData = "0x00"
    const fees = 20
    await core.depositERC1155(token1155.address, user1, tokenId, value, tokenData, fees, secretHash, { from: tokenOwner, value: 20 })
    await core.collectERC1155(token1155.address, tokenOwner, user1, tokenId, value, tokenData, fees, secretHash, Buffer.from(secret), { from: user1 })
  })

  //single item in batch functions
  it('should be able to send one item in a batch function', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const tokenIds = [1]
    const values = [100]
    const tokenData = "0x00"
    const fees = 20
    await core.depositBatchERC1155(token1155.address, user1, tokenIds, values, tokenData, fees, secretHash, { from: tokenOwner, value: 20 })
    await core.collectBatchERC1155(user1, tokenOwner, {token: token1155.address ,tokenIds: tokenIds, values: values, tokenData: tokenData, fees: fees, 
                                  secretHash: secretHash, secret: Buffer.from(secret)}, { from: user1 })
  })

  it('should be able to collect a transfer timed request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const tokenId = 1
    const value = 100
    const tokenData = "0x00"
    const now = await getLatestBlockTimestamp()
    const fees = 20
    await core.timedDepositERC1155(token1155.address, user1, tokenId, value, tokenData, fees, secretHash, 0, now+10000, 0,{ from: tokenOwner, value: 20 })
    await core.collectERC1155(token1155.address, tokenOwner, user1, tokenId, value, tokenData, fees, secretHash, Buffer.from(secret), { from: user1 })
 })

 it('should be able to auto retrieve a transfer timed request', async () => {
  const secret = 'my secret'
    const secretHash = sha3(secret)
    const tokenId = 1
    const value = 100
    const tokenData = "0x00"
    const fees = 20
    const now = await getLatestBlockTimestamp()
    await core.timedDepositERC1155(token1155.address, user1, tokenId, value, tokenData, fees, secretHash, 0, now+10000, 0,{ from: tokenOwner, value: 20 })
    advanceTimeAndBlock(10000)
    await core.autoRetrieveERC1155(tokenOwner, token1155.address, user1, tokenId, value, tokenData, fees, secretHash, { from: tokenOwner })
})

it('should be able to make a hidden transfer request', async () => {
  const secret = 'my secret'
  const secretHash = sha3(secret)
  const id1 = sha3('1234')
  await core.hiddenERC1155Deposit(id1, { from: tokenOwner, value:100})
})

it('should be able to retrieve a hidden transfer request', async () => {
  const secret = 'my secret'
  const secretHash = sha3(secret)
  const id1 = sha3('1234')
  await core.hiddenERC1155Retrieve(id1, 100, { from: tokenOwner })
})

it('should be able to make a timed hidden transfer request', async () => {
  const secret = 'my secret'
  const secretHash = sha3(secret)
  const id1 = sha3('1234')
  const now = await getLatestBlockTimestamp()
  await core.hiddenERC1155TimedDeposit(id1, 0, now+10000, 0, { from: tokenOwner, value:100})
})

it('should be able to retrieve a hidden transfer request', async () => {
  const secret = 'my secret'
  const secretHash = sha3(secret)
  const id1 = sha3('1234')
  await core.hiddenERC1155Retrieve(id1, 100, { from: tokenOwner })
})

it('should be able to collect a hidden transfer request', async () => {
  const secret = 'my secret'
  const tokenId = 1
  const value = 100
  const tokenData = "0x00"
  const fees = 20
  const secretHash = sha3(secret)
  const id1 = sha3(defaultAbiCoder.encode(
    ['bytes32', 'address', 'address', 'address','uint256', 'uint256', 'bytes','uint256', 'bytes32'],
    [await core.HIDDEN_ERC1155_COLLECT_TYPEHASH(), tokenOwner, user1, token1155.address, tokenId, value, tokenData, fees, secretHash]
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
        { name: 'token',              type: 'address' },
        { name: 'tokenId',            type: 'uint256' },
        { name: 'value',              type: 'uint256' },
        { name: 'tokenData',          type: 'bytes'   },
        { name: 'fees',               type: 'uint256' },
        { name: 'secretHash',         type: 'bytes32' },
      ]
    },
    primaryType: 'hiddenCollect',
    domain: {
      name: await core.NAME(),
      version: await core.VERSION(),
      chainId: '0x' + web3.utils.toBN(await core.CHAIN_ID()).toString('hex'), // await web3.eth.getChainId(),
      verifyingContract: st.address,
      salt: await core.uid(),
    },
    message: {
      from: tokenOwner,
      to: user1,
      value: '0x' + web3.utils.toBN('600').toString('hex'),
      fees: '0x' + web3.utils.toBN('100').toString('hex'),
      secretHash,
    }
  }

  mlog.log('typedData: ', JSON.stringify(typedData, null, 2))
  mlog.log('CHAIN_ID', await core.CHAIN_ID())
  mlog.log('DOMAIN_SEPARATOR', await core.DOMAIN_SEPARATOR())
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

  await core.hiddenERC1155Deposit(id1, { from: tokenOwner, value: 700 })
  await core.hiddenERC1155Collect(tokenOwner, user1, 600, 100, secretHash, Buffer.from(secret), rlp.v, rlp.r, rlp.s, { from: user1 })
})

  // batch transfer

  it('should be able to make a batch transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const tokenIds = [0,1]
    const values = [100,200]
    const tokenData = "0x00"
    const fees = 20
    await core.depositBatchERC1155(token1155.address, user1, tokenIds, values, tokenData, fees, secretHash, { from: tokenOwner, value: 20 })
  })

  it('should be able to retrieve a batch transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const tokenIds = [0,1]
    const values = [100,200]
    const tokenData = "0x00"
    const fees = 20
    await core.retrieveBatchERC1155(token1155.address, user1, tokenIds, values, tokenData, fees, secretHash, { from: tokenOwner })
  })

  it('should be able to collect a batch transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const tokenIds = [0,1]
    const values = [100,200]
    const tokenData = "0x00"
    const fees = 20
    await core.depositBatchERC1155(token1155.address, user1, tokenIds, values, tokenData, fees, secretHash, { from: tokenOwner, value: 20 })
    await core.collectBatchERC1155(user1, tokenOwner, {token: token1155.address ,tokenIds: tokenIds, values: values, tokenData: tokenData, fees: fees, 
                                  secretHash: secretHash, secret: Buffer.from(secret)}, { from: user1 })
  })

  it('should be able to make a timed batch transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const tokenIds = [0,1]
    const values = [100,200]
    const tokenData = "0x00"
    const fees = 20
    const token = token1155.address;
    const now = await getLatestBlockTimestamp()
    const availableAt = 0;
    const expiresAt = now+10000;
    const autoRetrieveFees = 0;
    await core.TimedDepositBatchERC1155(user1, {token, tokenIds, values, fees, secretHash, availableAt , expiresAt, autoRetrieveFees}, tokenData, { from: tokenOwner, value: 20 })
  })

  it('should be able to retrieve a batch transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const tokenIds = [0,1]
    const values = [100,200]
    const tokenData = "0x00"
    const fees = 20
    await core.retrieveBatchERC1155(token1155.address, user1, tokenIds, values, tokenData, fees, secretHash, { from: tokenOwner })
  })

  it('should be able to auto retrive a timed batch transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const tokenIds = [0,1]
    const values = [100,200]
    const tokenData = "0x00"
    const fees = 20
    const token = token1155.address;
    const now = await getLatestBlockTimestamp()
    const availableAt = 0;
    const expiresAt = now+10000;
    const autoRetrieveFees = 0;
    await core.TimedDepositBatchERC1155(user1, {token, tokenIds, values, fees, secretHash, availableAt , expiresAt, autoRetrieveFees}, tokenData, { from: tokenOwner, value: 20 })
    advanceTimeAndBlock(10000)
    await core.autoRetrieveBatchERC1155(tokenOwner, token1155.address, user1, tokenIds, values, tokenData, fees, secretHash, { from: tokenOwner })
  })

  it('should be able to make a hidden batch transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const id1 = sha3('1234')
    await core.hiddenBatchERC1155Deposit(id1, { from: tokenOwner, value:100})
  })
  
  it('should be able to retrieve a hidden batch transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const id1 = sha3('1234')
    await core.hiddenBatchERC1155Retrieve(id1, 100, { from: tokenOwner })
  })
  
  it('should be able to make a timed hidden transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const id1 = sha3('1234')
    const now = await getLatestBlockTimestamp()
    await core.hiddenBatchERC1155TimedDeposit(id1, 0, now+10000, 0, { from: tokenOwner, value:100})
  })
  
  it('should be able to retrieve a hidden transfer request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const id1 = sha3('1234')
    await core.hiddenBatchERC1155Retrieve(id1, 100, { from: tokenOwner })
  })

  //  swap 1155 to ETH

  it('should be able to deposit a swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0,1]
    const values0 = [100,200]
    const tokenData0 = "0x00"
    const fees0 = 20
    const token1 = ZERO_ADDRESS
    const tokenIds1 = [0]
    const values1 = [100000000000]
    const tokenData1 = "0x00"
    const fees1 = 40
    await st.swapDepositERC1155(user1, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:tokenOwner, value:fees0})
  })

  it('should be able to retrieve a swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0,1]
    const values0 = [100,200]
    const tokenData0 = "0x00"
    const fees0 = 20
    const token1 = ZERO_ADDRESS
    const tokenIds1 = [0]
    const values1 = [100000000000]
    const tokenData1 = "0x00"
    const fees1 = 40
    await st.swapRetrieveERC1155(user1, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:tokenOwner})
  })

  it('should be able to collect a swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0,1]
    const values0 = [100,200]
    const tokenData0 = "0x00"
    const fees0 = 20
    const token1 = ZERO_ADDRESS
    const tokenIds1 = [0]
    const values1 = [100000000000]
    const tokenData1 = "0x00"
    const fees1 = 40
    const trxValue = values1[0]+fees1
    await st.swapDepositERC1155(user1, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:tokenOwner, value:fees0})
    await st.swapERC1155(tokenOwner, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, Buffer.from(secret), {from:user1, value: trxValue})
  })

  it('should be able to deposit a single 1155 swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0]
    const values0 = [100]
    const tokenData0 = "0x00"
    const fees0 = 20
    const token1 = ZERO_ADDRESS
    const tokenIds1 = [0]
    const values1 = [100000000000]
    const tokenData1 = "0x00"
    const fees1 = 40
    await st.swapDepositERC1155(user1, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:tokenOwner, value:fees0})
  })

  it('should be able to retrieve a single 1155 swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0]
    const values0 = [100]
    const tokenData0 = "0x00"
    const fees0 = 20
    const token1 = ZERO_ADDRESS
    const tokenIds1 = [0]
    const values1 = [100000000000]
    const tokenData1 = "0x00"
    const fees1 = 40
    await st.swapRetrieveERC1155(user1, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:tokenOwner})
  })

  it('should be able to collect a single 1155 swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0]
    const values0 = [100]
    const tokenData0 = "0x00"
    const fees0 = 20
    const token1 = ZERO_ADDRESS
    const tokenIds1 = [0]
    const values1 = [100000000000]
    const tokenData1 = "0x00"
    const fees1 = 40
    const trxValue = values1[0]+fees1
    await st.swapDepositERC1155(user1, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:tokenOwner, value:fees0})
    await st.swapERC1155(tokenOwner, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, Buffer.from(secret), {from:user1, value: trxValue})
  })

  //  swap ETH to 1155

  it('should be able to deposit a swap request', async () => {
    const secret = 'my secret'
    const token1 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0]
    const values0 = [100000000000]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token0 = ZERO_ADDRESS
    const tokenIds1 = [0,3]
    const values1 = [100,200]
    const tokenData1 = "0x00"
    const fees1 = 20
    const trxValue = values0[0]+fees0
    await st.swapDepositERC1155(tokenOwner, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:user1, value:trxValue})
  })

  it('should be able to retrieve a swap request', async () => {
    const secret = 'my secret'
    const token1 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0]
    const values0 = [100000000000]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token0 = ZERO_ADDRESS
    const tokenIds1 = [0,3]
    const values1 = [100,200]
    const tokenData1 = "0x00"
    const fees1 = 20
    const trxValue = values0[0]+fees0
    await st.swapRetrieveERC1155(tokenOwner, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:user1})
  })

  it('should be able to collect a swap request', async () => {
    const secret = 'my secret'
    const token1 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0]
    const values0 = [100000000000]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token0 = ZERO_ADDRESS
    const tokenIds1 = [0,3]
    const values1 = [100,200]
    const tokenData1 = "0x00"
    const fees1 = 20
    const trxValue = values0[0]+fees0
    await st.swapDepositERC1155(tokenOwner, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:user1, value:trxValue})
    await st.swapERC1155(user1, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, Buffer.from(secret), {from:tokenOwner, value: fees1})
  })


  //  swap 721 to 1155

  it('should be able to deposit a swap request', async () => {
    const secret = 'my secret'
    const token1 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [NFT3]
    const values0 = [0]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token0 = token721.address
    const tokenIds1 = [0,3]
    const values1 = [100,200]
    const tokenData1 = "0x00"
    const fees1 = 20
    await st.swapDepositERC1155(tokenOwner, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:user3, value:fees0})
  })

  it('should be able to retrieve a swap request', async () => {
    const secret = 'my secret'
    const token1 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [NFT3]
    const values0 = [0]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token0 = token721.address
    const tokenIds1 = [0,3]
    const values1 = [100,200]
    const tokenData1 = "0x00"
    const fees1 = 20
    await st.swapRetrieveERC1155(tokenOwner, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:user3})
  })

  it('should be able to collect a swap request', async () => {
    const secret = 'my secret'
    const token1 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [NFT3]
    const values0 = [0]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token0 = token721.address
    const tokenIds1 = [0,3]
    const values1 = [100,200]
    const tokenData1 = "0x00"
    const fees1 = 20
    await st.swapDepositERC1155(tokenOwner, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:user3, value:fees0})
    await st.swapERC1155(user3, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, Buffer.from(secret), {from:tokenOwner, value: fees1})
  }) 

  //  swap 1155 to 721

  it('should be able to deposit a swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const tokenIds0 = [0,3]
    const values0 = [100,200]
    const tokenData0 = "0x00"
    const fees0 = 20
    const token1 = token721.address
    const tokenIds1 = [NFT5]
    const values1 = [0]
    const tokenData1 = "0x00"
    const fees1 = 40
    const secretHash = sha3(secret)
    await st.swapDepositERC1155(tokenOwner, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:user3, value:fees0})
  })

  it('should be able to retrieve a swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const tokenIds0 = [0,3]
    const values0 = [100,200]
    const tokenData0 = "0x00"
    const fees0 = 20
    const token1 = token721.address
    const tokenIds1 = [NFT5]
    const values1 = [0]
    const tokenData1 = "0x00"
    const fees1 = 40
    const secretHash = sha3(secret)
    await st.swapRetrieveERC1155(tokenOwner, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:user3})
  })

  it('should be able to collect a swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const tokenIds0 = [0,3]
    const values0 = [100,200]
    const tokenData0 = "0x00"
    const fees0 = 20
    const token1 = token721.address
    const tokenIds1 = [NFT5]
    const values1 = [0]
    const tokenData1 = "0x00"
    const fees1 = 40
    const secretHash = sha3(secret)
    console.log("owner", await token721.ownerOf(tokenIds1[0]));
    await token1155.setApprovalForAll(st.address,true, {from:user3})
    await st.swapDepositERC1155(tokenOwner, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:user3, value:fees0})
    await st.swapERC1155(user3, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, Buffer.from(secret), {from:tokenOwner, value: fees1})
  }) 

  // swap 1155 with 1155

  it('should be able to deposit a swap request', async () => {
    const secret = 'my secret'
    const token1 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0,1]
    const values0 = [10, 20]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token0 = token1155.address
    const tokenIds1 = [0,3]
    const values1 = [100,200]
    const tokenData1 = "0x00"
    const fees1 = 20
    await st.swapDepositERC1155(tokenOwner, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:user1, value:fees0})
  })

  it('should be able to retrieve a swap request', async () => {
    const secret = 'my secret'
    const token1 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0,1]
    const values0 = [10, 20]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token0 = token1155.address
    const tokenIds1 = [0,3]
    const values1 = [100,200]
    const tokenData1 = "0x00"
    const fees1 = 20
    await st.swapRetrieveERC1155(tokenOwner, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:user1})
  })

  it('should be able to collect a swap request', async () => {
    const secret = 'my secret'
    const token1 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0,1]
    const values0 = [10, 20]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token0 = token1155.address
    const tokenIds1 = [0,3]
    const values1 = [100,200]
    const tokenData1 = "0x00"
    const fees1 = 20
    await st.swapDepositERC1155(tokenOwner, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:user1, value:fees0})
    await st.swapERC1155(user1, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, Buffer.from(secret), {from:tokenOwner, value: fees1})
  }) 

  // swap 1155 to eth

  it('should be able to deposit a swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0,1]
    const values0 = [10, 20]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token1 = ZERO_ADDRESS
    const tokenIds1 = [0]
    const values1 = [100]
    const tokenData1 = "0x00"
    const fees1 = 20
    await st.swapDepositERC1155(tokenOwner, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:user1, value:fees0})
  })

  it('should be able to retrieve a swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0,1]
    const values0 = [10, 20]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token1 = ZERO_ADDRESS
    const tokenIds1 = [0]
    const values1 = [100]
    const tokenData1 = "0x00"
    const fees1 = 20
    await st.swapRetrieveERC1155(tokenOwner, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:user1})
  })

  it('should be able to collect a swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0,1]
    const values0 = [10, 20]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token1 = ZERO_ADDRESS
    const tokenIds1 = [0]
    const values1 = [100]
    const tokenData1 = "0x00"
    const fees1 = 20
    const trxValue = fees1 + values1[0];
    await st.swapDepositERC1155(tokenOwner, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:user1, value:fees0})
    await st.swapERC1155(user1, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, Buffer.from(secret), {from:tokenOwner, value: trxValue})
  }) 

  // auto retrive swap 1155 to eth

  it('should be able to deposit a swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0,1]
    const values0 = [10, 20]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token1 = ZERO_ADDRESS
    const tokenIds1 = [0]
    const values1 = [100]
    const tokenData1 = "0x00"
    const fees1 = 20
    const now = await getLatestBlockTimestamp()
    await st.timedSwapDepositERC1155(tokenOwner, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash},0, now+10000, 0, {from:user1, value:fees0})
  })

  it('should be able to retrieve a swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0,1]
    const values0 = [10, 20]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token1 = ZERO_ADDRESS
    const tokenIds1 = [0]
    const values1 = [100]
    const tokenData1 = "0x00"
    const fees1 = 20
    await st.swapRetrieveERC1155(tokenOwner, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:user1})
  })

  it('should be able to deposit a swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0,1]
    const values0 = [10, 20]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token1 = ZERO_ADDRESS
    const tokenIds1 = [0]
    const values1 = [100]
    const tokenData1 = "0x00"
    const fees1 = 20
    const now = await getLatestBlockTimestamp()
    await st.timedSwapDepositERC1155(tokenOwner, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash},0, now+10000, 0, {from:user1, value:fees0})
    advanceTimeAndBlock(10000)
    await st.autoSwapRetrieveERC1155(user1, tokenOwner, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:user1})
  })

  // swap ERC20 with batch 1155

  it('should be able to deposit an ERC20 swap request', async () => {
    const secret = 'my secret'
    const token0 = token20.address
    const secretHash = sha3(secret)
    const tokenId0 = 0
    const value0 = 100
    const tokenData0 = "0x00"
    const fees0 = 40
    const token1 = token1155.address
    const tokenIds1 = [0,3]
    const values1 = [100,100]
    const tokenData1 = "0x00"
    const fees1 = 20
    await st.swapDepositERC20ToERC1155(user1, {token0, tokenId0, value0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:tokenOwner, value:fees0})
  })

  it('should be able to retrieve an ERC20 swap request', async () => {
    const secret = 'my secret'
    const token0 = token20.address
    const secretHash = sha3(secret)
    const tokenId0 = 0
    const value0 = 100
    const tokenData0 = "0x00"
    const fees0 = 40
    const token1 = token1155.address
    const tokenIds1 = [0,3]
    const values1 = [100,100]
    const tokenData1 = "0x00"
    const fees1 = 20
    await st.swapRetrieveERC20ToERC1155(user1, {token0, tokenId0, value0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:tokenOwner})
  })

  it('should be able to collect an ERC20 swap request', async () => {
    const secret = 'my secret'
    const token0 = token20.address
    const secretHash = sha3(secret)
    const tokenId0 = 0
    const value0 = 100
    const tokenData0 = "0x00"
    const fees0 = 40
    const token1 = token1155.address
    const tokenIds1 = [0,3]
    const values1 = [100,100]
    const tokenData1 = "0x00"
    const fees1 = 20
    await st.swapDepositERC20ToERC1155(user1, {token0, tokenId0, value0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, {from:tokenOwner, value:fees0})
    await st.swapERC20ToERC1155(tokenOwner, {token0, tokenId0, value0, tokenData0, fees0, token1, tokenIds1, values1, tokenData1, fees1, secretHash}, Buffer.from(secret), {from:user1, value: fees1})
  }) 

  // swap batch 1155 with ERC20

  it('should be able to deposit an ERC1155 swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0,3]
    const values0 = [100,100]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token1 = token20.address
    const tokenId1 = 0
    const value1 = 100
    const tokenData1 = "0x00"
    const fees1 = 20
    await st.swapDepositERC1155ToERC20(user1, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash}, {from:tokenOwner, value:fees0})
  })

  it('should be able to retrieve an ERC1155 swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0,3]
    const values0 = [100,100]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token1 = token20.address
    const tokenId1 = 0
    const value1 = 100
    const tokenData1 = "0x00"
    const fees1 = 20
    await st.swapRetrieveERC1155ToERC20(user1, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash}, {from:tokenOwner})
  })

  it('should be able to collect an ERC1155 swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0,3]
    const values0 = [100,100]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token1 = token20.address
    const tokenId1 = 0
    const value1 = 100
    const tokenData1 = "0x00"
    const fees1 = 20
    await st.swapDepositERC1155ToERC20(user1, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash}, {from:tokenOwner, value:fees0})
    await st.swapERC1155ToERC20(tokenOwner, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash}, Buffer.from(secret), {from:user1, value: fees1})
  }) 

  // auto retrive swap batch 1155 with ERC20

  it('should be able to deposit an ERC1155 swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0,3]
    const values0 = [100,100]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token1 = token20.address
    const tokenId1 = 0
    const value1 = 100
    const tokenData1 = "0x00"
    const fees1 = 20
    const now = await getLatestBlockTimestamp() 
    await st.timedSwapDepositERC1155ToERC20(user1, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash},0, now+10000, 0, {from:tokenOwner, value:fees0})
  })

  it('should be able to retrieve an ERC1155 swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0,3]
    const values0 = [100,100]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token1 = token20.address
    const tokenId1 = 0
    const value1 = 100
    const tokenData1 = "0x00"
    const fees1 = 20
    await st.swapRetrieveERC1155ToERC20(user1, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash}, {from:tokenOwner})
  })

  it('should be able to deposit an ERC1155 swap request', async () => {
    const secret = 'my secret'
    const token0 = token1155.address
    const secretHash = sha3(secret)
    const tokenIds0 = [0,3]
    const values0 = [100,100]
    const tokenData0 = "0x00"
    const fees0 = 40
    const token1 = token20.address
    const tokenId1 = 0
    const value1 = 100
    const tokenData1 = "0x00"
    const fees1 = 20
    const now = await getLatestBlockTimestamp() 
    await st.timedSwapDepositERC1155ToERC20(user1, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash},0, now+10000, 0, {from:tokenOwner, value:fees0})
    advanceTimeAndBlock(10000)
    await st.autoSwapRetrieveERC1155ToERC20(tokenOwner, user1, {token0, tokenIds0, values0, tokenData0, fees0, token1, tokenId1, value1, tokenData1, fees1, secretHash}, {from:tokenOwner})
  })

  //hidden 1155 to eth

  it('should be able to make a hidden swap request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const id1 = sha3('1234')
    await st.hiddenBatchERC1155SwapDeposit(id1, { from: tokenOwner, value:100})
  })
  
  it('should be able to retrieve a hidden swap request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const id1 = sha3('1234')
    await st.hiddenBatchERC1155SwapRetrieve(id1, 100, { from: tokenOwner })
  })
  
  it('should be able to make a timed hidden swap request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const id1 = sha3('1234')
    const now = await getLatestBlockTimestamp()
    await st.hiddenERC1155TimedSwapDeposit(id1, 0, now+10000, 0, { from: tokenOwner, value:100})
  })
  
  it('should be able to retrieve a hidden swap request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const id1 = sha3('1234')
    await st.hiddenBatchERC1155SwapRetrieve(id1, 100, { from: tokenOwner })
  })

  //hidden 1155 to erc20

  it('should be able to make a hidden swap request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const id1 = sha3('1234')
    await st.hiddenBatchERC1155ToERC20SwapDeposit(id1, { from: tokenOwner, value:100})
  })
  
  it('should be able to retrieve a hidden swap request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const id1 = sha3('1234')
    await st.hiddenBatchERC1155ToERC20SwapRetrieve(id1, 100, { from: tokenOwner })
  })
  
  it('should be able to make a timed hidden swap request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const id1 = sha3('1234')
    const now = await getLatestBlockTimestamp()
    await st.hiddenERC1155ToERC20TimedSwapDeposit(id1, 0, now+10000, 0, { from: tokenOwner, value:100})
  })
  
  it('should be able to retrieve a hidden swap request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const id1 = sha3('1234')
    await st.hiddenBatchERC1155ToERC20SwapRetrieve(id1, 100, { from: tokenOwner })
  })
 
  })

