"use strict";

const Pool = artifacts.require("Pool");
const Token = artifacts.require("KiroboToken");
const mlog = require("mocha-logger");
const express = require("express");
const open = require("open");
const path = require("path");

const {
  assertRevert,
  assertInvalidOpcode,
  assertPayable,
  assetEvent_getArgs,
} = require("../../test/lib/asserts");

const {
  advanceBlock,
  advanceTime,
  advanceTimeAndBlock,
  pollCondition,
} = require("../../test/lib/utils");

const { hashMessage } = require('../../test/lib/hash');

contract("Trezor Test", async (accounts) => {

  let token, pool;

  let trzAddress, trzMessage, trzSignedMessage;

  const tokenOwner = accounts[1];
  const poolOwner = accounts[2];
  const user1 = accounts[3];
  const user2 = accounts[4];
  const user3 = accounts[5];

  const val1 = web3.utils.toWei("0.5", "gwei");
  const val2 = web3.utils.toWei("0.4", "gwei");
  const val3 = web3.utils.toWei("0.3", "gwei");
  const valBN = web3.utils.toBN("0");

  before("checking constants", async () => {
    assert(typeof tokenOwner == "string", "tokenOwner should be string");
    assert(typeof poolOwner == "string", "poolOwner should be string");
    assert(typeof user1 == "string", "user1 should be string");
    assert(typeof user2 == "string", "user2 should be string");
    assert(typeof user3 == "string", "user3 should be string");
    assert(typeof val1 == "string", "val1  should be big number");
    assert(typeof val2 == "string", "val2  should be string");
    assert(typeof val3 == "string", "val2  should be string");
    assert(valBN instanceof web3.utils.BN, "valBN should be big number");
  });

  before("setup contract for the test", async () => {
    token = await Token.new({ from: tokenOwner });
    pool = await Pool.new(token.address, { from: poolOwner });
    await token.disableTransfers(false, { from: tokenOwner });

    mlog.log("web3           ", web3.version);
    mlog.log("token contract ", token.address);
    mlog.log("pool contract  ", pool.address);
    mlog.log("tokenOwner     ", tokenOwner);
    mlog.log("poolOwner      ", poolOwner);
    mlog.log("user1          ", user1);
    mlog.log("user2          ", user2);
    mlog.log("user3          ", user3);
    mlog.log("val1           ", val1);
    mlog.log("val2           ", val2);
    mlog.log("val3           ", val3);
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

  it("should be able to generate, validate and execute 'token accept' message", async () => {

    await token.mint(pool.address, val1, { from: tokenOwner });
    const secret = "my secret";
    const tokens = 500;
    assert(trzAddress, 'trzAddress must be sent from the browser');
    mlog.log("trzAddress", trzAddress);
    await pool.issueTokens(trzAddress, 500, web3.utils.sha3(secret), { from: poolOwner })
    trzMessage = await pool.generateAcceptTokensMessage(trzAddress, tokens, web3.utils.sha3(secret), { from: poolOwner })
    mlog.log("message", trzMessage);

    const toSign = Buffer.from(web3.utils.sha3(trzMessage).slice(2)).toString('hex');
    mlog.log("toSign", toSign);
    trzMessage = toSign;

    mlog.log('Click "Sign" in the browser');
    await pollCondition(() => (trzSignedMessage !== undefined), 200);

    mlog.log('signed Trezor manual', JSON.stringify(trzSignedMessage));

    const r = "0x" + trzSignedMessage.substring(0, 64);
    const s = "0x" + trzSignedMessage.substring(64, 128);
    const v = "0x" + trzSignedMessage.substring(128, 130);

    const hashedToSign = hashMessage(toSign);

    const recovered = web3.eth.accounts.recover({
      messageHash: hashedToSign,
      v, r, s,
    })
    mlog.log("Recovered Trezor address", recovered);

    mlog.log("validating", `v is ${v} r is ${r} s is ${s}`);

    assert(
      await pool.validateAcceptTokens(
        trzAddress,
        tokens,
        web3.utils.sha3(secret),
        v, r, s,
        { from: trzAddress }
      ),
      "invalid ledger signature"
    );
    await pool.executeAcceptTokens(trzAddress, tokens, Buffer.from(secret), v, r, s, { from: poolOwner });
  });

});
