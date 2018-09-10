var CrosschainTokenETH = artifacts.require("./CrosschainTokenETH.sol");

module.exports = function(deployer) {
  deployer.deploy(CrosschainTokenETH);
};
