pragma solidity ^0.4.24;

import "./openzeppelin-solidity/contracts/math/Math.sol";
//import "./openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./interface/IMining.sol";
import "./RegistryUser.sol";
import "./Treasure.sol";

contract Mining is IMining {
//    using SafeMath for uint256;
    using Math for uint256;

    mapping (uint256 => Treasure) resources;

    constructor() public {

    }

    function() public payable {
        revert();
    }

    function createResource() public {

    }

//    function mine(uint256 nonce, bytes32 challenge_digest) public returns (bool) {
//
//    }
//
//    function getChallengeNumber(uint256 id) public view returns (bytes32) {
//
//    }
//
//    function getMiningDifficulty(uint256 id) public view returns (uint) {
//
//    }
//
//    function getMiningTarget(uint256 id) public view returns (uint) {
//
//    }
//
//    function getMiningReward(uint256 id) public view returns (uint) {
//
//    }
//
//    function getMintDigest(uint256 id, uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number) public view returns (bytes32) {
//
//    }
//
//    function checkMintSolution(uint256 id, uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget) public view returns (bool) {
//
//    }

}

