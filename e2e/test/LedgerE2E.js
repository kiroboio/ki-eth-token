const axios = require('axios');
const { assert } = require("console");
const crypto = require('crypto');
const mlog = require('mocha-logger');
const hidTransport = require("@ledgerhq/hw-transport-node-hid").default;
const App = require("@ledgerhq/hw-app-eth").default;

const LOCAL_POOL = 'http://127.0.0.1:3030/v1/eth/rinkeby/pool';
const DEV_POOL = 'https://testapi.kirobo.me/v1/eth/rinkeby/pool';

const SERVER = DEV_POOL;

const PATH = "44'/60'/0'/0/0";

contract("Ledger E2E: issue tokens and generate payment", async accounts => {

  let ethApp;

  const user1 = accounts[3];
  const user2 = accounts[4];
  const user3 = accounts[5];

  const tokenOwner = accounts[1];
  const poolOwner = accounts[2];

  before('setup contract for the test', async () => {

    mlog.log('web3           ', web3.version)
    mlog.log('tokenOwner     ', tokenOwner)
    mlog.log('poolOwner      ', poolOwner)
    mlog.log('user1          ', user1)
    mlog.log('user2          ', user2)
    mlog.log('user3          ', user3)

  });

  before("setup ledger", async () => {
    const transport = await hidTransport.create();
    ethApp = new App(transport);
  });

  it("should be able to issueTokens ", async () => {
    const secret = "my secret";
    const secretHash = web3.utils.sha3(secret);
    const secretHex = "0x" + Buffer.from(secret).toString("hex");
    const tokens = 500;

    const { address: ldgAddress } = await ethApp.getAddress(PATH);
    mlog.log("ledger address", ldgAddress);

    let response = await axios.post(SERVER, {
      cmd: 'accountInfo',
      data: {
        address: ldgAddress,
      }
    })
    const initialBalance = response.data.balance;
    mlog.log("got initial balance:", initialBalance);

    response = await axios.post(SERVER, {
      cmd: "issueTokens",
      data: {
        recipient: ldgAddress,
        value: tokens,
        secretHash,
      },
    });
    const { raw, parsed } = response.data.message;
    mlog.log("got message to sign:", raw);
    mlog.log("got parsed message:", JSON.stringify(parsed));
    const toSign = Buffer.from(web3.utils.sha3(raw).slice(2)).toString('hex');
    mlog.log('toSign with ledger:', toSign);
    const sha256_buf = crypto.createHash('sha256').update(Buffer.from(web3.utils.sha3(raw).slice(2))).digest('hex');
    mlog.log('ledger display: ', sha256_buf.toUpperCase());
    const signedLedger = await ethApp.signPersonalMessage(
      PATH,
      toSign,
    );

    const rlp = {
      v: '0x' + signedLedger.v.toString(16),
      r: '0x' + signedLedger.r,
      s: '0x' + signedLedger.s,
    }

    mlog.log("signed message: ", JSON.stringify(rlp));
    response = await axios.post(SERVER, {
      cmd: 'acceptTokens',
      data: {
        recipient: ldgAddress,
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
        address: ldgAddress,
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

    const { address: ldgAddress } = await ethApp.getAddress(PATH);
    mlog.log("ledger address", ldgAddress);

    let response = await axios.post(SERVER, {
      cmd: 'accountInfo',
      data: {
        address: ldgAddress,
      }
    })
    const initialBalance = response.data.balance;
    mlog.log("got initial balance:", initialBalance);

    response = await axios.post(SERVER, {
      cmd: "generatePayment",
      data: {
        from: ldgAddress,
        value: tokens,
      },
    });

    const { raw, parsed } = response.data.message;
    mlog.log("got raw message to sign:", raw);
    mlog.log("got parsed message:", JSON.stringify(parsed));
    // const rlp = await web3.eth.accounts.sign(web3.utils.sha3(raw).slice(2), getPrivateKey(user1));

    const toSign = Buffer.from(web3.utils.sha3(raw).slice(2)).toString('hex');
    mlog.log('toSign with ledger:', toSign);
    const sha256_buf = crypto.createHash('sha256').update(Buffer.from(web3.utils.sha3(raw).slice(2))).digest('hex');
    mlog.log('ledger display: ', sha256_buf.toUpperCase());
    const signedLedger = await ethApp.signPersonalMessage(
      PATH,
      toSign,
    );
    mlog.log("ledger signature: ", JSON.stringify(signedLedger));
    const rlp = {
      v: '0x' + signedLedger.v.toString(16),
      r: '0x' + signedLedger.r,
      s: '0x' + signedLedger.s,
    }

    mlog.log("signed message: ", JSON.stringify(rlp));

    response = await axios.post(SERVER, {
      cmd: 'validatePayment',
      data: {
        from: ldgAddress,
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
        from: ldgAddress,
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
        address: ldgAddress,
      }
    })
    mlog.log("accountInfo response", JSON.stringify(response.data));
    assert(parseInt(response.data.balance) == parseInt(initialBalance) - tokens, "wrong balance");
  });

});