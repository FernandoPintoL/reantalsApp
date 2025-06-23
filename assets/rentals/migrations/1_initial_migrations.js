const RentalContract = artifacts.require("../contracts/RentalContract.sol");

module.exports = function(deployer) {
    deployer.deploy(RentalContract);
};