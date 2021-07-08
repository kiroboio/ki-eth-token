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
contract("Metamask E2E: issue tokens and generate payment", async accounts => {

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
    const { contract, raw, parsed } = response.data.message
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