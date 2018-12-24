pragma solidity ^0.4.0;

interface ITreasure {
    function create(string _name, string _symbolOrUri, uint8 _decimals, uint64 _amount, bool _isNF) public returns(uint256 _id);
    function detectResource(uint256 _id, address _detector, uint256 _amount) external returns (bool);
    function mintNonFungible(uint256 _id, address[] _to) external;
    function totalSupply(uint256 _id) external view returns (uint256);
    function name(uint256 _id) external view returns (string);
    function symbolOrUri(uint256 _id) external view returns (string);
    function decimals(uint256 _id) external view returns (uint8);
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function burnNonFungible(uint256 _id, address _to) external;
}
