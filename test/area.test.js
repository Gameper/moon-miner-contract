import assertRevert from './helpers/assertRevert'
import EVMRevert from './helpers/EVMRevert'

const BigNumber = web3.BigNumber

require('chai').use(require('chai-as-promised')).use(require('chai-bignumber')(BigNumber)).should()

const Area = artifacts.require('Area.sol')

contract('Area', function ([deployer, user1, user2, holder1, holder2, holder3]) {
    let registry, area

    beforeEach(async () => {
        area = await Area.new()
    });
    describe('Owner ', function () {
        beforeEach(async () => {

        });
        it('Area can return address', async ()=> {
            assert.equal(1,1)
            
        });
    })

});
