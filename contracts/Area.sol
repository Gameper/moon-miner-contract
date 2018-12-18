pragma solidity ^0.4.24;

/**
 * @title Area
 * @dev Area
 */
contract Area {
    
    function getCurrentBeneficiaryInfo() public view returns(address beneficiary, uint256 ratio){
        return (0x6f0f5673d69b4608ac9be5887b2f71f20d0c3587, 10**17);
    }

    function moveCursor() public returns (bool success){
        return true;
    }
}