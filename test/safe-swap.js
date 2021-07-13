'use strict'

var bigInt = require("big-integer");

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
const { json } = require('express')

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
    mlog.log('safe swap contract      ', st.address)
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

    mlog.log('token721                 ',   token721.address);

  })

  it('should create an empty contract', async () => {
    assert.equal('0', ''+(await web3.eth.getBalance(st.address)))
  })


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

  const checkAmount = function(InitAmount, gasPrice, gasUsed, amountAdded, fee, finalAmount )
  {
    let totalgasSpent = bigInt(gasPrice).multiply((bigInt(gasUsed)));
    let endAmount = bigInt(InitAmount).minus(bigInt(totalgasSpent)).add(bigInt(amountAdded)).minus(bigInt(fee));
    console.log('calculated ', bigInt(endAmount).toString())
    console.log('finalAmount', bigInt(finalAmount).toString())
    return bigInt(endAmount).eq(bigInt(finalAmount));
  }

  /*
  it('should be able to collect a transfer request from token to ether', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    const value150 = 1500000000000000 //web3.utils.toBN(web3.utils.toWei('150', 'ether'))
    const gasPrice = await web3.eth.getGasPrice()

    let senderInitBalance = await web3.eth.getBalance(user3)
    let recipientBalance = await web3.eth.getBalance(user4)
    console.log('senderInitBalance before the swap = ', web3.utils.fromWei(senderInitBalance ,'ether'))
    console.log('recipientBalance before the swap = ', web3.utils.fromWei(recipientBalance ,'ether'))

    //console.log('senderInitBalance before the swap = ', web3.utils.fromWei(await token.balanceOf(user3, { from: user3 }) ,'ether'))
    //console.log('recipientBalance before the swap = ', web3.utils.fromWei(await token.balanceOf(user4, { from: user4 }),'ether'))


    await token.approve(st.address, 1e12, { from: user3 })

    const res = await st.deposit(user4, token.address, 50, 10, ZERO_ADDRESS, value150, 10, secretHash,
      { from: user3, value: 10, nonce: await trNonce(web3, user3) })

    await st.swap(user3, token.address, 50, 10, ZERO_ADDRESS, value150, 10, secretHash, Buffer.from(secret),
      { from: user4, value: value150+10, nonce: await trNonce(web3, user4) })

    console.log('gas used in wei ', res.receipt.gasUsed * gasPrice)

    let senderFinalBalance = await web3.eth.getBalance(user3)
    recipientBalance = await web3.eth.getBalance(user4)
    console.log('senderFinalBalance after the swap = ', web3.utils.fromWei(senderFinalBalance ,'ether'))
    console.log('recipientBalance after the swap = ', web3.utils.fromWei(recipientBalance ,'ether'))
    //console.log('senderBalance after the swap = ', web3.utils.fromWei(await token.balanceOf(user3, { from: user3 }) ,'ether'))
    //console.log(`recipientBalance after the swap = ${web3.utils.fromWei(await token.balanceOf(user4, { from: user4 }) ,'ether')}`)
    if(checkAmount(senderInitBalance, gasPrice, res.receipt.gasUsed, value150, 10, senderFinalBalance))
    {
      console.log("ether amount correct")
    }else{
      console.log("ether amount not correct")
    }
  })*/

  it('should be able to collect a transfer request from token to ether', async () => {
    const secret = 'my secret'
    const secretHash = sha3(secret)
    await token.approve(st.address, 1e12, { from: user3 })
    
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
    it('should be able to swap 721 token - Ether to 721', async () => {
      const secret = 'my secret'
      const secretHash = sha3(secret)
      const tokenId = NFT4;
      const tokenData = 1;
      const value150 = 1500000000000000 //web3.utils.toBN(web3.utils.toWei('150', 'ether'))
      const gasPrice = await web3.eth.getGasPrice()
  
      let senderInitBalance = await web3.eth.getBalance(user3)
      let recipientInitBalance = await web3.eth.getBalance(user4)
      console.log('senderInitBalance before the swap = ', web3.utils.fromWei(senderInitBalance ,'ether'))
      console.log('recipientInitBalance before the swap = ', web3.utils.fromWei(recipientInitBalance ,'ether'))
  
      await st.depositERC721(user4, ZERO_ADDRESS, value150, tokenData, 10, token721.address, tokenId, tokenData, 10, secretHash,
          { from: user3, value: value150+10, nonce: await trNonce(web3, user3) })
  
      const params = {from: user3, token0: ZERO_ADDRESS, value0: value150, tokenData0:tokenData, fees0:10, token1:token721.address, 
                      value1:tokenId, tokenData1:tokenData, fees1:10, secretHash:secretHash, secret:Buffer.from(secret)}
      
      const res1 = await token721.approve(st.address, tokenId, { from: user4 })
  
      const res = await st.swapERC721(params,{ from: user4, value: 10, nonce: await trNonce(web3, user4) })
  
      let senderFinalBalance = await web3.eth.getBalance(user3)
      let recipientFinalBalance = await web3.eth.getBalance(user4)
      console.log('senderFinalBalance after the swap = ', web3.utils.fromWei(senderFinalBalance ,'ether'))
      console.log('recipientFinalBalance after the swap = ', web3.utils.fromWei(recipientFinalBalance ,'ether'))
      if(checkAmount(recipientInitBalance, gasPrice, res.receipt.gasUsed+res1.receipt.gasUsed, value150, 10, recipientFinalBalance))
      {
        console.log("ether amount correct")
      }else{
        console.log("ether amount not correct")
      } 
      })
      */


  it('should be able to swap 721 token - Ether to 721', async () => {
    const secret = 'my secret'
    const secret2 = 'my secret word'
    const secretHash = sha3(secret)
    const tokenId = NFT4;
    const tokenData = 1;
    const zero_tokenId = 0;

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

    const params = {token0: ZERO_ADDRESS, value0: 150, tokenData0:tokenData, fees0:10, token1:token721.address, 
                    value1:tokenId, tokenData1:tokenData, fees1:10, secretHash:secretHash}

    const params1 = {token0: ZERO_ADDRESS, value0: 160, tokenData0:tokenData, fees0:10, token1:token721.address, 
      value1:tokenId, tokenData1:tokenData, fees1:10, secretHash:secretHash}

    const params2 = {token0: ZERO_ADDRESS, value0: 150, tokenData0:tokenData, fees0:10, token1:token721.address, 
        value1:tokenId, tokenData1:tokenData, fees1:10, secretHash:sha3(secret)}

    await token721.approve(st.address, tokenId, { from: user4 })

    //request not exists
    await mustRevert(async ()=> {
      await st.swapERC721(user3, params1, Buffer.from(secret), { from: user4, value: 10, nonce: await trNonce(web3, user4) })
    })

    //wrong secret
    await mustRevert(async ()=> {
      await st.swapERC721(user3, params2, Buffer.from(secret2), { from: user4, value: 10, nonce: await trNonce(web3, user4) })
    })

    await st.swapERC721(user3, params, Buffer.from(secret), { from: user4, value: 10, nonce: await trNonce(web3, user4) })

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
  
      const params = {token0:token721.address , value0: tokenId, tokenData0:tokenData, fees0:20, token1:ZERO_ADDRESS, 
                      value1:80, tokenData1:tokenData, fees1:10, secretHash:secretHash}
  
      await token721.approve(st.address, tokenId, { from: user6 })

      //msg.value > inputs.value1.add(inputs.fees1)
      await mustRevert(async ()=> {
        await st.swapERC721(user6, params,Buffer.from(secret), { from: user5, value: 100, nonce: await trNonce(web3, user5) })
      })

      //msg.value < inputs.value1.add(inputs.fees1)
      await mustRevert(async ()=> {
        await st.swapERC721(user6, params, Buffer.from(secret), { from: user5, value: 70, nonce: await trNonce(web3, user5) })
      })

      //msg.value == inputs.value1
      await mustRevert(async ()=> {
        await st.swapERC721(user6, params,Buffer.from(secret), { from: user5, value: 80, nonce: await trNonce(web3, user5) })
      })

      //msg.value == inputs.fees1
      await mustRevert(async ()=> {
        await st.swapERC721(user6, params, Buffer.from(secret), { from: user5, value: 10, nonce: await trNonce(web3, user5) })
      })

      await st.swapERC721(user6, params, Buffer.from(secret), { from: user5, value: 90, nonce: await trNonce(web3, user5) })
        
    })

      it('should be fail on no tokenIds - 721 to 721', async () => {
        const secret = 'my secret'
        const secretHash = sha3(secret)
        const tokenId7 = NFT7;
        const tokenId8 = NFT8;
        const tokenData = 1;
        const zero_tokenId = 0;
        
        //sender tokenId is 0 
        await mustRevert(async ()=> {
          await st.depositERC721(user8, token721.address, zero_tokenId, tokenData, 20, token721.address, tokenId8, tokenData, 10, secretHash,
            { from: user7, value: 20, nonce: await trNonce(web3, user7) })
        })

        //reciever tokenId is 0 
        await mustRevert(async ()=> {
          await st.depositERC721(user8, token721.address, tokenId7, tokenData, 20, token721.address, zero_tokenId, tokenData, 10, secretHash,
            { from: user7, value: 20, nonce: await trNonce(web3, user7) })
        })

        //msg.value != fees0
        await mustRevert(async ()=> {
          await st.depositERC721(user8, token721.address, tokenId7, tokenData, 20, token721.address, zero_tokenId, tokenData, 10, secretHash,
            { from: user7, value: 10, nonce: await trNonce(web3, user7) })
        })

        await st.depositERC721(user8, token721.address, tokenId7, tokenData, 20, token721.address, tokenId8, tokenData, 10, secretHash,
          { from: user7, value: 20, nonce: await trNonce(web3, user7) })


        const params = {token0:token721.address , value0: tokenId7, tokenData0:tokenData, fees0:20, token1:token721.address, 
                        value1:tokenId8, tokenData1:tokenData, fees1:10, secretHash:secretHash}
    
        await token721.approve(st.address, tokenId7, { from: user7 })
        await token721.approve(st.address, tokenId8, { from: user8 })

        //msg.value > value1  
        await mustRevert(async ()=> {
          await st.swapERC721(user7, params, Buffer.from(secret), { from: user8, value: 12, nonce: await trNonce(web3, user8) })
        })

        //msg.value < value1
        await mustRevert(async ()=> {
          await st.swapERC721(user7, params, Buffer.from(secret), { from: user8, value: 8, nonce: await trNonce(web3, user8) })
        })

        //msg.value == 0
        await mustRevert(async ()=> {
          await st.swapERC721(user7, params, Buffer.from(secret), { from: user8, value: 12, nonce: await trNonce(web3, user8) })
        })

        //msg.value == value0
        await mustRevert(async ()=> {
          await st.swapERC721(user7, params, Buffer.from(secret), { from: user8, value: 20, nonce: await trNonce(web3, user8) })
        })

        await st.swapERC721(user7, params, Buffer.from(secret), { from: user8, value: 10, nonce: await trNonce(web3, user8) })

      })

      it('should be able to deposit and retrieve 721 token - Ether to 721', async () => {
        const secret = 'my secret'
        const secretHash = sha3(secret)
        const tokenId = NFT4;
        const tokenData = 1;
        
        await st.depositERC721(user4, ZERO_ADDRESS, 90, tokenData, 10, token721.address, tokenId, tokenData, 10, secretHash,
        { from: user3, value: 100, nonce: await trNonce(web3, user3) })

        //request not exists
        /* await mustRevert(async ()=> {
          st.retrieveERC721(user4, ZERO_ADDRESS, 80, tokenData, 10, token721.address, tokenId, tokenData, 10, secretHash, { from: user3 })
        }) */
        const params = {token0:ZERO_ADDRESS , value0: 90, tokenData0:tokenData, fees0:10, token1:token721.address, 
          value1:tokenId, tokenData1:tokenData, fees1:10, secretHash:secretHash, secret:Buffer.from(secret)}


        await st.retrieveERC721(user4, params, { from: user3 })
      })

      it('should be able to make a hidden deposit request', async () => {
        const secret = 'my secret'
        const secretHash = sha3(secret)
        const id1 = sha3('1234')
        await st.hiddenDeposit(id1, { from: user2, value: 100 })
      })

      it('should be able to retrieve a hidden deposits request', async () => {
        const secret = 'my secret'
        const secretHash = sha3(secret)
        const id1 = sha3('1234')
        await st.hiddenRetrieve(id1, 100, { from: user2 })
      })


      //hidden tests
      //------------------------

       it('should be able to swap a hidden deposit request - ether to 20', async () => {
        const secret = 'my secret'
        const secret2 = 'wrong secrete'
        const secretHash = sha3(secret)
        const id1 = sha3(defaultAbiCoder.encode(
          ['bytes32', 'address', 'address','address', 'uint256', 'uint256','address', 'uint256', 'uint256','bytes32'],
          [await st.HIDDEN_SWAP_TYPEHASH(), user2, user3, ZERO_ADDRESS, '600', '100',token.address, '500', '120', secretHash]
        ))
    
        mlog.log('id1', id1)
        await st.hiddenDeposit(id1, { from: user2, value: 700 , nonce: await trNonce(web3, user2)})
        await token.approve(st.address, 1e12, { from: user3 })

        const params = {token0:ZERO_ADDRESS, value0:600, fees0:100, token1:token.address, value1:500, fees1: 120, secretHash:secretHash}
        //wrong secret
        await mustRevert(async ()=> {
          await st.hiddenSwap(user2, params, Buffer.from(secret2), { from: user3, value: 120, nonce: await trNonce(web3, user3) })
        })
        //wrong fees
         await mustRevert(async ()=> {
          await st.hiddenSwap(user2, params, Buffer.from(secret), { from: user3, value: 100, nonce: await trNonce(web3, user3) })
        })
        //no fees
        await mustRevert(async ()=> {
          await st.hiddenSwap(user2, params, Buffer.from(secret), { from: user3 , nonce: await trNonce(web3, user3)})
        })
        
        await st.hiddenSwap(user2, params, Buffer.from(secret), { from: user3,value:120, nonce: await trNonce(web3, user3)})
      })
 
      it('should be able to swap a hidden deposit request - 20 to ether', async () => {
        const secret = 'my secret'
        const secret2 = 'wrong secrete'
        const secretHash = sha3(secret)
        const id1 = sha3(defaultAbiCoder.encode(
          ['bytes32', 'address', 'address','address', 'uint256', 'uint256','address', 'uint256', 'uint256','bytes32'],
          [await st.HIDDEN_SWAP_TYPEHASH(), user2, user1, token.address, '50', '10',ZERO_ADDRESS, '55', '17', secretHash]
        ))

        await token.approve(st.address, 1e12, { from: user2 })
        await st.hiddenDeposit(id1, { from: user2, value: 10 , nonce: await trNonce(web3, user2)})
        

        const params = {token0:token.address, value0:50, fees0:10, token1:ZERO_ADDRESS, value1:55, fees1: 17, secretHash:secretHash}
        await st.hiddenSwap(user2, params, Buffer.from(secret), { from: user1, value:72, nonce: await trNonce(web3, user1)})

      })
      

      it('should be able to swap 721 token from a hidden deposit request - ether to 721', async () => {
        const secret = 'my secret'
        const secretHash = sha3(secret)
        const tokenId = NFT4;
        const tokenData = 1;
        const id1 = sha3(defaultAbiCoder.encode(
          ['bytes32', 'address', 'address','address', 'uint256','bytes', 'uint256','address', 'uint256','bytes', 'uint256','bytes32'],
          [await st.HIDDEN_ERC721_SWAP_TYPEHASH(), user2, user4, ZERO_ADDRESS, '6000',tokenData, '1000',token721.address, tokenId,tokenData, '1200', secretHash]
        ))
    
        mlog.log('id1', id1)
    
        await st.hiddenDeposit(id1, { from: user2, value: 7000 })
        await token.approve(st.address, 1e12, { from: user4 })

        const params = {token0:ZERO_ADDRESS, value0:6000, tokenData0:tokenData, fees0:1000, token1:token721.address, 
                        value1:tokenId, tokenData1:tokenData, fees1: 1200, secretHash:secretHash}
        await st.hiddenSwapERC721(user2, params, Buffer.from(secret), { from: user4, value: 1200 })
      })

      it('should be able to swap 721 token from a hidden deposit request - 721 to ether', async () => {
        const secret = 'my secret'
        const secretHash = sha3(secret)
        const tokenId = NFT4;
        const tokenData = 1;
        const id1 = sha3(defaultAbiCoder.encode(
          ['bytes32', 'address', 'address','address', 'uint256','bytes', 'uint256','address', 'uint256','bytes', 'uint256','bytes32'],
          [await st.HIDDEN_ERC721_SWAP_TYPEHASH(), user4, user1, token721.address, tokenId,tokenData, '1000',ZERO_ADDRESS ,'6000',tokenData, '1200', secretHash]
        ))
    
        mlog.log('id1', id1)
        await token721.approve(st.address, 1e12, { from: user4 })
        await st.hiddenDeposit(id1, { from: user4, value: 1000 })

        const params = {token0:token721.address, value0:tokenId, tokenData0:tokenData, fees0:1000, token1:ZERO_ADDRESS, 
                        value1:6000, tokenData1:tokenData, fees1: 1200, secretHash:secretHash}
        await st.hiddenSwapERC721(user4, params, Buffer.from(secret), { from: user1, value: 1200 , nonce: await trNonce(web3, user4)})
      })

  })