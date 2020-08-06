const axios = require('axios');
const { assert } = require("console");
const mlog = require('mocha-logger');

const ETH_ACC = '0x6a13b7F1Ec6e94cE5d77563ce12702da8E4E84B8';
const LOCAL_POOL = 'http://127.0.0.1:3030/v1/eth/rinkeby/pool';

const DEV_POOL = 'https://testapi.kirobo.me/v1/eth/rinkeby/pool';

const SERVER = DEV_POOL;

const getPrivateKey = (address) => {
  const wallet = web3.currentProvider.wallets[address.toLowerCase()]
  return `0x${wallet._privKey.toString('hex')}`
}

contract("Local E2E: issue tokens and generate payment", async accounts => {

  const user1 = accounts[3];
  const user2 = accounts[4];
  const user3 = accounts[5];

  const tokenOwner = accounts[1]
  const poolOwner = accounts[2]

  before('setup contract for the test', async () => {

    mlog.log('web3           ', web3.version)
    mlog.log('tokenOwner     ', tokenOwner)
    mlog.log('poolOwner      ', poolOwner)
    mlog.log('user1          ', user1)
    mlog.log('user2          ', user2)
    mlog.log('user3          ', user3)

  });

  it("should be able to issueTokens ", async () => {
    const secret = "my secret";
    const secretHash = web3.utils.sha3(secret);
    const secretHex = "0x" + Buffer.from(secret).toString("hex");
    const tokens = 500;

    let response = await axios.post(SERVER, {
      cmd: 'accountInfo',
      data: {
        address: user1,
      }
    })
    const initialBalance = response.data.balance;
    mlog.log("got initial balance:", initialBalance);

    response = await axios.post(SERVER, {
      cmd: "issueTokens",
      data: {
        recipient: user1,
        value: tokens,
        secretHash,
      },
    });
    const { raw, parsed } = response.data.message;
    mlog.log("got message to sign:", raw);
    mlog.log("got parsed message:", JSON.stringify(parsed));
    const rlp = await web3.eth.accounts.sign(web3.utils.sha3(raw).slice(2), getPrivateKey(user1));
    mlog.log("signed message: ", JSON.stringify(rlp));
    response = await axios.post(SERVER, {
      cmd: 'acceptTokens',
      data: {
        recipient: user1,
        value: tokens,
        secretHex,
        v: rlp.v,
        r: rlp.r,
        s: rlp.s,
      }
    });
    mlog.log("acceptTokens response", JSON.stringify(response.data));
    assert(response.data.status === true, "accept tokens failure");
    response = await axios.post(SERVER, {
      cmd: 'accountInfo',
      data: {
        address: user1,
      }
    })
    mlog.log("accountInfo response", JSON.stringify(response.data));
    assert(parseInt(response.data.balance) == parseInt(initialBalance) + tokens, "wrong balance");

  });

  it("should be able to generate payment ", async () => {
    const secret = "my secret";
    const secretHash = web3.utils.sha3(secret);
    const secretHex = "0x" + Buffer.from(secret).toString("hex");
    const tokens = 120;

    let response = await axios.post(SERVER, {
      cmd: 'accountInfo',
      data: {
        address: user1,
      }
    })
    const initialBalance = response.data.balance;
    mlog.log("got initial balance:", initialBalance);

    response = await axios.post(SERVER, {
      cmd: "generatePayment",
      data: {
        from: user1,
        value: tokens,
      },
    });

    const { raw, parsed } = response.data.message;
    mlog.log("got message to sign:", raw);
    mlog.log("got parsed message:", JSON.stringify(parsed));
    const rlp = await web3.eth.accounts.sign(web3.utils.sha3(raw).slice(2), getPrivateKey(user1));
    mlog.log("signed message: ", JSON.stringify(rlp));

    response = await axios.post(SERVER, {
      cmd: 'validatePayment',
      data: {
        from: user1,
        value: tokens,
        v: rlp.v,
        r: rlp.r,
        s: rlp.s,
      }
    });
    mlog.log("validate payment response:", JSON.stringify(response.data));

    response = await axios.post(SERVER, {
      cmd: 'executePayment',
      data: {
        from: user1,
        value: tokens,
        v: rlp.v,
        r: rlp.r,
        s: rlp.s,
      }
    });

    mlog.log("execute payment response:", JSON.stringify(response.data));


    response = await axios.post(SERVER, {
      cmd: 'accountInfo',
      data: {
        address: user1,
      }
    })
    mlog.log("accountInfo response", JSON.stringify(response.data));
    assert(parseInt(response.data.balance) == parseInt(initialBalance) - tokens, "wrong balance");
  });

});