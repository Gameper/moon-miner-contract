pragma solidity ^0.4.24;

import "./ERC1155/ERC1155MixedFungible.sol";
import "./interface/IArea.sol";
import "./RegistryUser.sol";

/**
 * @title Treasure
 * @dev Treasure Contract
 */
contract Treasure is ERC1155MixedFungible, RegistryUser {

    using SafeMath for uint256;

    struct Resource {
        address creator;
        string name;
        string symbolOrUri;
        uint8 decimals;
        uint256 totalSupply;
        address area;
    }

    uint256 nonce;
    mapping (uint256 => Resource) public resources;
    mapping (uint256 => address) public creators;
    mapping (uint256 => uint256) public maxIndex;
    mapping (uint256 => mapping (address => uint256[])) public nfList; // id => address => NFTlist

    modifier creatorOnly(uint256 _id) {
        require(creators[_id] == msg.sender);
        _;
    }
    constructor() public {
        thisDomain = "Treasure";
    }
    function create(string _name, string _symbolOrUri, uint8 _decimals, uint64 _amount, bool _isNF) public returns(uint256 _id) {

        // Store the type in the upper 128 bits
        _id = (++nonce << 128);

        // Set a flag if this is an NFI.
        if (_isNF)
            _id = _id | TYPE_NF_BIT;

        // This will allow restricted access to creators.
        creators[_id] = msg.sender;

        Resource storage resource = resources[_id];

        resource.creator = msg.sender;
        resource.name = _name;
        resource.symbolOrUri = _symbolOrUri;

        if(_isNF) {
            resource.decimals = 0;
            resource.totalSupply = _amount;
        } else {
            resource.decimals = _decimals;
            resource.totalSupply = _amount * 10 ** uint(_decimals);
            balances[_id][msg.sender] = resource.totalSupply;
        }

        emit TransferSingle(msg.sender, 0x0, 0x0, _id, resource.totalSupply);

        if (bytes(_name).length > 0)
            emit Name(_name, _id);

        if (bytes(_symbolOrUri).length > 0)
            emit URI(_symbolOrUri, _id);
        
        if (keccak256(_symbolOrUri) == keccak256("Area")){
            resource.area = msg.sender;
        }
    }

    function detectResource(uint256 _id, address _detector, uint256 _amount) public creatorOnly(_id) returns (bool) {
        require(isFungible(_id));
        require(_amount <= balances[_id][msg.sender]);
        require(_detector != address(0));
        balances[_id][msg.sender] = balances[_id][msg.sender].sub(_amount);
        balances[_id][_detector] = balances[_id][_detector].add(_amount);
        return true;
    }

    function mintNonFungible(uint256 _id, address[] _to) external creatorOnly(_id) {

        // No need to check this is a nf type rather than an id since
        // creatorOnly() will only let a type pass through.
        require(isNonFungible(_id));

        // Index are 1-based.
        uint256 index = maxIndex[_id] + 1;

        for (uint256 i = 0; i < _to.length; ++i) {
            address dst = _to[i];
            uint256 id  = _id | index + i;

            nfOwners[id] = dst;
            
            nfList[_id][_to[i]].push(id);
            
            // You could use base-type id to store NF type balances if you wish.
            // balances[_type][dst] = quantity.add(balances[_type][dst]);

            emit TransferSingle(msg.sender, 0x0, dst, id, 1);

            if (dst.isContract()) {
                require(IERC1155TokenReceiver(dst).onERC1155Received(msg.sender, msg.sender, id, 1, '') == ERC1155_RECEIVED);
            }
        }

        maxIndex[_id] = _to.length.add(maxIndex[_id]);
        resources[_id].totalSupply = _to.length.add(resources[_id].totalSupply);
    }

    function burnNonFungible(uint256 _id, address _to) external creatorOnly(_id) {
        // _id = only NFT base id
        // burn erc721 from last
        require(nfList[_id][_to].length > 0, "not enough balance");

        uint256 id = nfList[_id][_to][nfList[_id][_to].length-1];
        nfOwners[id] = address(0); // delete nfOwners[id];

        nfList[_id][_to].length = nfList[_id][_to].length - 1;
        resources[_id].totalSupply--;
    }

    // overide
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes _data) external {

        require(_to != 0);
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        if (isNonFungible(_id)) {
            require(nfOwners[_id] == _from);
            nfOwners[_id] = _to;
            
            // uint256 id = _id & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000;
            uint256 id = getNonFungibleBaseType(_id);
            for(uint256 i=0;i<nfList[id][_from].length;i++){
                if(nfList[id][_from][i] == _id) {
                    nfList[id][_from][i] = nfList[id][_from][nfList[id][_from].length-1];
                    nfList[id][_from].length = nfList[id][_from].length - 1;
                    break;
                }
            }
            
            // Area Token should change the beneficiary list
            if(resources[id].area != address(0)) {
                IArea area = IArea(resources[id].area);
                area.modifyHolderAfterTrasnfer(_from, nfList[id][_from].length, _to, nfList[id][_to].length);
            }

        } else {
            balances[_id][_from] = balances[_id][_from].sub(_value);
            balances[_id][_to]   = balances[_id][_to].add(_value);
        }

        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        if (_to.isContract()) {
            require(IERC1155TokenReceiver(_to).onERC1155Received(msg.sender, _from, _id, _value, _data) == ERC1155_RECEIVED);
        }
    }

    // overide
    function safeBatchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values, bytes _data) external {

        require(_to != 0, "cannot send to zero address");
        require(_ids.length == _values.length, "Array length must match");

        // Only supporting a global operator approval allows us to do only 1 check and not to touch storage to handle allowances.
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        for (uint256 i = 0; i < _ids.length; ++i) {
            // Cache value to local variable to reduce read costs.
            uint256 id = _ids[i];
            uint256 value = _values[i];

            if (isNonFungible(id)) {
                revert("Batch Transfer for Non-Fungible not provided");
                require(nfOwners[id] == _from);
                nfOwners[id] = _to;
            } else {
                balances[id][_from] = balances[id][_from].sub(value);
                balances[id][_to]   = value.add(balances[id][_to]);
            }
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        if (_to.isContract()) {
            require(IERC1155TokenReceiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _values, _data) == ERC1155_RECEIVED);
        }
    }

    function balanceOf(address _owner, uint256 _id) external view returns (uint256) {
        if (isNonFungibleItem(_id))
            return nfList[_id][_owner].length;
        return balances[_id][_owner];
    }

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return resources[_id].totalSupply;
    }

    /**
     * @return the name of the token.
     */
    function name(uint256 _id) public view returns (string) {
        return resources[_id].name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbolOrUri(uint256 _id) public view returns (string) {
        return resources[_id].symbolOrUri;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals(uint256 _id) public view returns (uint8) {
        return resources[_id].decimals;
    }
}
