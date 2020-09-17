
const Token = artifacts.require('Token')
const Pool = artifacts.require('Pool')
const Wallet = artifacts.require("Wallet")
const Minter = artifacts.require("Minter")
const Vesting = artifacts.require("Vesting")
const Unipool = artifacts.require("Unipool")

const liveTestNetworks = { ropsten: true, rinkeby: true, kovan: true };

module.exports = function(deployer, network, accounts) {

  const tokenOwner    = accounts[1]
  const poolOwner     = accounts[2]
  const walletOwner1  = accounts[6]
  const walletOwner2  = accounts[7]
  const walletOwner3  = accounts[8]
  const mintRecipient = accounts[9]

  deployer.then(async () => {
    const now = (new Date()).getTime()/1000
    const retrieveTime = '' + Math.round(now+(60*60*24))
    const releaseTime = '' + Math.round(now+(60*60*24*7))
    const token   = await deployer.deploy(Token, { from: tokenOwner })
  	const minter  = await deployer.deploy(Minter, token.address, mintRecipient, { from: tokenOwner })
  	const vesting = await deployer.deploy(Vesting, token.address, mintRecipient, retrieveTime, tokenOwner, releaseTime, { from: tokenOwner })
  	// const unipool = await deployer.deploy(Unipool, '0xd0fd23E6924a7A34d34BC6ec6b97fadD80BE255F', token.address, { from: tokenOwner })
  	const pool    = await deployer.deploy(Pool, token.address, { from: poolOwner })
    const wallet  = await deployer.deploy(Wallet, walletOwner1, walletOwner2, walletOwner3, { from: poolOwner })
    // await token.disableTransfers(false, { from: tokenOwner })
    if (liveTestNetworks[network]) {
      const supply = 100000n * 10n**18n
      await token.mint(pool.address, supply.toString(), { from: tokenOwner })
      await pool.resyncTotalSupply(supply.toString(), { from: poolOwner })
    }
  })

}
