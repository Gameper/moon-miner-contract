pragma solidity ^0.4.24;

/**
 * @title IRegistry
 * @dev interface for registry
 * Owner should set domain and permission.
 */
contract IRegistry {
    function getAddressOf(bytes32 _name) public view returns(address addr);
    function getPermission(bytes32 _domain, address _granted) public view returns(bool found);
    
}