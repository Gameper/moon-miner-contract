pragma solidity ^0.4.24;

/**
 * @title ITreasure
 * @dev interface for Treasure
 */
contract ITreasure {
    function mint(uint256 nonce, bytes32 challenge_digest) external returns (bool);
    function getChallengeNumber() external view returns (bytes32);
    function getMiningDifficulty() external view returns (uint);
    function getMiningTarget() external view returns (uint);
    function getMiningReward() external view returns (uint);
    function getMintDigest(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number) external view returns (bytes32);
    function checkMintSolution(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget) external view returns (bool);
}
