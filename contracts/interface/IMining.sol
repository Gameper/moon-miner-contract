pragma solidity ^0.4.24;

/**
 * @title ITreasure
 * @dev interface for Treasur
 */
contract IMining {
    function mine(uint256 nonce, bytes32 challenge_digest) external returns (bool);
    function getChallengeNumber(uint256 id) external view returns (bytes32);
    function getMiningDifficulty(uint256 id) external view returns (uint);
    function getMiningTarget(uint256 id) external view returns (uint);
    function getMiningReward(uint256 id) external view returns (uint);
    function getMintDigest(uint256 id, uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number) external view returns (bytes32);
    function checkMintSolution(uint256 id, uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget) external view returns (bool);

    event Mine(address indexed from, uint256 id, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);
}
