
const Token = artifacts.require('KiroboToken')
const Pool = artifacts.require('Pool')
const Wallet = artifacts.require("Wallet")

const liveTestNetworks = { ropsten: true, rinkeby: true, kovan: true };

module.exports = function(deployer, network, accounts) {

  const tokenOwner    = accounts[1]
  const poolOwner     = accounts[2]
  const walletOwner1  = accounts[6]
  const walletOwner2  = accounts[7]
  const walletOwner3  = accounts[8]

  deployer.then(async () => {
	  const token   = await deployer.deploy(Token, { from: tokenOwner })
  	const pool    = await deployer.deploy(Pool, token.address, { from: poolOwner })
    const wallet  = await deployer.deploy(Wallet, walletOwner1, walletOwner2, walletOwner3, { from: poolOwner })
    await token.disableTransfers(false, { from: tokenOwner })
    if (liveTestNetworks[network]) {
      await token.mint(pool.address, 100000, { from: tokenOwner })
      await pool.resyncTotalSupply(100000, { from: poolOwner })
    }
  })

}
