const { developmentChains } = require("../helper-hardhat-config")

const BASE_FEE = ethers.utils.parseEther("0.25")

module.exports = async function ({ getNamedAccounts , deployments}) {
    const { deploy , log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    if(developmentChains.includes(network.name)){
        log("local network detected! Deploying mocks...")
        //deploy a mock vrfCoordinator
        await deploy("VRFCoordinatorV2Mock" , {

        })
    }
}