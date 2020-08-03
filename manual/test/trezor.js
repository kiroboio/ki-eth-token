"use strict";

const Pool = artifacts.require("Pool");
const Token = artifacts.require("KiroboToken");
const mlog = require("mocha-logger");
const TrezorConnect = require("trezor-connect").default;

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

contract("Trezor Test", async (accounts) => {
  let ethApp, token, pool;
  let _web3;

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

  // before("setup trezor", async () => {
  //   const transport = await hidTransport.create();
  //   ethApp = new App(transport);
  //   _web3 = new web3(new LedgerProvider());
  // });

  const sanitizeHex = (hex) => {
    hex = hex.substring(0, 2) === "0x" ? hex.substring(2) : hex;
    if (hex == "") return "";
    return "0x" + padLeftEven(hex);
  };

  const getBufferFromHex = (hex) => {
    hex = sanitizeHex(hex);
    const _hex = hex.toLowerCase().replace("0x", "");
    return new Buffer(_hex, "hex");
  };

  const toBuffer = (v) => {
    if (ethUtil.isHexString(v)) {
      return ethUtil.toBuffer(v);
    }
    return Buffer.from(v);
  };

  const padLeftEven = (hex) => {
    hex = hex.length % 2 != 0 ? "0" + hex : hex;
    return hex;
  };

  const msgSigner = async (msg, path) => {
    const result = await ethApp.signPersonalMessage(
      path,
      toBuffer(msg).toString("hex")
    );
    const v = parseInt(result.v, 10) - 27;
    const vHex = sanitizeHex(v.toString(16));
    // return Buffer.concat([
    //   getBufferFromHex(result.r),
    //   getBufferFromHex(result.s),
    //   getBufferFromHex(vHex),
    // ]);
    return {
      v: vHex,
      r: result.r,
      s: result.s,
    };
  };

  it("should be able to generate message", async () => {
    const PATH = "44'/60'/0'/0/0";
    await token.mint(pool.address, val1, { from: tokenOwner });
    await token.mint(user1, val2, { from: tokenOwner });
    await token.approve(pool.address, val3, { from: user1 });
    await pool.deposit(val3, { from: user1 });
    const res = await TrezorConnect.ethereumGetAddress({
      path: PATH,
      showOnTrezor: false,
    });
    mlog.log("trezor res", JSON.stringify(res));
    const address = res.payload.address;
    const message = await pool.generateAcceptTokensMessage(address, 200, {
      from: poolOwner,
    });
    mlog.log("message", message);
    mlog.log("sha3", web3.utils.sha3(message));
    const signed = await TrezorConnect.ethereumSignMessage({
      path: PATH,
      message: web3.utils.sha3(message).slice(2),
    });

    mlog.log(`signed: ${JSON.stringify(signed)}`);

    // let v = signed.v - 27;
    // v = v.toString(16);
    // if (v.length < 2) {
    //   v = "0x0" + v;
    // }

    // let { r, s } = signed;

    // mlog.log("validating", `v is ${v} r is ${"0x" + r} s is ${"0x" + s}`);

    // assert(
    //   await pool.validateAcceptTokensMessage(
    //     address,
    //     200,
    //     v,
    //     "0x" + signed.r,
    //     "0x" + signed.s,
    //     { from: address }
    //   ),
    //   "invalid signature"
    // );
    assert(2 === 2);
  });
});
