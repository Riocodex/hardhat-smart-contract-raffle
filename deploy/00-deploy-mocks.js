const { developmentChains } = require("../helper-hardhat-config")

const BASE_FEE = ethers.utils.parseEther("0.25")//0.25 is the premium , it cost 0.25 link per request
const GAS_PRICE_LINK =1e9 //calculated value based on the gas price of the chain
const args = [BASE_FEE , GAS_PRICE_LINK]
module.exports = async function ({ getNamedAccounts , deployments}) {
    const { deploy , log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    if(developmentChains.includes(network.name)){
        log("local network detected! Deploying mocks...")
        //deploy a mock vrfCoordinator
        await deploy("VRFCoordinatorV2Mock" , {
            from: deployer , 
            log: true ,
            args: args, 
        })
        log("Mocks Deployed!")
        log("--------------------------------")
    }
}
module.exports.tags = ["all" , "mocks"];