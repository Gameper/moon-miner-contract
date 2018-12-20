

import assertRevert from './helpers/assertRevert'
import EVMRevert from './helpers/EVMRevert'

const BigNumber = web3.BigNumber

require('chai').use(require('chai-as-promised')).use(require('chai-bignumber')(BigNumber)).should()

const Area = artifacts.require('Area.sol')
const Registry = artifacts.require('Registry.sol')
const Treasure = artifacts.require('Treasure.sol')
const Mining = artifacts.require('Mining.sol')

contract('Area', function ([deployer, holder1, holder2, holder3, holder4]) {
    let registry, area, treasure, mining
    let ether1 = 10 ** 18, ether01 = 10 ** 17
    let totalSupply, AreaBalance, AreaWeight;
    let NFTid;
    let FTid;

    beforeEach(async () => {
        area = await Area.new()
        registry = await Registry.new()
        treasure = await Treasure.new()
        mining = await Mining.new()
        
        await registry.setDomain("Area", area.address)
        await registry.setDomain("Treasure", treasure.address)
        await registry.setPermission("Area", treasure.address, "true")
        await registry.setPermission("Treasure", area.address, "true")
        await registry.setPermission("Mining", mining.address, "true")
        
        await area.setRegistry(registry.address)
        await treasure.setRegistry(registry.address)
        await mining.setRegistry(registry.address)

        await area.initialize();
        await area.deposit({value:ether1*10})

        totalSupply = 1000;
        AreaBalance = ether1 * 10;
        AreaWeight = 1000000;
        
    });
    describe('Owner ', function () {
        beforeEach(async () => {

        });

        it('Area can buy and sell', async ()=> {
            // Buy NFT from Area
            let estimatedReturn = await area.calculatePurchaseReturn(totalSupply, AreaBalance, AreaWeight, ether01);
            console.log(`estimated Return : ${estimatedReturn}`);
            
            await area.buy({from:holder1, value:ether01})
            let list1addr = await area.getHolderIndex(1);
            NFTid = await area.tokenId();
            console.log(`list 1 addr : ${list1addr}`)
            console.log(`token id : ${NFTid}`)

            let holder1NFTbalance = await treasure.balanceOf(holder1, NFTid);

            console.log(`holder 1 balance : ${holder1NFTbalance}`)
            
            // Sell NFT from Area
            let estimatedEthReturn = await area.calculateSaleReturn(totalSupply+10, AreaBalance+ether01, AreaWeight, 10);
            console.log(`estimated ETH Return : ${estimatedEthReturn}`);
            await area.sell(10, {from:holder1})
            list1addr = await area.getHolderIndex(1);
            console.log(`list 1 addr : ${list1addr}`)

            holder1NFTbalance = await treasure.balanceOf(holder1, NFTid);
            console.log(`holder 1 balance : ${holder1NFTbalance}`)

        });

        it.only('Mining can deployed', async ()=> { 
            
            await mining.createResource("mineral", "Ruby", 18, 1000);
            FTid = await mining.tokenId();
            let nonce = 0;
            let chDigest = "Hello";
            let chanllengeNumber = await mining.getChallengeNumber(FTid);
            let digest = await mining.getMiningDigestByKeccak256(FTid, nonce, chDigest, chanllengeNumber)

            await mining.mine(FTid, nonce, digest);
        })
        
        
        
        
        
        // NFT Holder get reward when mining success

        

    })

});

