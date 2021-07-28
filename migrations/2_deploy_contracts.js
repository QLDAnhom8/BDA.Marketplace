const NginNFT = artifacts.require("NginNFT");

module.exports = async (deployer, _network, accounts) => {
    await deployer.deploy(NginNFT);
    const nft = await NginNFT.deployed();
    await nft.mint(accounts[0]);
}