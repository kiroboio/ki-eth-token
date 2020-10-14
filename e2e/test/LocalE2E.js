const axios = require('axios')
const { ethers } = require('ethers')
const { TypedDataUtils } = require('ethers-eip712')
const { assert } = require("console")
const mlog = require('mocha-logger')

const ETH_ACC = '0x6a13b7F1Ec6e94cE5d77563ce12702da8E4E84B8'
const LOCAL_SERVER = 'http://127.0.0.1:3030/v1'

const DEV_SERVER = 'https://testapi.kirobo.me/v1'

// const SERVER = DEV_SERVER
const SERVER = LOCAL_SERVER

const EP = {
  BALANCE:  `${SERVER}/eth/rinkeby/balance`,
  POOL:  `${SERVER}/eth/rinkeby/pool`,
  KIRO:  `${SERVER}/eth/rinkeby/kiros`,
  BUY: `${SERVER}/eth/rinkeby/kiro/buy`,
  PRICE: `${SERVER}/eth/rinkeby/kiro/price`, 
}

const getPrivateKey = (address) => {
  const wallet = web3.currentProvider.wallets[address.toLowerCase()]
  return `0x${wallet._privKey.toString('hex')}`
}

const logCall = (name, response) => {
  mlog.log(`${name} request`, JSON.stringify({ url: response.config.url, data: JSON.parse(response.config.data || '{}')}))
  mlog.log(`${name} response`, JSON.stringify(response.data))
}

