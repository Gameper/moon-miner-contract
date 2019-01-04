

import assertRevert from './helpers/assertRevert'
import EVMRevert from './helpers/EVMRevert'
import advanceBlock from './helpers/advanceToBlock'

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
        await registry.setPermission("Area", mining.address, "true")
        
        await area.setRegistry(registry.address)
        await treasure.setRegistry(registry.address)
        await mining.setRegistry(registry.address)
        
        
        await area.initialize("Area0", "Area", 0, 1000, "true"); // "Area0", "Area", 0, 1000, true
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
            // FTid = await mining.tokenId();
            let nonce = 0;
            let chDigest = "Hello";
            let chanllengeNumber = await mining.getChallengeNumber();
            let digest = await mining.getMintDigest(nonce, chDigest, chanllengeNumber)

            //nonce need to be loop if fail
            // await mining.mine(FTid, nonce, digest);
            await mining.mint(nonce, digest);
        })

        it('Area - Mining - Treasure basic work with 1 NFT buyer', async ()=> { 
            // Buy NFT from Area
            let estimatedReturn = await area.calculatePurchaseReturn(totalSupply, AreaBalance, AreaWeight, ether01);
            console.log(`estimated Return : ${estimatedReturn}`);
            
            await area.buy({from:holder1, value:ether01})
            let list1addr = await area.getHolderIndex(1);
            NFTid = await area.tokenId();
            console.log(`list 1 addr : ${list1addr}`)
            console.log(`token id : ${NFTid}`)

            let holder1NFTbalance = await treasure.balanceOf(holder1, NFTid);

            console.log(`holder 1 NFT balance : ${holder1NFTbalance}`)

            await mining.createResource("mineral", "Ruby", 18, 1000);
            FTid = await mining.tokenId();
            let nonce = 0;
            let chDigest = "Hello";
            let chanllengeNumber = await mining.getChallengeNumber(FTid);
            let digest = await mining.getMiningDigestByKeccak256(FTid, nonce, chDigest, chanllengeNumber)

            //nonce need to be loop if fail
            await mining.mine(FTid, nonce, digest);


            // NFT Holder get reward when mining success

            let holder1FTbalance = await treasure.balanceOf(holder1, FTid);
            console.log(`holder 1 mineral balance : ${holder1FTbalance}`)

            let minerbalance = await treasure.balanceOf(deployer, FTid);
            console.log(`miner mineral balance : ${minerbalance}`)
        })
        
        it('Area - Mining - Treasure basic work with 3 NFT buyer', async ()=> { 
            // Buy NFT from Area
            let estimatedReturn = await area.calculatePurchaseReturn(totalSupply, AreaBalance, AreaWeight, ether01);
            console.log(`estimated Return : ${estimatedReturn}`);
            
            await area.buy({from:holder1, value:ether01})
            await area.buy({from:holder2, value:ether01})
            await area.buy({from:holder3, value:ether01})

            let list1addr = await area.getHolderIndex(1);
            NFTid = await area.tokenId();
            console.log(`list 1 addr : ${list1addr}`)
            console.log(`token id : ${NFTid}`)

            let holder1NFTbalance = await treasure.balanceOf(holder1, NFTid);
            let holder2NFTbalance = await treasure.balanceOf(holder2, NFTid);
            let holder3NFTbalance = await treasure.balanceOf(holder3, NFTid);

            console.log(`holder 1 NFT balance : ${holder1NFTbalance}`)
            console.log(`holder 2 NFT balance : ${holder2NFTbalance}`)
            console.log(`holder 3 NFT balance : ${holder3NFTbalance}`)

            await mining.createResource("mineral", "Ruby", 18, 1000);
            FTid = await mining.tokenId();
            let nonce = 0;
            let chDigest = "Hello";
            let chanllengeNumber = await mining.getChallengeNumber(FTid);
            let digest = await mining.getMiningDigestByKeccak256(FTid, nonce, chDigest, chanllengeNumber)

            //nonce need to be loop if fail
            await mining.mine(FTid, nonce, digest);

            chanllengeNumber = await mining.getChallengeNumber(FTid);
            digest = await mining.getMiningDigestByKeccak256(FTid, nonce, chDigest, chanllengeNumber)
            await mining.mine(FTid, nonce, digest);

            chanllengeNumber = await mining.getChallengeNumber(FTid);
            digest = await mining.getMiningDigestByKeccak256(FTid, nonce, chDigest, chanllengeNumber)
            await mining.mine(FTid, nonce, digest);

            chanllengeNumber = await mining.getChallengeNumber(FTid);
            digest = await mining.getMiningDigestByKeccak256(FTid, nonce, chDigest, chanllengeNumber)
            await mining.mine(FTid, nonce, digest);

            chanllengeNumber = await mining.getChallengeNumber(FTid);
            digest = await mining.getMiningDigestByKeccak256(FTid, nonce, chDigest, chanllengeNumber)
            await mining.mine(FTid, nonce, digest);

            // await advanceBlock()

            // NFT Holder get reward when mining success

            let holder1FTbalance = await treasure.balanceOf(holder1, FTid);
            console.log(`holder 1 mineral balance : ${holder1FTbalance}`)

            let holder2FTbalance = await treasure.balanceOf(holder2, FTid);
            console.log(`holder 2 mineral balance : ${holder2FTbalance}`)

            let holder3FTbalance = await treasure.balanceOf(holder3, FTid);
            console.log(`holder 3 mineral balance : ${holder3FTbalance}`)

            let minerbalance = await treasure.balanceOf(deployer, FTid);
            console.log(`miner mineral balance : ${minerbalance}`)
        })

    })

});

