
//const Token = artifacts.require('Token') 
//const Pool = artifacts.require('Pool')
//const Wallet = artifacts.require("Wallet")
//const Minter = artifacts.require("Minter")
//const Staking = artifacts.require("Staking")
//const SafeSwap = artifacts.require("SafeSwap") 
//const SafeTransfer = artifacts.require("SafeTransfer")
const SafeForERC1155 = artifacts.require("SafeForERC1155")
const MyERC1155 = artifacts.require("MyERC1155")

//const liveTestNetworks = { ropsten: true, rinkeby: true, kovan: true };
//const liveTestNetworks = { maticMain: true };


module.exports = function(deployer, network, accounts) {

  const tokenOwner    = accounts[1]
/*    const poolOwner     = accounts[2]
  const walletOwner1  = accounts[6]
  const walletOwner2  = accounts[7]
  const walletOwner3  = accounts[8]
  const mintRecipient = accounts[9]  */

  deployer.then(async () => {
    // const now = (new Date()).getTime()/1000
    // const retrieveTime = '' + Math.round(now+(60*60*24))
    // const releaseTime = '' + Math.round(now+(60*60*24*7))
     //const token   = await deployer.deploy(Token, { from: '0x29bC20DebBB95fEFef4dB8057121c8e84547E1A9' })
  	 //const minter  = await deployer.deploy(Minter, token.address, mintRecipient, { from: tokenOwner })
  	// const vesting = await deployer.deploy(Vesting, token.address, mintRecipient, retrieveTime, tokenOwner, releaseTime, { from: tokenOwner })
  	// // const unipool = await deployer.deploy(Unipool, '0xd0fd23E6924a7A34d34BC6ec6b97fadD80BE255F', token.address, { from: tokenOwner })
    // const unipool = await deployer.deploy(Unipool, '0xd0fd23E6924a7A34d34BC6ec6b97fadD80BE255F', token.address, { from: tokenOwner })
    //const staking = await deployer.deploy(Staking, , )
  //	const pool    = await deployer.deploy(Pool, "0xB382C1cfA622795a534e5bd56Fac93d59BAc8B0D", { from: tokenOwner })
    //const safeSwap = await deployer.deploy(SafeSwap ,'0x29bC20DebBB95fEFef4dB8057121c8e84547E1A9' , { from: '0x29bC20DebBB95fEFef4dB8057121c8e84547E1A9' })
    const myERC1155 = await deployer.deploy(MyERC1155, { from: tokenOwner })
    const safeForERC1155 = await deployer.deploy(SafeForERC1155 ,tokenOwner , { from: tokenOwner })
    //const safeTransfer = await deployer.deploy(SafeTransfer ,'0x29bC20DebBB95fEFef4dB8057121c8e84547E1A9' , { from: '0x29bC20DebBB95fEFef4dB8057121c8e84547E1A9' })
 
     /*await token.disableTransfers(false, { from: tokenOwner })
     if (liveTestNetworks[network]) {
       const supply = 100000n * 10n**18n
       await token.mint(pool.address, supply.toString(), { from: tokenOwner })
       //await pool.resyncTotalSupply(supply.toString(), { from: poolOwner })
    }} */
  //)

})
}
