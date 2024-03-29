const HDWalletProvider = require("@truffle/hdwallet-provider")
const ganache = require("ganache-cli")
const MaticPOSClient = require('@maticnetwork/maticjs').MaticPOSClient
let server
const INFURA_API_KEY = 'c3b4ff6ae7d64731a16ccfa5ee811d65'


/**
 * Use this file to configure your truffle project. It's seeded with some
 * common settings for different networks and features like migrations,
 * compilation and testing. Uncomment the ones you need or modify
 * them to suit your project as necessary.
 *
 * More information about configuration can be found at:
 *
 * truffleframework.com/docs/advanced/configuration
 *
 * To deploy via Infura you'll need a wallet provider (like @truffle/hdwallet-provider)
 * to sign your transactions before they're sent to a remote public node. Infura accounts
 * are available for free at: infura.io/register.
 *
 * You'll also need a mnemonic - the twelve word phrase the wallet uses to generate
 * public/private key pairs. If you're publishing your code to GitHub make sure you load this
 * phrase from a file you've .gitignored so it doesn't accidentally become public.
 *
 */

// const HDWalletProvider = require('@truffle/hdwallet-provider');
// const infuraKey = "fj4jll3k.....";
const BSCSCANAPIKEY = '9ZP9CBPK9Z2DXHJTCFV748RA5656K1ZQ1U'
// const fs = require('fs');
// const mnemonic = fs.readFileSync(".secret").toString().trim();
const mnemonic = 'attack limb hood nothing divert clown target corn muscle leader naive small';
//const mnemonic = 'topic brown age machine torch art proof deny above ski badge border'

const parentProvider = new HDWalletProvider(mnemonic, 'https://mainnet.infura.io/v3/' + INFURA_API_KEY)

/* const maticPOSClient = new MaticPOSClient({
  network: "mainnet",
  version: "v1",
  parentProvider: parentProvider,
  maticProvider: maticProvider
}); */

