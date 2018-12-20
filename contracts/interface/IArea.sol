pragma solidity ^0.4.24;

/**
 * @title IArea
 * @dev interface for Area
 */
contract IArea {
    function getCurrentBeneficiaryInfo() public view returns(address beneficiary, uint256 ratio);
    function moveCursor() public returns (bool success);
    function modifyHolderAfterTrasnfer(address _from, uint256 _fromBalance, address _to, uint256 _toBalance) public returns (bool);
}