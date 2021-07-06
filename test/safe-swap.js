'use strict'

const Token = artifacts.require("Token")
const SafeSwap = artifacts.require('SafeSwap')
const mlog = require('mocha-logger')
const ERC721Token = artifacts.require("ERC721Token")

const { ethers } = require('ethers')
const { defaultAbiCoder, keccak256, toUtf8Bytes } = ethers.utils
const { TypedDataUtils } = require('ethers-eip712')

const sha3 = web3.utils.sha3
const NFT4 = 23456
const NFT6 = 12345
const NFT7 = 45678
const NFT8 = 45633
const NFT9 = 73454
const NFT10 = 54654
const NFT11 = 45454
const NFT12 = 45455

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

contract('SafeSwap', async accounts => {
  let token, tokenSymbol, st, nonce, targetSupply, duration, initialSupply

  const tokenOwner = accounts[1]
  const user1 = accounts[2]
  const user2 = accounts[3]
  const user3 = accounts[4]
  const user4 = accounts[5]
  const user5 = accounts[6]
  const user6 = accounts[7]
  const user7 = accounts[8]
  const user8 = accounts[9]

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
      assert(typeof user5         == 'string', 'user5 should be string')
      assert(typeof user6         == 'string', 'user6 should be string')
      assert(typeof user7         == 'string', 'user7 should be string')
      assert(typeof user8         == 'string', 'user8 should be string')
      assert(typeof val1          == 'string', 'val1  should be big number')
      assert(typeof val2          == 'string', 'val2  should be string')
      assert(typeof val3          == 'string', 'val2  should be string')
      assert(valBN instanceof web3.utils.BN, 'valBN should be big number')
  })

  before('setup contract for the test', async () => {
    token = await Token.new({ from: tokenOwner })
    st = await SafeSwap.new(user1, { from: user1 })
    mlog.log('web3                    ', web3.version)
    mlog.log('token contract          ', token.address)
    mlog.log('safe swap contract  ', st.address)
    mlog.log('token Owner             ', tokenOwner)
    mlog.log('user1                   ', user1)
    mlog.log('user2                   ', user2)
    mlog.log('user3                   ', user3)
    mlog.log('user4                   ', user4)
    mlog.log('user5                   ', user5)
    mlog.log('user6                   ', user6)
    mlog.log('user7                   ', user7)
    mlog.log('user8                   ', user8)
    mlog.log('val1                    ', val1)
    mlog.log('val2                    ', val2)
    mlog.log('val3                    ', val3)

    await token.mint(user1, 1e10, { from: tokenOwner })
    await token.mint(user2, 1e10, { from: tokenOwner })
    await token.mint(user3, 1e10, { from: tokenOwner })
    tokenSymbol = await token.symbol()
    token721 = await ERC721Token.new('Kirobo ERC721 Token', 'KBF', {from: tokenOwner});
    await token721.selfMint(NFT4, { from: user4 })
    await token721.selfMint(NFT6, { from: user6 })
    await token721.selfMint(NFT7, { from: user7 })
    await token721.selfMint(NFT8, { from: user8 })

    mlog.log('token721  ',   token721.address);

  })

  it('should create an empty contract', async () => {
    assert.equal('0', ''+(await web3.eth.getBalance(st.address)))
  })

  /*
function deposit(
        address payable to,
        address token0,
        uint256 value0,
        uint256 fees0,
        address token1,
        uint256 value1,
        uint256 fees1,
        bytes32 secretHash
  */

  it('should be able to make a swap request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    await st.deposit(user3, ZERO_ADDRESS, 600, 100, token.address, 50, 10, secretHash, { from: user2, value: 700 })
  })

  it('should be able to retrieve a swap request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    await st.retrieve(user3, ZERO_ADDRESS, 600, 100, token.address, 50, 10, secretHash, { from: user2 })
  })

  it('should be able to reject a swap request', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    await st.deposit(user3, ZERO_ADDRESS, 600, 100, token.address, 50, 10, secretHash, { from: user2, value: 700 })
    await st.reject(user2, ZERO_ADDRESS, 600, 100, token.address, 50, 10, secretHash, { from: user3 })
  })

  it('should fail when to and from are the same', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)

    await mustRevert(async ()=> {
      await st.deposit(user4, token.address, 90, 10, ZERO_ADDRESS, 50, 10, secretHash,
        { from: user4, value: 10, nonce: await trNonce(web3, user4) })
    })
  })

  it('should fail when the 2 tokens are the same in deposit', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    await token.approve(st.address, 1e12, { from: user3 })
    await mustRevert(async ()=> {
      await st.deposit(user4, ZERO_ADDRESS, 100, 10, ZERO_ADDRESS, 50, 10, secretHash,
        { from: user3, value: 10, nonce: await trNonce(web3, user3) })
    })

    await mustRevert(async ()=> {
      await st.deposit(user4, token.address, 100, 10, token.address, 50, 10, secretHash,
        { from: user3, value: 10, nonce: await trNonce(web3, user3) })
    })
  })

  it('should fail when the 2 tokens are the same in swap', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    await token.approve(st.address, 1e12, { from: user3 })

    await st.deposit(user4, token.address, 20, 10, ZERO_ADDRESS, 50, 10, secretHash,
      { from: user3, value: 10, nonce: await trNonce(web3, user3) })

    await mustRevert(async ()=> {
      await st.swap(user3, ZERO_ADDRESS, 20, 10, ZERO_ADDRESS, 50, 10, secretHash, Buffer.from(secret),
      { from: user4, value: 60, nonce: await trNonce(web3, user4) })
    })

    await mustRevert(async ()=> {
      await st.swap(user3, token.address, 20, 10, token.address, 50, 10, secretHash, Buffer.from(secret),
      { from: user4, value: 60, nonce: await trNonce(web3, user4) })
    })

  })

  it('should fail when deposit and swap IDs are different', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    await token.approve(st.address, 1e12, { from: user3 })
    
    await st.deposit(user4, token.address, 70, 10, ZERO_ADDRESS, 50, 10, secretHash,
    { from: user3, value: 10, nonce: await trNonce(web3, user3) })

    await mustRevert(async ()=> {
      await st.swap(user3, token.address, 40, 10, ZERO_ADDRESS, 50, 10, secretHash, Buffer.from(secret),
      { from: user4, value: 60, nonce: await trNonce(web3, user4) })
    })
  })

  it('should fail when 2 identicale diposites are created', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    await token.approve(st.address, 1e12, { from: user3 })
    
    await st.deposit(user4, token.address, 80, 10, ZERO_ADDRESS, 50, 10, secretHash,
      { from: user3, value: 10, nonce: await trNonce(web3, user3) })

    await mustRevert(async ()=> {
      await st.deposit(user4, token.address, 80, 10, ZERO_ADDRESS, 50, 10, secretHash,
        { from: user3, value: 10, nonce: await trNonce(web3, user3) })
    })
  })

  it('should be able to collect a transfer request from token to ether', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    await token.approve(st.address, 1e12, { from: user3 })

    let balance7 = await web3.eth.getBalance(user3)
    let balance8 = await web3.eth.getBalance(user4)
    console.log("user3 balance =", web3.utils.fromWei(balance7,'ether'))
    console.log("user4 balance =", web3.utils.fromWei(balance8,'ether'))
    
    await mustRevert(async ()=> {
      await st.deposit(user4, token.address, 30, 10, ZERO_ADDRESS, 50, 10, secretHash,
      { from: user3, value: 40, nonce: await trNonce(web3, user3) })
    })

    await mustRevert(async ()=> {
      await st.deposit(user4, token.address, 30, 10, ZERO_ADDRESS, 50, 10, secretHash,
      { from: user3, value: 50, nonce: await trNonce(web3, user3) })
    })

    await mustRevert(async ()=> {
      await st.deposit(user4, token.address, 30, 10, ZERO_ADDRESS, 50, 10, secretHash,
      { from: user3, value: 30, nonce: await trNonce(web3, user3) })
    })

    await st.deposit(user4, token.address, 30, 10, ZERO_ADDRESS, 50, 10, secretHash,
      { from: user3, value: 10, nonce: await trNonce(web3, user3) })

    await mustRevert(async ()=> {
      await st.swap(user3, token.address, 30, 10, ZERO_ADDRESS, 50, 10, secretHash, Buffer.from(secret),
      { from: user4, value: 50, nonce: await trNonce(web3, user4) })
    })

    await mustRevert(async ()=> {
      await st.swap(user3, token.address, 30, 10, ZERO_ADDRESS, 50, 10, secretHash, Buffer.from(secret),
      { from: user4, value: 10, nonce: await trNonce(web3, user4) })
    })

    await mustRevert(async ()=> {
      await st.swap(user3, token.address, 30, 10, ZERO_ADDRESS, 50, 10, secretHash, Buffer.from(secret),
      { from: user4, value: 70, nonce: await trNonce(web3, user4) })
    })

    await mustRevert(async ()=> {
      await st.swap(user3, token.address, 30, 10, ZERO_ADDRESS, 50, 10, secretHash, Buffer.from(secret),
      { from: user4, value: 5, nonce: await trNonce(web3, user4) })
    })

    await mustRevert(async ()=> {
      await st.swap(user3, token.address, 30, 10, ZERO_ADDRESS, 50, 10, secretHash, Buffer.from(secret),
      { from: user4, value: 0, nonce: await trNonce(web3, user4) })
    })

    await st.swap(user3, token.address, 30, 10, ZERO_ADDRESS, 50, 10, secretHash, Buffer.from(secret),
      { from: user4, value: 60, nonce: await trNonce(web3, user4) })

      balance7 = await web3.eth.getBalance(user3)
     balance8 = await web3.eth.getBalance(user4)
      console.log("user3 balance =", web3.utils.fromWei(balance7,'ether'))
      console.log("user4 balance =", web3.utils.fromWei(balance8,'ether'))
    
  })
      

  it('should be able to collect a transfer request from ether to token', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    await token.approve(st.address, 1e12, { from: user1 })
    
    await mustRevert(async ()=> {
      await st.deposit(user1, ZERO_ADDRESS, 600, 100, token.address, 50, 10, secretHash,
      { from: user2, value: 100, nonce: await trNonce(web3, user2) })
    })

   await mustRevert(async ()=> {
      await st.deposit(user1, ZERO_ADDRESS, 600, 100, token.address, 50, 10, secretHash,
      { from: user2, value: 600, nonce: await trNonce(web3, user2) })
   })

    await mustRevert(async ()=> {
      await st.deposit(user1, ZERO_ADDRESS, 600, 100, token.address, 50, 10, secretHash,
      { from: user2, value: 0, nonce: await trNonce(web3, user2) })
    })

    await mustRevert(async ()=> {
      await st.deposit(user1, ZERO_ADDRESS, 600, 100, token.address, 50, 10, secretHash,
      { from: user2, value: 1000, nonce: await trNonce(web3, user2) })
    })

    await st.deposit(user1, ZERO_ADDRESS, 600, 100, token.address, 50, 10, secretHash,
      { from: user2, value: 700, nonce: await trNonce(web3, user2) })

    await mustRevert(async ()=> {
      await st.swap(user2, ZERO_ADDRESS, 600, 100, token.address, 50, 10, secretHash, Buffer.from(secret),
      { from: user1, value: 60, nonce: await trNonce(web3, user1) })
    })

    await mustRevert(async ()=> {
      await st.swap(user2, ZERO_ADDRESS, 600, 100, token.address, 50, 10, secretHash, Buffer.from(secret),
      { from: user1, value: 6, nonce: await trNonce(web3, user1) })
    })

    await mustRevert(async ()=> {
      await st.swap(user2, ZERO_ADDRESS, 600, 100, token.address, 50, 10, secretHash, Buffer.from(secret),
      { from: user1, value: 50, nonce: await trNonce(web3, user1) })
    })

    await mustRevert(async ()=> {
      await st.swap(user2, ZERO_ADDRESS, 600, 100, token.address, 50, 10, secretHash, Buffer.from(secret),
      { from: user1, value: 70, nonce: await trNonce(web3, user1) })
    })

    await st.swap(user2, ZERO_ADDRESS, 600, 100, token.address, 50, 10, secretHash, Buffer.from(secret),
      { from: user1, value: 10, nonce: await trNonce(web3, user1) })
  })

  /*                ERC-721     */

  /*
    function depositERC721(
       address payable to,
        address token0,
        uint256 value0, //in case of ether it's a value, in case of 721 it's tokenId
        bytes calldata tokenData0,
        uint256 fees0,
        address token1,
        uint256 value1, //in case of ether it's a value, in case of 721 it's tokenId
        bytes calldata tokenData1,
        uint256 fees1,
        bytes32 secretHash
    ) 
  */


  it('should be able to swap 721 token - Ether to 721', async () => {
    const secret = 'my secret'
    const secret2 = 'my secret word'
    const secretHash = sha3(secret)
    const tokenId = NFT4;
    const tokenData = 1;
    const zero_tokenId = 0;

    let balance1 = await web3.eth.getBalance(user3)
    let balance2 = await web3.eth.getBalance(user4)
    console.log(web3.utils.fromWei(balance1,'ether'))
    console.log(web3.utils.fromWei(balance2,'ether'))


    //msg.value < value0 + fees0 
    await mustRevert(async ()=> {
      await st.depositERC721(user4, ZERO_ADDRESS, 150, tokenData, 10, token721.address, tokenId, tokenData, 10, secretHash,
        { from: user3, value: 110, nonce: await trNonce(web3, user3) })
    })

    //msg.value > value0 + fees0
    await mustRevert(async ()=> {
      await st.depositERC721(user4, ZERO_ADDRESS, 150, tokenData, 10, token721.address, tokenId, tokenData, 10, secretHash,
        { from: user3, value: 170, nonce: await trNonce(web3, user3) })
    })

    //msg.value = fees0
    await mustRevert(async ()=> {
      await st.depositERC721(user4, ZERO_ADDRESS, 150, tokenData, 10, token721.address, tokenId, tokenData, 10, secretHash,
        { from: user3, value: 10, nonce: await trNonce(web3, user3) })
    })

    ////msg.value = value0
    await mustRevert(async ()=> {
      await st.depositERC721(user4, ZERO_ADDRESS, 150, tokenData, 10, token721.address, tokenId, tokenData, 10, secretHash,
        { from: user3, value: 150, nonce: await trNonce(web3, user3) })
    })

    //ether to ether
    await mustRevert(async ()=> {
      await st.depositERC721(user4, ZERO_ADDRESS, 150, tokenData, 10, ZERO_ADDRESS, 120, tokenData, 10, secretHash,
        { from: user3, value: 160, nonce: await trNonce(web3, user3) })
    })

    //ether to 721 when tokenId is 0
    await mustRevert(async ()=> {
      await st.depositERC721(user4, ZERO_ADDRESS, 150, tokenData, 10, token721.address, zero_tokenId, tokenData, 10, secretHash,
        { from: user3, value: 160, nonce: await trNonce(web3, user3) })
    })
    

    await st.depositERC721(user4, ZERO_ADDRESS, 150, tokenData, 10, token721.address, tokenId, tokenData, 10, secretHash,
    { from: user3, value: 160, nonce: await trNonce(web3, user3) })

    //same trx second time
    await mustRevert(async ()=> {
      await st.depositERC721(user4, ZERO_ADDRESS, 150, tokenData, 10, token721.address, tokenId, tokenData, 10, secretHash,
      { from: user3, value: 160, nonce: await trNonce(web3, user3) })
    })

    const params = {from: user3, token0: ZERO_ADDRESS, value0: 150, tokenData0:tokenData, fees0:10, token1:token721.address, 
                    value1:tokenId, tokenData1:tokenData, fees1:10, secretHash:secretHash, secret:Buffer.from(secret)}

    const params1 = {from: user3, token0: ZERO_ADDRESS, value0: 160, tokenData0:tokenData, fees0:10, token1:token721.address, 
      value1:tokenId, tokenData1:tokenData, fees1:10, secretHash:secretHash, secret:Buffer.from(secret)}

    const params2 = {from: user3, token0: ZERO_ADDRESS, value0: 150, tokenData0:tokenData, fees0:10, token1:token721.address, 
        value1:tokenId, tokenData1:tokenData, fees1:10, secretHash:sha3(secret), secret:Buffer.from(secret2)}

    await token721.approve(st.address, tokenId, { from: user4 })

    //request not exists
    await mustRevert(async ()=> {
      await st.swapERC721(params1,{ from: user4, value: 10, nonce: await trNonce(web3, user4) })
    })

    //wrong secret
    await mustRevert(async ()=> {
      await st.swapERC721(params2,{ from: user4, value: 10, nonce: await trNonce(web3, user4) })
    })

    await st.swapERC721(params,{ from: user4, value: 10, nonce: await trNonce(web3, user4) })

    balance1 = await web3.eth.getBalance(user3)
    balance2 = await web3.eth.getBalance(user4)
    console.log(web3.utils.fromWei(balance1,'ether'))
    console.log(web3.utils.fromWei(balance2,'ether'))

    })

    it('should fail on sender == recepient - Ether to 721', async () => {
      const secret = 'my secret'
      const secretHash = sha3(secret)
      const tokenId = NFT4;
      const tokenData = 1;
      const zero_tokenId = 0;
  
       await mustRevert(async ()=> {
        await st.depositERC721(user4, ZERO_ADDRESS, 150, tokenData, 10, token721.address, tokenId, tokenData, 10, secretHash,
          { from: user4, value: 160, nonce: await trNonce(web3, user4) })
      }) 
    })

    it('should fail on value mismatch - 721 to Ether', async () => {
      const secret = 'my secret'
      const secretHash = sha3(secret)
      const tokenId = NFT6;
      const tokenData = 1;
      const zero_tokenId = 0;
      let balance5 = await web3.eth.getBalance(user5)
      let balance6 = await web3.eth.getBalance(user6)
      console.log(web3.utils.fromWei(balance5,'ether'))
      console.log(web3.utils.fromWei(balance6,'ether'))

      //no tokenId
      await mustRevert(async ()=> {
        await st.depositERC721(user5, token721.address, zero_tokenId, tokenData, 20, ZERO_ADDRESS, 80, tokenData, 10, secretHash,
          { from: user6, value: 10, nonce: await trNonce(web3, user6) })
      })
      
      //msg.value < fees0
      await mustRevert(async ()=> {
        await st.depositERC721(user5, token721.address, tokenId, tokenData, 20, ZERO_ADDRESS, 80, tokenData, 10, secretHash,
          { from: user6, value: 18, nonce: await trNonce(web3, user6) })
      })

      //msg.value > fees0
      await mustRevert(async ()=> {
        await st.depositERC721(user5, token721.address, tokenId, tokenData, 20, ZERO_ADDRESS, 80, tokenData, 10, secretHash,
          { from: user6, value: 22, nonce: await trNonce(web3, user6) })
      })

      //msg.value == fees1
      await mustRevert(async ()=> {
        await st.depositERC721(user5, token721.address, tokenId, tokenData, 20, ZERO_ADDRESS, 80, tokenData, 10, secretHash,
          { from: user6, value: 10, nonce: await trNonce(web3, user6) })
      })

      //msg.value == 0
      await mustRevert(async ()=> {
        await st.depositERC721(user5, token721.address, tokenId, tokenData, 20, ZERO_ADDRESS, 80, tokenData, 10, secretHash,
          { from: user6, value: 0, nonce: await trNonce(web3, user6) })
      })

      await st.depositERC721(user5, token721.address, tokenId, tokenData, 20, ZERO_ADDRESS, 80, tokenData, 10, secretHash,
        { from: user6, value: 20, nonce: await trNonce(web3, user6) })
  
      const params = {from: user6, token0:token721.address , value0: tokenId, tokenData0:tokenData, fees0:20, token1:ZERO_ADDRESS, 
                      value1:80, tokenData1:tokenData, fees1:10, secretHash:secretHash, secret:Buffer.from(secret)}
  
      await token721.approve(st.address, tokenId, { from: user6 })

      //msg.value > inputs.value1.add(inputs.fees1)
      await mustRevert(async ()=> {
        await st.swapERC721(params,{ from: user5, value: 100, nonce: await trNonce(web3, user5) })
      })

      //msg.value < inputs.value1.add(inputs.fees1)
      await mustRevert(async ()=> {
        await st.swapERC721(params,{ from: user5, value: 70, nonce: await trNonce(web3, user5) })
      })

      //msg.value == inputs.value1
      await mustRevert(async ()=> {
        await st.swapERC721(params,{ from: user5, value: 80, nonce: await trNonce(web3, user5) })
      })

      //msg.value == inputs.fees1
      await mustRevert(async ()=> {
        await st.swapERC721(params,{ from: user5, value: 10, nonce: await trNonce(web3, user5) })
      })

      await st.swapERC721(params,{ from: user5, value: 90, nonce: await trNonce(web3, user5) })
        
      balance5 = await web3.eth.getBalance(user5)
      balance6 = await web3.eth.getBalance(user6)
      console.log(web3.utils.fromWei(balance5,'ether'))
      console.log(web3.utils.fromWei(balance6,'ether'))
    })

      it('should be fail on no tokenIds - 721 to 721', async () => {
        const secret = 'my secret'
        const secretHash = sha3(secret)
        const tokenId7 = NFT7;
        const tokenId8 = NFT8;
        const tokenData = 1;
        const zero_tokenId = 0;
        
        await mustRevert(async ()=> {
          await st.depositERC721(user8, token721.address, zero_tokenId, tokenData, 10, token721.address, tokenId8, tokenData, 10, secretHash,
            { from: user7, value: 10, nonce: await trNonce(web3, user7) })
        })

        await mustRevert(async ()=> {
          await st.depositERC721(user8, token721.address, tokenId7, tokenData, 10, token721.address, zero_tokenId, tokenData, 10, secretHash,
            { from: user7, value: 10, nonce: await trNonce(web3, user7) })
        })
      })

      it('should be able to swap 721 token - 721 to 721', async () => {
        const secret = 'my secret'
        const secretHash = sha3(secret)
        const tokenId7 = NFT7;
        const tokenId8 = NFT8;
        const tokenData = 1;
        
        await st.depositERC721(user8, token721.address, tokenId7, tokenData, 10, token721.address, tokenId8, tokenData, 10, secretHash,
          { from: user7, value: 10, nonce: await trNonce(web3, user7) })
    
        const params = {from: user7, token0:token721.address , value0: tokenId7, tokenData0:tokenData, fees0:10, token1:token721.address, 
                        value1:tokenId8, tokenData1:tokenData, fees1:10, secretHash:secretHash, secret:Buffer.from(secret)}
    
        await token721.approve(st.address, tokenId7, { from: user7 })
        await token721.approve(st.address, tokenId8, { from: user8 })
        await st.swapERC721(params,{ from: user8, value: 10, nonce: await trNonce(web3, user8) })
    
        })

        it('should be able to deposit and retrieve 721 token - Ether to 721', async () => {
          const secret = 'my secret'
          const secretHash = sha3(secret)
          const tokenId = NFT4;
          const tokenData = 1;
          
          await st.depositERC721(user4, ZERO_ADDRESS, 90, tokenData, 10, token721.address, tokenId, tokenData, 10, secretHash,
          { from: user3, value: 100, nonce: await trNonce(web3, user3) })
      
          st.retrieveERC721(user4, ZERO_ADDRESS, 90, tokenData, 10, token721.address, tokenId, tokenData, 10, secretHash, { from: user3 })
        })


        /* it('should fail in swap on no request exists  - Ether to 721', async () => {
          const secret = 'my secret word'
          const secretHash = sha3(secret)
          const tokenId = NFT4;
          const tokenData = 1;
          const zero_tokenId = 0;
          
          await st.depositERC721(user4, ZERO_ADDRESS, 180, tokenData, 10, token721.address, tokenId, tokenData, 10, secretHash,
            { from: user3, value: 190, nonce: await trNonce(web3, user3) })
        
            const params = {from: user3, token0: ZERO_ADDRESS, value0: 180, tokenData0:tokenData, fees0:10, token1:token721.address, 
                            value1:tokenId, tokenData1:tokenData, fees1:10, secretHash:secretHash, secret:Buffer.from(secret)}
        
            await token721.approve(st.address, tokenId, { from: user4 })
            await st.swapERC721(params,{ from: user4, value: 10, nonce: await trNonce(web3, user4) })
        })  */

  })
/*
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
*/
//})
