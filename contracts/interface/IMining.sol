pragma solidity ^0.4.24;

/**
 * @title ITreasure
 * @dev interface for Treasur
 */
interface IMining {
    function mine(uint256 _id, uint256 _nonce, bytes32 _challenge_digest) external returns (bool);
    function getChallengeNumber(uint256 _id) external view returns (bytes32);
    function getMiningDifficulty(uint256 _id) external view returns (uint256);
    function getMiningTarget(uint256 _id) external view returns (uint256);
    function getMiningReward(uint256 _id) external view returns (uint256);
    function getMiningDigestByKeccak256(uint256 _id, uint256 _nonce, bytes32 _challenge_digest, bytes32 _challenge_number) external view returns (bytes32);
    function getMiningDigestBySha256(uint256 _id, uint256 _nonce, bytes32 _challenge_digest, bytes32 _challenge_number) external view returns (bytes32);
    function checkMiningSolutionByKeccak256(uint256 _id, uint256 _nonce, bytes32 _challenge_digest, bytes32 _challenge_number, uint _testTarget) external view returns (bool);
    function checkMiningSolutionBySha256(uint256 _id, uint256 _nonce, bytes32 _challenge_digest, bytes32 _challenge_number, uint _testTarget) external view returns (bool);

    event Mine(address indexed from, uint256 _id, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);
}
