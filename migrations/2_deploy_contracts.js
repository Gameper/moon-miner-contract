'use strict'

const Registry = artifacts.require('Registry.sol')

async function deploy(deployer, network, accounts) {
    let reg, mim, tr, am, ar, achiv
    const args = process.argv.slice()

    if (args[3] == 'all') {
       
    } else if (args[3] == 'area') {
        deployer.then(async () => {})

    } 
}
module.exports = deploy