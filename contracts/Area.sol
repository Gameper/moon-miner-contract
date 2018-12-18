pragma solidity ^0.4.24;

/**
 * @title Area
 * @dev Area
 */
contract Area {
    
    uint256 AreaWeight;
    uint256 AreaBalance;
    uint256 depositAmount;

    function getCurrentBeneficiaryInfo() public view returns(address beneficiary, uint256 ratio){
        return (0x6f0f5673d69b4608ac9be5887b2f71f20d0c3587, 10**17);
    }

    function moveCursor() public returns (bool success){
        return true;
    }

    function buy() public payable returns (bool success){
        // mintingAmount = calculatePurchaseReturn(totalSupply, AreaBalance, AreaWeight, depositAmount)
        // batchMint(mintingAmount, msg.sender, "Area0Security")
        // add holder to linked list if not exist
        // set time lock
        // (balance added to the contract)
        return true;

    }
    function sell() public returns (bool success){
        // buringAmount = calculateSaleReturn(totalSupply, AreaBalance, AreaWeight, depositAmount)
        // batchBurn(burningAmount, msg.sender);
        // send balance to the msg.sender
        // remove holder from linked list if token balance == 0 and move cursor if needed
        // set time lock
    }
}