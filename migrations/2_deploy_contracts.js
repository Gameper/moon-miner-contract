'use strict'

const Registry = artifacts.require('Registry.sol')
const Treasure = artifacts.require('Treasure.sol')
const Area = artifacts.require('Area.sol')

async function deploy(deployer, network, accounts) {
    let registry, area, treasure
    let ether1 = 10 ** 18, ether01 = 10 ** 17
    let totalSupply = 1000, AreaBalance, AreaWeight = 1000000;
    const args = process.argv.slice()

    if (args[3] == 'all') {
        deployer.then(async () => {
            registry = await deployer.deploy(Registry)
            area = await deployer.deploy(Area)
            treasure = await deployer.deploy(Treasure)
            
            await registry.setDomain("Area", area.address)
            await registry.setDomain("Treasure", treasure.address)
            await registry.setPermission("Area", treasure.address, "true")
            await registry.setPermission("Treasure", area.address, "true")
            await area.setRegistry(registry.address)
            await treasure.setRegistry(registry.address)
    
            await area.initialize();
            await area.deposit({value:ether1*10})
            AreaBalance = ether1 * 10;

        })

    } else if (args[3] == 'area') {
        

    } 
}
module.exports = deploy