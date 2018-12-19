pragma solidity ^0.4.24;

import "./ERC1155/ERC1155MixedFungible.sol";
import "./openzeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * @title Treasure
 * @dev Treasure Contract
 */
contract Treasure is ERC1155MixedFungible, Ownable {

    using SafeMath for uint256;

    struct Resource {
        address creator;
        string name;
        string symbolOrUri;
        uint8 decimals;
        uint256 totalSupply;
    }


    address public miningContract;

    uint256 nonce;
    mapping(uint256 => Resource) public resources;
    mapping (uint256 => address) public creators;
    mapping (uint256 => uint256) public maxIndex;

    modifier creatorOnly(uint256 _id) {
        require(creators[_id] == msg.sender);
        _;
    }

    modifier onlyMiningContract {
        require(msg.sender == miningContract);
        _;
    }

    function setMiningContract(address _miningContract) external onlyOwner {
        miningContract = _miningContract;
    }

    function create(string _name, string _symbolOrUri, uint8 _decimals, uint64 _amount, bool _isNF) external returns(uint256 _type) {

        // Store the type in the upper 128 bits
        _type = (++nonce << 128);

        // Set a flag if this is an NFI.
        if (_isNF)
            _type = _type | TYPE_NF_BIT;

        // This will allow restricted access to creators.
        creators[_type] = msg.sender;

        Resource storage resource = resources[_type];

        resource.creator = msg.sender;
        resource.name = _name;
        resource.symbolOrUri = _symbolOrUri;

        if(_isNF) {
            resource.decimals = 0;
            resource.totalSupply = _amount;
        } else {
            resource.decimals = _decimals;
            resource.totalSupply = _amount * 10 ** uint(_decimals);
        }

        emit TransferSingle(msg.sender, 0x0, 0x0, _type, resource.totalSupply);

        if (bytes(_name).length > 0)
            emit Name(_name, _type);

        if (bytes(_symbolOrUri).length > 0)
            emit URI(_symbolOrUri, _type);
    }

//    function mintFungible(uint256 _id, address[] _to, uint256[] _quantities) external creatorOnly(_id) {
//        revert();
//    }

    function detectResource(uint256 _id, address _detector, uint256 _amount) public onlyMiningContract returns (bool) {
        require(isFungible(_id));
        balances[_id][_detector] = balances[_id][_detector].add(_amount);
        return true;
    }

    function mintNonFungible(uint256 _type, address[] _to) external creatorOnly(_type) {

        // No need to check this is a nf type rather than an id since
        // creatorOnly() will only let a type pass through.
        require(isNonFungible(_type));

        // Index are 1-based.
        uint256 index = maxIndex[_type] + 1;

        for (uint256 i = 0; i < _to.length; ++i) {
            address dst = _to[i];
            uint256 id  = _type | index + i;

            nfOwners[id] = dst;

            // You could use base-type id to store NF type balances if you wish.
            // balances[_type][dst] = quantity.add(balances[_type][dst]);

            emit TransferSingle(msg.sender, 0x0, dst, id, 1);

            if (dst.isContract()) {
                require(IERC1155TokenReceiver(dst).onERC1155Received(msg.sender, msg.sender, id, 1, '') == ERC1155_RECEIVED);
            }
        }

        maxIndex[_type] = _to.length.add(maxIndex[_type]);
    }

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply(uint256 id) public view returns (uint256) {
        return resources[id].totalSupply;
    }

    /**
     * @return the name of the token.
     */
    function name(uint256 id) public view returns (string) {
        return resources[id].name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbolOrUri(uint256 id) public view returns (string) {
        return resources[id].symbolOrUri;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals(uint256 id) public view returns (uint8) {
        return resources[id].decimals;
    }
}
