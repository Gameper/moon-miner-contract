pragma solidity ^0.4.24;

import './bancor/BancorFormula.sol';
import './RegistryUser.sol';
import './ERC1155/IERC1155.sol';
import './utils/LibCLL.sol';
import './interface/ITreasure.sol';

/**
 * @title Area
 * @dev User can buy/sell ERC721 security token from Area contract along with the bancor alogrithm.
 * Area has the holder list in the form of the circular linked list from buy/sell operation.
 * If transfer is used from outside(token transfer), then you should let area contract know.
 * There is a time lock between buy and sell.
 * 
 */
contract Area is BancorFormula, RegistryUser{
    
    uint32 public AreaWeight = 1000000;
    uint256 public AreaBalance;
    uint256 public depositAmount;
    uint256 public tokenId = 0;

    uint256 public currentBeneficiaryIndex = 1;

    mapping(address => uint256) private timelock;
    using LibCLLu for LibCLLu.CLL;

    LibCLLu.CLL holderCLL;
    uint256 public holderNonce = 1;
    mapping (uint256 => address) internal holderIndex;
    mapping (address => uint256) internal isholderIndexExists;

    event Buy(address indexed buyer, uint256 deposit, uint256 buyTokenAmount);
    event Sell(address indexed seller, uint256 returnDepoist, uint256 sellTokenAmount);
    event Deposit(address indexed depositor, uint256 deposit);
    event Withdraw(address indexed withdrawer, uint256 withdraw);

    constructor() public {
        thisDomain = "Area";
    }


    function deposit() public payable {
        AreaBalance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _value) public onlyOwner returns (bool success) {
        AreaBalance -= _value;
        msg.sender.transfer(_value);

        emit Withdraw(msg.sender, _value);
        return true;
    }

    function getHolderIndex(uint256 _index) public view returns(address holder) {
        return holderIndex[_index];
    }

    function getIsHolderIndexExists(address _addr) public view returns(uint256 index) {
        return isholderIndexExists[_addr];
    }

    function getNode(uint256 _n) public view returns(uint256[2]){
        return holderCLL.getNode(_n);
    }

    /**
     * @dev Initialize Area. Create Area Security token type on the Treasure(ERC1155).
     * @return A boolean that indicates if the operation was successful.
     */
    function initialize() /* internal */ public {
        // function create(string _name, string _symbol, uint8 _decimals, uint64 _amount, string _uri, bool _isNF) external onlyOwner returns(uint256 _type)
        ITreasure treasure = ITreasure(registry.getAddressOf("Treasure"));
        tokenId = treasure.create("Area0", "Area", 0, 1000, true);
        // function create(string _name, string _symbolOrUri, uint8 _decimals, uint64 _amount, bool _isNF) external onlyOwner returns(uint256 _type) {
    }

    /**
     * @dev You can get the current beneficary info. ratio will be determined by the precise equation after mvp.
     * @return beneficiary and ratio.
     */
    function getCurrentBeneficiaryInfo() public view returns(address beneficiary, uint256 ratio){
        ITreasure treasure = ITreasure(registry.getAddressOf("Treasure"));
        address bene = holderIndex[currentBeneficiaryIndex];
        return (bene, treasure.balanceOf(bene, tokenId));
    }

    //TODO : PUBLIC should be PERMISSIONED after mvp
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

    function addHolder(address _holder) public /* internal */{
        if(isholderIndexExists[_holder] == 0){
            // pointer add
            holderIndex[holderNonce] = _holder;
            isholderIndexExists[_holder] = holderNonce;

            // push
            holderCLL.push(holderNonce, false);

            if(holderIndex[currentBeneficiaryIndex] == address(0)) {
                currentBeneficiaryIndex = holderNonce;
            }
            
            holderNonce++;
        }
    }

    function removeHolder(address _holder) public /* internal */ {
        // remove holder from linked list if token balance == 0 and move cursor if needed
        
        if(currentBeneficiaryIndex == isholderIndexExists[_holder]){
            moveCursor();
        }

        holderCLL.remove(isholderIndexExists[_holder]);
        uint256 index = isholderIndexExists[_holder];
        delete isholderIndexExists[_holder];
        delete holderIndex[index];

    }

    /**
    * @dev Buy security token. The amount of the ERC 721 token is determined by bancor, 
    * using ether value(connector token or msg.value)
    * @return A boolean that indicates if the operation was successful.
    */
    function buy() public payable returns (bool success){
        ITreasure treasure = ITreasure(registry.getAddressOf("Treasure"));
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
        
        emit Buy(msg.sender, msg.value, mintingAmount);
        
        return true;

    }

    /**
     * @dev Buy security tokens with ether at least {_minReturn}. Currently, contract do not return rest of the ether.
     * @param _minReturn expected miniumReturn by user
     * @return A boolean that indicates if the operation was successful.
     */
    function buyWithMinimum(uint256 _minReturn) public payable returns (bool success) {
        ITreasure treasure = ITreasure(registry.getAddressOf("Treasure"));
        uint256 totalSupply = treasure.totalSupply(tokenId);

        //function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) public view returns (uint256);
        uint256 mintingAmount = calculatePurchaseReturn(totalSupply, AreaBalance, AreaWeight, msg.value);
        
        require(mintingAmount >= _minReturn, "not expected return amount");
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
        
        emit Buy(msg.sender, msg.value, mintingAmount);
        
        return true;

    }

    /**
     * @dev Sell tokens. User gets ether.
     * @param _sellAmount sell token amount
     * @return A boolean that indicates if the operation was successful.
     */
    function sell(uint256 _sellAmount) public returns (bool success){
        
        // sell need to be waited at least 1 hour after buy
        // require(now - timelock[msg.sender] > 3600, "You should wait"); 

        ITreasure treasure = ITreasure(registry.getAddressOf("Treasure"));
        uint256 totalSupply = treasure.totalSupply(tokenId);

        uint256 returnAmount = calculateSaleReturn(totalSupply, AreaBalance, AreaWeight, _sellAmount);
        
        // // batchBurn(burningAmount, msg.sender);
        for(uint256 i=0;i<_sellAmount;i++) {
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

        emit Sell(msg.sender, returnAmount, _sellAmount);
        
    }

    function getExpectedPurchasePrice(uint256 amount) public view returns (uint256) {
        ITreasure treasure = ITreasure(registry.getAddressOf("Treasure"));
        uint256 totalSupply = treasure.totalSupply(tokenId);
        return calculatePurchaseReturn(totalSupply, AreaBalance, AreaWeight, amount);
    }

    function getExpectedSellPrice(uint256 amount) public view returns (uint256) {
        ITreasure treasure = ITreasure(registry.getAddressOf("Treasure"));
        uint256 totalSupply = treasure.totalSupply(tokenId);
        return calculateSaleReturn(totalSupply, AreaBalance, AreaWeight, amount);
    }
}