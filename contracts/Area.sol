pragma solidity ^0.4.24;

import './bancor/BancorFormula.sol';
import './RegistryUser.sol';
import './ERC1155/IERC1155.sol';
import './utils/LibCLL.sol';
import './Treasure.sol';
import './interface/ITreasure.sol';

/**
 * @title Area
 * @dev Area
 */
contract Area is BancorFormula, RegistryUser{
    
    uint32 public AreaWeight = 1000000;
    uint256 public AreaBalance;
    uint256 public depositAmount;
    uint256 public tokenId = 0;

    uint256 public currentBeneficiaryIndex;

    mapping(address => uint256) private timelock;
    using LibCLLu for LibCLLu.CLL;

    LibCLLu.CLL holderCLL;
    uint256 holderNonce = 1;
    mapping (uint256 => address) internal holderIndex;
    mapping (address => uint256) internal isholderIndexExists;

    constructor() public {
        thisDomain = "Area";
    }

    function deposit() public payable {
        AreaBalance += msg.value;
    }
    function getHolderIndex(uint256 _index) public view returns(address holder) {
        return holderIndex[_index];
    }

    function getIsholderIndexExists(address _addr) public view returns(uint256 index) {
        return isholderIndexExists[_addr];
    }

    function getNode(uint256 _n) public view returns(uint256[2]){
        return holderCLL.getNode(_n);
    }

    function initialize() public {
        // function create(string _name, string _symbol, uint8 _decimals, uint64 _amount, string _uri, bool _isNF) external onlyOwner returns(uint256 _type)
        ITreasure treasure = ITreasure(registry.getAddressOf("Treasure"));
        tokenId = treasure.create("Area0", "Area", 0, 1000, true);
        // function create(string _name, string _symbolOrUri, uint8 _decimals, uint64 _amount, bool _isNF) external onlyOwner returns(uint256 _type) {
    }
    function getCurrentBeneficiaryInfo() public view returns(address beneficiary, uint256 ratio){
        Treasure treasure = Treasure(registry.getAddressOf("Treasure"));
        address bene = holderIndex[currentBeneficiaryIndex];
        return (bene, treasure.balanceOf(bene, tokenId));
    }

    function moveCursor() public returns (bool success){
        currentBeneficiaryIndex = holderCLL.step(currentBeneficiaryIndex, false);
        return true;
    }

    function modifyHolderAfterTrasnfer(address _from, uint256 _fromBalance, address _to, uint256 _toBalance) public permissioned returns (bool){
        
        //_to has at least 1 NFT
        addHolder(_to);

        if(_fromBalance == 0) {
            removeHolder(_from);
        }
    }

    function addHolder(address _holder) internal {
        if(isholderIndexExists[msg.sender] == 0){
            // pointer add
            holderIndex[holderNonce] = msg.sender;
            isholderIndexExists[msg.sender] = holderNonce;

            // push
            holderCLL.push(holderNonce, false);
            
            holderNonce++;
        }
    }

    function removeHolder(address _holder) internal {
        // remove holder from linked list if token balance == 0 and move cursor if needed
        
        if(currentBeneficiaryIndex == isholderIndexExists[msg.sender]){
            moveCursor();
        }

        holderCLL.remove(isholderIndexExists[msg.sender]);
        uint256 index = isholderIndexExists[msg.sender];
        delete isholderIndexExists[msg.sender];
        delete holderIndex[index];

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
        addHolder(msg.sender);
        
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
        for(uint256 i=0;i<returnAmount;i++) {
            treasure.burnNonFungible(tokenId, msg.sender);
        }
        // remove holder if balance == 0
        if(treasure.balanceOf(msg.sender, tokenId) == 0) {
            removeHolder(msg.sender);
        }

        // set time lock
        timelock[msg.sender] = now;

        // send balance to the msg.sender
        msg.sender.transfer(returnAmount);

        
    }
}