const logError = (name, err, populate = true) => {
  mlog.log(`${name} request`, JSON.stringify({ url: err.response.config.url, data: JSON.parse(err.response.config.data || '{}')}))
  mlog.error(`${name} response`, JSON.stringify(err.response.data, null, 2))
  if (populate) throw new Error(err.response)
}
contract("Local E2E: issue tokens and generate payment", async accounts => {

  const user1 = accounts[3]
  const user2 = accounts[4]
  const user3 = accounts[5]

  const tokenOwner = accounts[1]
  const poolOwner = accounts[2]

  const USER = user3
  const PAYMENT = 120

  before('setup contract for the test', async () => {

    mlog.log('web3           ', web3.version)
    mlog.log('tokenOwner     ', tokenOwner)
    mlog.log('poolOwner      ', poolOwner)
    mlog.log('user1          ', user1)
    mlog.log('user2          ', user2)
    mlog.log('user3          ', user3)

  })

  it("should be able to buy tokens ", async () => {
    const secret = "my secret is very secret"
    const secretHash = web3.utils.sha3(secret)
    const secretHex = "0x" + Buffer.from(secret).toString("hex")
    const tokens = 500

    let response = await axios.get(`${EP.KIRO}/${USER}`)
    const initialBalance = response.data.poolBalance
    mlog.log("got initial balance:", initialBalance)

    response = await axios.post(EP.PRICE, {
        recipient: USER,
    })
    logCall('price', response)

    const { min, address } = response.data.eth
    mlog.log('token price in wei', min)
    mlog.log('payment address', address)
    response = await axios.get(`${EP.BALANCE}/${USER}`)
    mlog.log('eth balance', JSON.stringify(response.data))

    let nonce = response.data.transactionCount
    const { raw } = await web3.eth.signTransaction({
      from: USER, to: address, value: min*2, nonce } // TODO: [server] keep min value per address request (EP.PRICE)
    )

    try{
      response = await axios.post(EP.BUY, {
        eth: { raw },
      })
      logCall('buyTokens', response)
    } catch (e) {
      logError('buyTokens', e)
    }

    response = await axios.get(`${EP.KIRO}/${USER}`)
    const balance = response.data.poolBalance
    mlog.log("got balance:", balance)

    response = await axios.get(`${EP.BALANCE}/${USER}`)
    mlog.log('eth balance', JSON.stringify(response.data))

  })

  it("should be able to issueTokens ", async () => {
    const secret = "my secret is very secret"
    const secretHash = web3.utils.sha3(secret)
    const secretHex = "0x" + Buffer.from(secret).toString("hex")
    const tokens = 500

    let response = await axios.get(`${EP.KIRO}/${USER}`)
    logCall('accountInfo', response)
    const initialBalance = response.data.poolBalance
    mlog.log("got initial balance:", initialBalance)

    response = await axios.post(EP.POOL, {
      cmd: "issueTokens",
      data: {
        recipient: USER,
        value: tokens,
        secretHash,
      },
    })
    logCall('issueTokens', response)
    const { raw, parsed } = response.data.message
    const domain = response.data.contract.domain
    mlog.log("got message to sign:", raw)
    mlog.log("got parsed message:", JSON.stringify(parsed))
    const rlp = await web3.eth.accounts.sign(domain.slice(2) + web3.utils.sha3(raw).slice(2), getPrivateKey(USER))
    mlog.log("signed message: ", JSON.stringify(rlp))
    response = await axios.post(EP.POOL, {
      cmd: 'acceptTokens',
      data: {
        recipient: USER,
        value: tokens,
        secretHex,
        v: rlp.v,
        r: rlp.r,
        s: rlp.s,
        eip712: false,
      }
    })
    logCall('acceptTokens', response)
    // mlog.log("acceptTokens response", JSON.stringify(response.data))
    assert(response.data.status === true, "accept tokens failure")
    response = await axios.get(`${EP.KIRO}/${USER}`)
    mlog.log("accountInfo response", JSON.stringify(response.data))
    assert(parseInt(response.data.poolBalance) == parseInt(initialBalance) + tokens, "wrong balance")

  })
  
  it.skip("should be able to distributeTokens ", async () => {
    const tokens = 500

    let response = await axios.get(`${EP.KIRO}/${USER}`)
    const initialBalance = response.data.poolBalance
    mlog.log("got initial balance:", initialBalance)

    response = await axios.post(EP.POOL, {
      cmd: "distributeTokens",
      data: {
        recipient: USER,
        value: tokens,
      },
    })
    mlog.log("distributeTokens returned:", JSON.stringify(response.data))
    assert(response.data.blockHash.length > 0)
    response = await axios.get(`${EP.KIRO}/${USER}`)
    logCall('accountInfo', response)
    assert(parseInt(response.data.poolBalance) == parseInt(initialBalance) + tokens, "wrong balance")
  })

  it("should be able to generate payment ", async () => {
    const secret = "my secret"
    const secretHash = web3.utils.sha3(secret)
    const secretHex = "0x" + Buffer.from(secret).toString("hex")

    let response = await axios.get(`${EP.KIRO}/${USER}`)
    logCall('accountInfo', response)
    const initialBalance = response.data.poolBalance
    mlog.log("got initial balance:", initialBalance)

    // const response2 = await axios.post(EP.POOL, {
    //   cmd: "generatePayment",
    //   data: {
    //     from: USER,
    //     value: PAYMENT,
    //   },
    // })
    // logCall('generatePayment', response2)

    let amount = web3.utils.toBN(PAYMENT) 

    if (response.data.debt !== '0' && response.data.nonce === response.data.debt.message.parsed.nonce) { 
      amount.add(web3.utils.toBN('0x' + response.data.debt.message.value))
    }
    
    const { domain, paymentTypeHash } = response.data.contract
    
    const synthesizedRaw = 
      paymentTypeHash +
      response.data.address.slice(2).padStart(64, '0') +
      amount.toString(16).padStart(64, '0') +
      response.data.nonce.slice(2) 

    const raw = ethers.utils.defaultAbiCoder.encode(
      ['bytes32', 'address', 'uint256', 'uint256'],
      [paymentTypeHash, response.data.address, '0x' + amount.toString(16), response.data.nonce]
    )

    mlog.log("raw message to sign:", raw)
    mlog.log("synthesized raw message to sign:", synthesizedRaw)
    // mlog.log("got parsed message:", JSON.stringify(parsed))
    const rlp = await web3.eth.accounts.sign(domain.slice(2) + web3.utils.sha3(raw).slice(2), getPrivateKey(USER))
    mlog.log("signed message: ", JSON.stringify(rlp))

    response = await axios.post(EP.POOL, {
      cmd: 'validatePayment',
      data: {
        from: USER,
        value: PAYMENT,
        v: rlp.v,
        r: rlp.r,
        s: rlp.s,
        eip712: false,
      }
    })
    logCall('validatePayment', response)
    // mlog.log("validate payment response:", JSON.stringify(response.data))

    // response = await axios.post(EP.POOL, {
    //   cmd: 'finalizePayment',
    //   data: {
    //     from: USER,
    //   }
    // })
    // logCall('finalizePayment', response)

    // mlog.log("execute payment response:", JSON.stringify(response.data))


    response = await axios.get(`${EP.KIRO}/${USER}`)
    logCall('accountInfo', response)
    //mlog.log("accountInfo response", JSON.stringify(response.data))
    assert(parseInt(response.data.poolBalance) == parseInt(initialBalance) - PAYMENT, "wrong balance")
  })

  it("should be able to get previous payment", async () => {
    response = await axios.post(EP.POOL, {
      cmd: "lastPaymentInfo",
      data: {
        address: USER,
      },
    })
    logCall('lastPaymentInfo', response)
    // mlog.log('Previous Payment Info:', JSON.stringify(response.data))
    assert(parseInt(response.data.message.parsed.value, 16) === PAYMENT)
  })

  
  it("EIP712: should be able to issue and accept tokens ", async () => {
    const tokens = 500
    const secret = 'my secret2'
    const secretHash = web3.utils.sha3(secret)
    // await pool.issueTokens(user1, tokens, secretHash, { from: poolOwner })
    let response = await axios.post(EP.POOL, {
      cmd: "issueTokens",
      data: {
        recipient: USER,
        value: tokens,
        secretHash,
      },
    })
    logCall('issueTokens', response)
    const { raw, parsed } = response.data.message
    const contract = response.data.contract
    // const message = await pool.generateAcceptTokensMessage(USER, tokens, secretHash, { from: poolOwner })
    // mlog.log('message: ', message)
    const typedData = {
      types: {
        EIP712Domain: [
          { name: "name",               type: "string" },
          { name: "version",            type: "string" },
          { name: "chainId",            type: "uint256" },
          { name: "verifyingContract",  type: "address" },
          { name: "salt",               type: "bytes32" }
        ],
        acceptTokens: [
          { name: 'recipient',          type: 'address' },
          { name: 'value',              type: 'uint256' },
          { name: 'secretHash',         type: 'bytes32' },
        ]
      },
      primaryType: 'acceptTokens',
      domain: {
        name: contract.name, // await pool.NAME(),
        version: contract.version, // await pool.VERSION(),
        chainId: contract.chainId, // + web3.utils.toBN(await pool.CHAIN_ID()).toString('hex'), // await web3.eth.getChainId(),
        verifyingContract: contract.address, // pool.address,
        salt: contract.uid,
      },
      message: {
        recipient: USER,
        value: '0x' + web3.utils.toBN(tokens).toString('hex'),
        secretHash,
      }
    }
    mlog.log('typedData: ', JSON.stringify(typedData, null, 2))
    const domainHash = TypedDataUtils.hashStruct(typedData, 'EIP712Domain', typedData.domain)
    const domainHashHex = ethers.utils.hexlify(domainHash)
    mlog.log('DOMAIN_SEPARATOR', contract.domain)
    mlog.log('DOMAIN_SEPARATOR (calculated)', domainHashHex)
    
    const { defaultAbiCoder, keccak256, toUtf8Bytes } = ethers.utils

    mlog.log('DOMAIN_SEPARATOR (calculated2)', keccak256(defaultAbiCoder.encode(
        ['bytes32', 'bytes32', 'bytes32', 'uint256', 'address', 'bytes32'],
        [
          keccak256(
            toUtf8Bytes('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)')
          ),
          keccak256(toUtf8Bytes('Kirobo Pool')),
          keccak256(toUtf8Bytes('1')),
          '0x4',
          '0x4bfb5d173f2990fe43b3b3743983572d31e2234c',
          '0x01005aacf7a7117257d300004bfb5d173f2990fe43b3b3743983572d31e2234c',
        ]
    )))

    const messageDigest = TypedDataUtils.encodeDigest(typedData)
    const messageDigestHex = ethers.utils.hexlify(messageDigest)
    let signingKey = new ethers.utils.SigningKey(getPrivateKey(USER));
    const sig = signingKey.signDigest(messageDigest)
    const rlp = ethers.utils.splitSignature(sig)
    rlp.v = '0x' + rlp.v.toString(16)
    // const messageDigestHash = messageDigestHex.slice(2)
    // mlog.log('messageDigestHash', messageDigestHash)
    mlog.log('user', USER, 'tokens', tokens, 'secretHash', secretHash)
    const messageHash = TypedDataUtils.hashStruct(typedData, typedData.primaryType, typedData.message)
    const messageHashHex = ethers.utils.hexlify(messageHash)
    mlog.log('messageHash (calculated)', messageHashHex)
    
    const message2Hash = keccak256(raw)
    mlog.log('messageHash (calculated 2)', message2Hash)
    
    mlog.log('rlp', JSON.stringify(rlp))
    mlog.log('recover', ethers.utils.recoverAddress(messageDigest, sig))

    const secretHex = "0x" + Buffer.from(secret).toString("hex")

    try {
      response = await axios.post(EP.POOL, {
        cmd: "acceptTokens",
        data: {
          recipient: USER,
          value: tokens,
          secretHex,
          v: rlp.v,
          r: rlp.r,
          s: rlp.s,
          eip712: true,
        }
      })
    } catch (e) {
      logError('issueTokens', e)
    }
    logCall('issueTokens', response)

  })

})