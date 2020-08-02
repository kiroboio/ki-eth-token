const Migrations = artifacts.require("Migrations");

var Token = artifacts.require("./Token.sol");
var Pool = artifacts.require("./Pool.sol");
var Wallet = artifacts.require("./Wallet.sol");


module.exports = function(deployer, network, accounts) {

  const tokenOwner = accounts[0]
  const poolOwner = accounts[1]
  const walletOwner1 = accounts[2]
  const walletOwner2 = accounts[3]
  const walletOwner3 = accounts[4]
  deployer.then(async () => {
	  const token = await deployer.deploy(Token, { from: tokenOwner });
  	const pool = await deployer.deploy(Pool, token.address, { from: poolOwner });
  	const wallet = await deployer.deploy(Wallet, walletOwner1, walletOwner2, walletOwner3, { from: poolOwner });
  });

}

