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
    
    uint32 private AreaWeight = 1000;
    uint256 private AreaBalance;
    uint256 private depositAmount;
    uint256 private tokenId = 10;

    uint256 public currentBeneficiaryIndex;

    mapping(address => uint256) private timelock;
    using LibCLLu for LibCLLu.CLL;

    LibCLLu.CLL holderCLL;
    address[] holderIndex;
    mapping (address => uint256) isholderIndexExists;

    constructor() public {
        thisDomain = "Area";
    }
    function initialize() public {
        // function create(string _name, string _symbol, uint8 _decimals, uint64 _amount, string _uri, bool _isNF) external onlyOwner returns(uint256 _type)
        tokenId = Treasure(registry.getAddressOf("Treasure")).create("AreaNFT", "AreaNFT", 0, 1000, true);
        // function create(string _name, string _symbolOrUri, uint8 _decimals, uint64 _amount, bool _isNF) external onlyOwner returns(uint256 _type) {
    }
    function getCurrentBeneficiaryInfo() public view returns(address beneficiary, uint256 ratio){
        Treasure treasure = Treasure(registry.getAddressOf("Treasure"));
        address bene = holderIndex[currentBeneficiaryIndex];
        return (bene, treasure.balanceOf(bene, tokenId));
    }

    function moveCursor() public returns (bool success){
        currentBeneficiaryIndex = holderCLL.step(currentBeneficiaryIndex, true);
        return true;
    }


    function buy() public payable returns (bool success){
        Treasure treasure = Treasure(registry.getAddressOf("Treasure"));
        uint256 totalSupply = treasure.totalSupply(tokenId);

        //function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) public view returns (uint256);
        uint256 mintingAmount = calculatePurchaseReturn(totalSupply, AreaBalance, AreaWeight, msg.value);
        
        // batchMint(mintingAmount, msg.sender, "Area0Security")
        // temporaily function mintNonFungible(uint256 _type, address[] _to) external creatorOnly(_type)
        address[] memory getter = new address[](1);
        getter[0] = msg.sender;
        
        for(uint256 i=0;i<mintingAmount;i++) {
            treasure.mintNonFungible(tokenId, getter);
        }

        // add holder to linked list if not exist
        if(isholderIndexExists[msg.sender] == 0){
            holderIndex.push(msg.sender);
            holderCLL.push(holderIndex.length-1, true);
        }
        
        // set time lock
        timelock[msg.sender] = now;
        
        // balance added to the contract
        AreaBalance += msg.value;
        
        return true;

    }
    function sell(uint256 _sellAmount) public returns (bool success){
        
        // sell need to be waited at least 1 hour after buy
        require(now - timelock[msg.sender] > 3600, "You should wait"); 

        Treasure treasure = Treasure(registry.getAddressOf("Treasure"));
        uint256 totalSupply = treasure.totalSupply(tokenId);

        uint256 returnAmount = calculateSaleReturn(totalSupply, AreaBalance, AreaWeight, _sellAmount);
        // batchBurn(burningAmount, msg.sender);
        
        // remove holder from linked list if token balance == 0 and move cursor if needed
        if(treasure.balanceOf(msg.sender, tokenId) == 0) {
            if(currentBeneficiaryIndex == isholderIndexExists[msg.sender]){
                moveCursor();
            }
            holderCLL.remove(isholderIndexExists[msg.sender]);
        }
        // set time lock
        timelock[msg.sender] = now;

        // send balance to the msg.sender
        msg.sender.transfer(returnAmount);

        
    }
}