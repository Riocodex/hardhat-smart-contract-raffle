const { network } = require("hardhat")
const { developmentChains } = require("../helper-hardhat-config")
module.exports = async function ({ getNamedAccounts , deployments}) {
    const { deploy , log } = deployments;
    const {deployer} = await getNamedAccounts();
    const chainId = network.config.chainId;
    let vrfCoordinatorV2Address;

    if (developmentChains.includes(network.name)){
        const VRFCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock");
        vrfCoordinatorV2Address = VRFCoordinatorV2Mock.address;
    }else{
        vrfCoordinatorV2Address = networkConfig[chainId]["vrfCoordinatorV2"];
    }

    const args = []
    const raffle = await deploy ("Raffle" , {
        from:deployer ,
        args:args,
        log:true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })
}