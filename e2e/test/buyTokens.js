/**
 * Have some eth on my balance ?
 * Send an issue tokens
 * Get message
 * Sign message
 * Send to ExecuteAcceptTokens
 */

const axios = require('axios');
const { assert } = require("console");

const ETH_ACC = '0x6a13b7F1Ec6e94cE5d77563ce12702da8E4E84B8';
const LOCAL_POOL = 'http://127.0.0.1:3030/v1/eth/rinkeby/pool'

contract("Buy Tokens", async accounts => {
  before("setup", async () => {
    // set up

  });

  it("should be able to initiate issueTokens", async () => {
    const secret = "supermegal117secretz";
    const secretHash = web3.utils.sha3(secret);
    const tokens = 500;
    const response = await axios.post(LOCAL_POOL, {
      cmd: "issueTokens",
      data: {
        to: ETH_ACC,
        value: 500,
        secretHash,
      },
    });
    assert(response.data.arguments.value === tokens);
  });



});