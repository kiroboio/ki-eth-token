/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-web3");
module.exports = {
  solidity: {
    version: "0.6.12",
    settings: {
      optimizer: {
        enabled: true,
        runs: 999, // Optimize for how many times you intend to run the code
      },
      outputSelection: {
        "*": {
          "*": ["storageLayout"],
          "": ["storageLayout"],
        },
      },
    },
  },
  networks: {
    hardhat: {
      chainId: 4,
      allowUnlimitedContractSize: true,
      accounts: {
        mnemonic:
          "awesome grain neither pond excess garage tackle table piece assist venture escape",
        count: 220,
      },
    },
  },
};
