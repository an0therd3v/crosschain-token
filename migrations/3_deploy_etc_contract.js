var CrosschainTokenETC = artifacts.require("./CrosschainTokenETC.sol");

module.exports = function(deployer) {
  deployer.deploy(CrosschainTokenETC);
};
