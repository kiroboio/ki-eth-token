"use strict";

/**
 * Need to be connected to ETH app in ledger to run this test
 */

const Pool = artifacts.require("Pool");
const Token = artifacts.require("Token");
const mlog = require("mocha-logger");
const hidTransport = require("@ledgerhq/hw-transport-node-hid").default;
const App = require("@ledgerhq/hw-app-eth").default;

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
} = require("../../test/lib/utils");

const { hashMessage } = require('../../test/lib/hash');


contract("Ledger Test", async (accounts) => {
  let ethApp, token, pool;

  const tokenOwner = accounts[1];
  const poolOwner = accounts[2];
  const user1 = accounts[3];
  const user2 = accounts[4];
  const user3 = accounts[5];

  const user0 = accounts[0];

  const val1 = web3.utils.toWei("0.5", "gwei");
  const val2 = web3.utils.toWei("0.4", "gwei");
  const val3 = web3.utils.toWei("0.3", "gwei");
  const valBN = web3.utils.toBN("0");

  const PATH = "44'/60'/0'/0/0";

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

    mlog.log('web3           ', web3.version)
    mlog.log('tokenOwner     ', tokenOwner)
    mlog.log('poolOwner      ', poolOwner)
    mlog.log('user0          ', user0)
    mlog.log('user1          ', user1)
    mlog.log('user2          ', user2)
    mlog.log('user3          ', user3)
    mlog.log('val1           ', val1)
    mlog.log('val2           ', val2)
    mlog.log('val3           ', val3)

    token = await Token.deployed()
    pool = await Pool.deployed()

    mlog.log('token contract ', token.address)
    mlog.log('pool contract  ', pool.address)
  });

  before("setup ledger", async () => {
    const transport = await hidTransport.create();
    ethApp = new App(transport);
  });

  it("should be able to generate, validate and execute 'token accept' message", async () => {
    await token.mint(pool.address, val1, { from: tokenOwner })
    await pool.resyncTotalSupply(await pool.ownedTokens(), { from: poolOwner })
    const secret = "my secret";
    const tokens = 500;
    const { address: ldgAddress } = await ethApp.getAddress(PATH);
    mlog.log("ledger address", ldgAddress);
    await pool.issueTokens(ldgAddress, tokens, web3.utils.sha3(secret), { from: poolOwner })
    const message = await pool.generateAcceptTokensMessage(ldgAddress, tokens, web3.utils.sha3(secret), { from: poolOwner })
    mlog.log("message", message);

    const toSign = Buffer.from(web3.utils.sha3(message).slice(2)).toString('hex');
    mlog.log("toSign", toSign);
    const hashedToSign = hashMessage(toSign);
    // mlog.log("message hash", hashToSign);


    const signedLedger = await ethApp.signPersonalMessage(
      PATH,
      toSign,
    );

    mlog.log('signed Ledger manual', JSON.stringify(signedLedger));

    let v = '0x' + signedLedger.v.toString(16);

    let { r, s } = signedLedger;

    const recovered = web3.eth.accounts.recover({
      messageHash: hashedToSign,
      v,
      r: "0x" + r,
      s: "0x" + s
    })
    mlog.log("Recovered Ledger", recovered);

    mlog.log("validating", `v is ${v} r is ${"0x" + r} s is ${"0x" + s}`);

    assert(
      await pool.validateAcceptTokens(
        ldgAddress,
        tokens,
        web3.utils.sha3(secret),
        v,
        "0x" + signedLedger.r,
        "0x" + signedLedger.s,
        { from: ldgAddress }
      ),
      "invalid ledger signature"
    );
    await pool.executeAcceptTokens(ldgAddress, tokens, Buffer.from(secret), v, "0x" + signedLedger.r, "0x" + signedLedger.s, { from: poolOwner })
  });

  it('should be able to generate,validate & execute "payment" message', async () => {
    const { address: ldgAddress } = await ethApp.getAddress(PATH);
    mlog.log("ledger address", ldgAddress);
    await token.mint(ldgAddress, val1, { from: tokenOwner })
    const message = await pool.generatePaymentMessage(ldgAddress, 200, { from: poolOwner })
    mlog.log('message: ', message)

    mlog.log("sha3(message)", web3.utils.sha3(message));

    const toSign = Buffer.from(web3.utils.sha3(message).slice(2)).toString('hex');
    mlog.log("toSign", toSign);

    const hashedToSign = hashMessage(toSign);

    mlog.log("message hash", hashedToSign);

    const signedLedger = await ethApp.signPersonalMessage(
      PATH,
      toSign,
    );

    mlog.log('signed Ledger manual', JSON.stringify(signedLedger));

    let v = '0x' + signedLedger.v.toString(16);

    let { r, s } = signedLedger;

    const recovered = web3.eth.accounts.recover({
      messageHash: hashedToSign,
      v,
      r: "0x" + r,
      s: "0x" + s
    })
    mlog.log("Recovered Ledger", recovered);

    mlog.log("validating", `v is ${v} r is ${"0x" + r} s is ${"0x" + s}`);

    assert(
      await pool.validatePayment(
        ldgAddress,
        200,
        v,
        "0x" + signedLedger.r,
        "0x" + signedLedger.s,
        { from: ldgAddress }
      ),
      "invalid ledger signature"
    );
  });
});
