pragma solidity ^0.4.24;

import "./openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./interface/IRegistry.sol";
/**
 * @title Registry
 * @dev Registry Contract used to set domain and permission
 * Owner should set domain and permission.
 */
contract Registry is IRegistry, Ownable {
    
    mapping(bytes32=>address) internal domains;
    mapping(bytes32=>mapping(address=>bool)) internal permissions;

    event SetDomain(address setter, bytes32 indexed name, address indexed addr);
    event SetPermission(bytes32 indexed domain, address indexed granted, bool status);

    /**
    * @dev Function to set contract(can be general address) domain
    * Only owner can use this function
    * @param _name name
    * @param _addr address
    * @return A boolean that indicates if the operation was successful.
    */
    function setDomain(bytes32 _name, address _addr) public onlyOwner returns (bool success) {
        require(_addr != address(0x0), "address should be non-zero");
        domains[_name] = _addr;

        emit SetDomain(msg.sender, _name, _addr);

        return true;

    }
    /**
    * @dev Function to get contract(can be general address) address
    * Anyone can use this function
    * @param _name _name
    * @return An address of the _name
    */
    function getAddressOf(bytes32 _name) public view returns(address addr) {
        require(domains[_name] != address(0x0), "address should be non-zero");
        return domains[_name];
    }

    /**
    * @dev Function to set permission on domain
    * domain using modifier 'permissioned' references mapping variable 'permissions'
    * Only owner can use this function
    * @param _domain domain name
    * @param _granted granted address
    * @param _status true = can use, false = cannot use. default is false
    * @return A boolean that indicates if the operation was successful.
    */
    function setPermission(bytes32 _domain, address _granted, bool _status) public onlyOwner returns(bool success) {
        require(_granted != address(0x0), "address should be non-zero");
        permissions[_domain][_granted] = _status;

        emit SetPermission(_domain, _granted, _status);
        
        return true;
    }

    /**
    * @dev Function to get permission on domain
    * domain using modifier 'permissioned' references mapping variable 'permissions'
    * @param _domain domain name
    * @param _granted granted address
    * @return permission result
    */
    function getPermission(bytes32 _domain, address _granted) public view returns(bool found) {
        return permissions[_domain][_granted];
    }
    
}