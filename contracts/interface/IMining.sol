pragma solidity ^0.4.24;

/**
 * @title ITreasure
 * @dev interface for Treasur
 */
interface IMining {
    function mint(uint256 _nonce, bytes32 _challenge_digest) external returns (bool);
    function getChallengeNumber() external view returns (bytes32);
    function getMiningDifficulty() external view returns (uint256);
    function getMiningTarget() external view returns (uint256);
    function getMiningReward() external view returns (uint256);
    function getTotalMinted() external view returns (uint256);
    function getLastMiner() external view returns (address);
    function getMintDigest(uint256 _nonce, bytes32 _challenge_digest, bytes32 _challenge_number) external view returns (bytes32);
    function getMintDigestBySha256(uint256 _nonce, bytes32 _challenge_digest, bytes32 _challenge_number) external view returns (bytes32);
    function checkMintSolution(uint256 _nonce, bytes32 _challenge_digest, bytes32 _challenge_number, uint _testTarget) external view returns (bool);
    function checkMintSolutionBySha256(uint256 _nonce, bytes32 _challenge_digest, bytes32 _challenge_number, uint _testTarget) external view returns (bool);

    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);
}
