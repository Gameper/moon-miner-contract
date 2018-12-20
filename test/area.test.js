import assertRevert from './helpers/assertRevert'
import EVMRevert from './helpers/EVMRevert'

const BigNumber = web3.BigNumber

require('chai').use(require('chai-as-promised')).use(require('chai-bignumber')(BigNumber)).should()

const Area = artifacts.require('Area.sol')
const Registry = artifacts.require('Registry.sol')
const Treasure = artifacts.require('Treasure.sol')

contract('Area', function ([deployer, user1, user2, holder1, holder2, holder3]) {
    let registry, area, treasure

    beforeEach(async () => {
        area = await Area.new()
        registry = await Registry.new()
        treasure = await Treasure.new()
        
        await registry.setDomain("Area", area.address)
        await registry.setDomain("Treasure", treasure.address)
        await registry.setPermission("Area", treasure.address, "true")
        await registry.setPermission("Treasure", area.address, "true")
        await area.setRegistry(registry.address)
        await treasure.setRegistry(registry.address)

        await area.initialize();
        
    });
    describe('Owner ', function () {
        beforeEach(async () => {

        });

        it('Area can return address', async ()=> {
            assert.equal(1,1)
            
        });
        
        // Buy NFT from Area
        
        // Sell NFT from Area
        
        // NFT Holder get reward when mining success

        

    })

});