module.exports = {
  plugins: [
    'truffle-plugin-verify'
  ],
  api_keys: {
    bscscan: BSCSCANAPIKEY
  },
  /**
   * Networks define how you connect to your ethereum client and let you set the
   * defaults web3 uses to send transactions. If you don't specify one truffle
   * will spin up a development blockchain for you on port 9545 when you
   * run `develop` or `test`. You can ask a truffle command to use a specific
   * network from the command line, e.g
   *
   * $ truffle test --network <network-name>
   */

  networks: {
    // Useful for testing. The `development` name is special - truffle uses it by default
    // if it's defined here and no other network is specified at the command line.
    // You should run a client (like ganache-cli, geth or parity) in a separate terminal
    // tab if you use this network and you must also set the `host`, `port` and `network_id`
    // options below to some value.
    //
    ganache: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*" ,// Match any network id
      gasPrice: 20000000000,
      gas: "6721975",
    },
    test: {
      network_id: "*",
      provider: function() {
        // const mnemonic2 = 'awesome grain neither pond excess garage tackle table piece assist venture escape'
        const mnemonic = 'front assume robust donkey senior economy maple enhance click bright game alcohol'
        const port = 7545
        if (!server) {
          server = ganache.server({ mnemonic })
          server.listen(port, ()=>{ console.log('ready')})
        }
        const provider = new HDWalletProvider(mnemonic, `http://127.0.0.1:${port}`)
        return provider
      },
    },
    /* ganache: {
      network_id: "*",
      provider: function() {
        // const mnemonic = 'awesome grain neither pond excess garage tackle table piece assist venture escape'
        const mnemonic = 'front assume robust donkey senior economy maple enhance click bright game alcohol'
        const port = 8545
        const provider = new HDWalletProvider(mnemonic, `http://127.0.0.1:${port}`)
        return provider
      },
    }, */
    ropsten: {
      provider: function() {
        mnemonic =
          "front assume robust donkey senior economy maple enhance click bright game alcohol";
        return new HDWalletProvider(
          mnemonic, "https://ropsten.infura.io/v3/adb23ed195ef4a499b698007beb437ca"
        );
      },
      network_id: 3,
    },
    testnet: {
      provider: () => new HDWalletProvider(mnemonic, `https://data-seed-prebsc-1-s1.binance.org:8545`),
      network_id: 97,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true,
      //from: "0x29bC20DebBB95fEFef4dB8057121c8e84547E1A9",
      from: "0x1cbed60336E3FEe0734325fe70B13B805c15d99d",
      //gas: "4500000",
      //gasPrice: "10000000000",
    },
    bsc: {
      provider: () => new HDWalletProvider(mnemonic, `https://bsc-dataseed1.binance.org`),
      network_id: 56,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    maticMain: {
      provider: () => new HDWalletProvider(mnemonic, 'https://rpc-mainnet.maticvigil.com/v1/cce4f4c10a8fd12cd1590eddf140a9f937809b07'),
      network_id: 137,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
      from: "0x29bC20DebBB95fEFef4dB8057121c8e84547E1A9",
      //gas: "4500000",
      //gasPrice: "10000000000",
    },
    development: {
      network_id: "*",
      provider: function () {
        const mnemonic = 'awesome grain neither pond excess garage tackle table piece assist venture escape'
        const port = 9545
        const accounts = 220
        if (!server) {
          server = ganache.server({
            mnemonic,
            total_accounts: accounts,
            gasLimit: 22500000,
            default_balance_ether: 1000,
          })
           server.listen(port, () => { console.log('ready') })
         }
         const provider = new HDWalletProvider({
           mnemonic,
           numberOfAddresses: accounts,
           providerOrUrl: `http://127.0.0.1:${port}`,
           _chainId: 4,
           _chainIdRpc: 4,
          })
         return provider
       },
      ens: {
        registry: {
          address: '0x194882C829ba3F56C7B7b99175435381d8Ac30B9',
        },
      },
    },
    shasta:{
      privateKey:'e6b4df55147ef6891de00c6227e403e99663e805c40ff4c869039abfc30f65c3',
      fee_limit: 100000000,
      fullNode:"https://api.shasta.trongrid.io",
      solidityNode :"https://api.shasta.trongrid.io",
      eventServer:"https://api.shasta.trongrid.io",
      network_id: "*"
    },
    matic: {
      provider: () => new HDWalletProvider(mnemonic, `https://rpc-mumbai.maticvigil.com`),
      network_id: 80001,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
      from: "0x29bC20DebBB95fEFef4dB8057121c8e84547E1A9",
      //gas: "4500000",
      //gasPrice: "10000000000",
    },
    rinkeby: {
      provider: function() {
        mnemonic =
          "front assume robust donkey senior economy maple enhance click bright game alcohol";
        return new HDWalletProvider(
          mnemonic, "https://rinkeby.infura.io/v3/adb23ed195ef4a499b698007beb437ca"
        );
      },
      network_id: 4,
      gasPrice: 20000000000,
      gas: "29900000",
      //from: "0x119a1fF5DA23046784E83e35E94753e42feF7ad3",
    },
    goerli: {

      provider: function(){
        Orimnemonic = 'attack limb hood nothing divert clown target corn muscle leader naive small';
        return new HDWalletProvider(Orimnemonic, 'https://goerli.infura.io/v3/' + INFURA_API_KEY)
      } ,
      network_id: 5,
      //confirmations: 2,
      //timeoutBlocks: 200,
      skipDryRun: true,
      from: "0x29bC20DebBB95fEFef4dB8057121c8e84547E1A9",
      //gas: "29000000",
      //gasPrice: "200000000000",
      //nounce: 3,
    },

    // Another network with more advanced options...
    // advanced: {
      // port: 8777,             // Custom port
      // network_id: 1342,       // Custom network
      // gas: 8500000,           // Gas sent with each transaction (default: ~6700000)
      // gasPrice: 20000000000,  // 20 gwei (in wei) (default: 100 gwei)
      // from: <address>,        // Account to send txs from (default: accounts[0])
      // websockets: true        // Enable EventEmitter interface for web3 (default: false)
    // },

    // Useful for deploying to a public network.
    // NB: It's important to wrap the provider as a function.
    // ropsten: {
      // provider: () => new HDWalletProvider(mnemonic, `https://ropsten.infura.io/v3/YOUR-PROJECT-ID`),
      // network_id: 3,       // Ropsten's id
      // gas: 5500000,        // Ropsten has a lower block limit than mainnet
      // confirmations: 2,    // # of confs to wait between deployments. (default: 0)
      // timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      // skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    // },

    // Useful for private networks
    // private: {
      // provider: () => new HDWalletProvider(mnemonic, `https://network.io`),
      // network_id: 2111,   // This network is yours, in the cloud.
      // production: true    // Treats this network as if it was a public net. (default: false)
    // }
  },


  // Set default mocha options here, use special reporters etc.
  mocha: {
    reporter: 'eth-gas-reporter',
    reporterOptions : {
      url: 'http://127.0.0.1:8545',
    },
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.6.12",    // Fetch exact version from solc-bin (default: truffle's version)
    }
  },
  solc: {
      settings: {          // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 999
        },
      },
      optimizer: {
          enabled: true,
          runs: 999
      }
  }
}
