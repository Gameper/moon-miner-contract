'use strict'

const Registry = artifacts.require('Registry.sol')
const Treasure = artifacts.require('Treasure.sol')
const Area = artifacts.require('Area.sol')
const Mining = artifacts.require('Mining.sol')

async function deploy(deployer, network, accounts) {
    let registry, area, treasure, mining
    let ether1 = 10 ** 18, ether01 = 10 ** 17
    let totalSupply = 1000, AreaBalance, AreaWeight = 1000000;
    const args = process.argv.slice()

    if (args[3] == 'all') {
        deployer.then(async () => {
            
            registry = await deployer.deploy(Registry)
            area = await deployer.deploy(Area)
            treasure = await deployer.deploy(Treasure)
            mining = await deployer.deploy(Mining)
            
            await registry.setDomain("Area", area.address)
            await registry.setDomain("Treasure", treasure.address)
            await registry.setDomain("Mining", mining.address)
            
            await registry.setPermission("Area", treasure.address, "true")
            await registry.setPermission("Treasure", area.address, "true")
            await registry.setPermission("Mining", mining.address, "true")
            await registry.setPermission("Area", mining.address, "true")

            await area.setRegistry(registry.address)
            await treasure.setRegistry(registry.address)
            await mining.setRegistry(registry.address)
            
            console.log(`area initialize`)
            await area.initialize("Area0", "Area", 0, 1000, "true");
            console.log(`area deposit`)
            await area.deposit({value:10000000000000000000});
            AreaBalance = ether1 * 10;

            console.log(`mining create resource`)
            await mining.createResource("Mineral", "MLL", 18, 21000000);

        })

    } else if (args[3] == 'area') {
        

    } 
}
module.exports = deploy