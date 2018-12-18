pragma solidity ^0.4.24;

import "./openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./interface/IRegistry.sol";

/**
 * @title RegistryUser
 * @dev RegistryUser Contract that uses Registry contract
 */
contract RegistryUser is Ownable {
    
    IRegistry public registry;
    bytes32 public thisDomain;

    /**
     * @dev Function to set registry address. Contract that wants to use registry should setRegistry first.
     * @param _addr address of registry
     * @return A boolean that indicates if the operation was successful.
     */
    function setRegistry(address _addr) public onlyOwner {
        registry = IRegistry(_addr);
    }
    
    modifier permissioned() {
        require(isPermitted(msg.sender), "No Permission");
        _;
    }

    /**
     * @dev Function to check the permission
     * @param _addr address of sender to check the permission
     * @return A boolean that indicates if the operation was successful.
     */
    function isPermitted(address _addr) public view returns(bool found) {
        return registry.getPermission(thisDomain, _addr);
    }
    
}