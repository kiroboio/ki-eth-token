const axios = require("axios");
const { assert } = require("console");
const mlog = require("mocha-logger");
const express = require("express");
const open = require("open");
const path = require("path");

const {
  advanceBlock,
  advanceTime,
  advanceTimeAndBlock,
  pollCondition,
} = require("../../test/lib/utils");

const LOCAL_POOL = "http://127.0.0.1:3030/v1/eth/rinkeby/pool";
const DEV_POOL = "https://testapi.kirobo.me/v1/eth/rinkeby/pool";
const SERVER = DEV_POOL;

const PATH = "44'/60'/0'/0/0";


contract("Ledger E2E: issue tokens and generate payment", async (accounts) => {

  let trzAddress, trzMessage, trzSignedMessage;

  const user1 = accounts[3];
  const user2 = accounts[4];
  const user3 = accounts[5];

  const tokenOwner = accounts[1];
  const poolOwner = accounts[2];

  before("setup contract for the test", async () => {
    mlog.log("web3           ", web3.version);
    mlog.log("tokenOwner     ", tokenOwner);
    mlog.log("poolOwner      ", poolOwner);
    mlog.log("user1          ", user1);
    mlog.log("user2          ", user2);
    mlog.log("user3          ", user3);
  });

  before("setup trezor", async () => {
    const app = express();
    const port = 3000;

    app.use(express.json());
    app.use(express.urlencoded({ extended: true }));
    app.use(express.static(path.join(__dirname, 'public')))

    app.listen(port, () => {
      mlog.log(`Trezor test server listening at http://localhost:${port}`)
    });

    app.post('/address', (req, res) => {
      mlog.log('received address', req.query.address);
      trzAddress = req.query.address;
    });

    app.get('/message', (req, res) => {
      mlog.log(`returning message to sign`, trzMessage);
      res.json({ message: trzMessage });
    });

    app.post('/signed', (req, res) => {
      mlog.log('received signed Trezor message, signature', req.query.sig)
      trzSignedMessage = req.query.sig;
    })

    await open('http://localhost:3000/index.html', { app: ['google chrome'] });
    mlog.log('Press "Generate Address" button in the browser');
    await pollCondition(() => (trzAddress !== undefined), 200);
  });

  it("should be able to issueTokens ", async () => {
    const secret = "my secret";
    const secretHash = web3.utils.sha3(secret);
    const secretHex = "0x" + Buffer.from(secret).toString("hex");
    const tokens = 500;

    assert(trzAddress, 'trzAddress must be sent from the browser');
    mlog.log("trzAddress", trzAddress);

    let response = await axios.post(SERVER, {
      cmd: "accountInfo",
      data: {
        address: trzAddress,
      },
    });
    const initialBalance = response.data.balance;
    mlog.log("got initial balance:", initialBalance);

    response = await axios.post(SERVER, {
      cmd: "issueTokens",
      data: {
        recipient: trzAddress,
        value: tokens,
        secretHash,
      },
    });
    const { raw, parsed } = response.data.message;
    mlog.log("got message to sign:", raw);
    mlog.log("got parsed message:", JSON.stringify(parsed));
    // const rlp = await web3.eth.accounts.sign(web3.utils.sha3(raw).slice(2), getPrivateKey(user1));
    const toSign = Buffer.from(web3.utils.sha3(raw).slice(2)).toString("hex");
    mlog.log("toSign with Trezor:", toSign);
    trzMessage = toSign;

    mlog.log('Click "Sign Accept Tokens" in the browser...');
    await pollCondition(() => (trzSignedMessage !== undefined), 200);
    mlog.log('signed Trezor manual', JSON.stringify(trzSignedMessage));

    const rlp = {
      r: "0x" + trzSignedMessage.substring(0, 64),
      s: "0x" + trzSignedMessage.substring(64, 128),
      v: "0x" + trzSignedMessage.substring(128, 130),
    };

    mlog.log("signed message: ", JSON.stringify(rlp));
    response = await axios.post(SERVER, {
      cmd: "acceptTokens",
      data: {
        recipient: trzAddress,
        value: tokens,
        secretHex,
        v: rlp.v,
        r: rlp.r,
        s: rlp.s,
      },
    });
    mlog.log("acceptTokens response", JSON.stringify(response.data));
    assert(response.data.status === true, "accept tokens failure");
    response = await axios.post(SERVER, {
      cmd: "accountInfo",
      data: {
        address: trzAddress,
      },
    });
    mlog.log("accountInfo response", JSON.stringify(response.data));
    assert(
      parseInt(response.data.balance) == parseInt(initialBalance) + tokens,
      "wrong balance"
    );
  });

  it("should be able to generate payment ", async () => {
    assert(trzAddress, 'trzAddress must be sent from the browser');
    mlog.log("trezor address", trzAddress);
    const secret = "my secret";
    const secretHash = web3.utils.sha3(secret);
    const secretHex = "0x" + Buffer.from(secret).toString("hex");
    const tokens = 120;


    let response = await axios.post(SERVER, {
      cmd: "accountInfo",
      data: {
        address: trzAddress,
      },
    });
    const initialBalance = response.data.balance;
    mlog.log("got initial balance:", initialBalance);

    response = await axios.post(SERVER, {
      cmd: "generatePayment",
      data: {
        from: trzAddress,
        value: tokens,
      },
    });

    const { raw, parsed } = response.data.message;
    mlog.log("got raw message to sign:", raw);
    mlog.log("got parsed message:", JSON.stringify(parsed));
    // const rlp = await web3.eth.accounts.sign(web3.utils.sha3(raw).slice(2), getPrivateKey(user1));

    const toSign = Buffer.from(web3.utils.sha3(raw).slice(2)).toString("hex");
    trzMessage = toSign;
    mlog.log("toSign with Trezor:", toSign);

    mlog.log("Click on Sign Payment in the browser...");
    trzSignedMessage = undefined;
    await pollCondition(() => (trzSignedMessage !== undefined), 200);
    mlog.log('signed Trezor manual', JSON.stringify(trzSignedMessage));

    const rlp = {
      r: "0x" + trzSignedMessage.substring(0, 64),
      s: "0x" + trzSignedMessage.substring(64, 128),
      v: "0x" + trzSignedMessage.substring(128, 130),
    };

    mlog.log("signed message: ", JSON.stringify(rlp));

    response = await axios.post(SERVER, {
      cmd: "validatePayment",
      data: {
        from: trzAddress,
        value: tokens,
        v: rlp.v,
        r: rlp.r,
        s: rlp.s,
      },
    });
    mlog.log("validate payment response:", JSON.stringify(response.data));

    response = await axios.post(SERVER, {
      cmd: "executePayment",
      data: {
        from: trzAddress,
        value: tokens,
        v: rlp.v,
        r: rlp.r,
        s: rlp.s,
      },
    });

    mlog.log("execute payment response:", JSON.stringify(response.data));

    response = await axios.post(SERVER, {
      cmd: "accountInfo",
      data: {
        address: trzAddress,
      },
    });
    mlog.log("accountInfo response", JSON.stringify(response.data));
    assert(
      parseInt(response.data.balance) == parseInt(initialBalance) - tokens,
      "wrong balance"
    );
  });
});
