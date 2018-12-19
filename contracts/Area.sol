pragma solidity ^0.4.24;

import './bancor/BancorFormula.sol';
import './RegistryUser.sol';
import './ERC1155/IERC1155.sol';
import './utils/LibCLL.sol';
import './Treasure.sol';

/**
 * @title Area
 * @dev Area
 */
contract Area is BancorFormula, RegistryUser{
    
    uint32 private AreaWeight = 10;
    uint256 private AreaBalance;
    uint256 private depositAmount;
    uint256 private tokenId = 10;

    mapping(address => uint256) private timelock;
    using LibCLLu for LibCLLu.CLL;

    LibCLLu.CLL holderCLL;
    mapping (uint256 => address) holderIndex;

    constructor() public {
        thisDomain = "Area";
        
    }
    function initialize(Treasure _addr) public {
        // function create(string _name, string _symbol, uint8 _decimals, uint64 _amount, string _uri, bool _isNF) external onlyOwner returns(uint256 _type)
        tokenId = _addr.create("AreaNFT", "AreaNFT", 0, 1000, true);
        // function create(string _name, string _symbolOrUri, uint8 _decimals, uint64 _amount, bool _isNF) external onlyOwner returns(uint256 _type) {
    }
    function getCurrentBeneficiaryInfo() public view returns(address beneficiary, uint256 ratio){
        return (0x6f0f5673d69b4608ac9be5887b2f71f20d0c3587, 10**17);
    }

    function moveCursor() public returns (bool success){
        return true;
    }


    function buy() public payable returns (bool success){
        
        uint256 totalSupply = 10; // IERC1155(registry.getAddressOf("Tresure")).balanceOf(tokenId);

        //function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) public view returns (uint256);
        uint256 mintingAmount = calculatePurchaseReturn(totalSupply, AreaBalance, AreaWeight, msg.value);
        
        AreaBalance += msg.value;
        
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