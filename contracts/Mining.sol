pragma solidity ^0.4.24;

import "./openzeppelin-solidity/contracts/math/Math.sol";
import "./openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./interface/ITreasure.sol";
import "./interface/IMining.sol";
import "./interface/IArea.sol";
import "./RegistryUser.sol";

contract Mining is IMining, RegistryUser {
    using SafeMath for uint256;
    using Math for uint256;

    uint256 public tokenId;
    uint256 public _BLOCKS_PER_READJUSTMENT;
    uint256 public initialReward;
    uint256 public epochCount;
    uint256 public latestDifficultyPeriodStarted;
    uint256 public miningTarget;
    uint256 public tokensMinted; // 현재 채굴된 총량
    bytes32 public challengeNumber; // 새로운 reward 가 minting 되면 새로운 challenge number 생성 ( recent ethereum block hash)
    uint256 public rewardEra; // 반감기 주기 기간
    uint256 public maxSupplyForEra; // 기간 내 최대 줄 수 있는 토큰량

    // 마지막 reward 관련
    address lastRewardTo;
    uint256 lastRewardAmount;
    uint256 lastRewardEthBlockNumber;

    mapping(bytes32 => bytes32) public solutionForChallenge;
    //    bool public locked;

    // a little & big number (target)
    uint256 public constant _MINIMUM_TARGET = 2 ** 16;
    uint256 public constant _MAXIMUM_TARGET = 2 ** 234;

    constructor() public {
        thisDomain = "Mining";
    }

    function() public payable {
        revert();
    }

    function createResource(string _name, string _symbol, uint8 _decimals, uint64 _amount) public /*permissioned*/ {
        ITreasure treasure = ITreasure(registry.getAddressOf("Treasure"));
        uint id = treasure.create(_name, _symbol, _decimals, _amount, false);
        uint256 totalSupply = _amount * 10 ** uint(_decimals);
        tokenId = id;
        //        locked = true;

        // initialize miningInfo
        _BLOCKS_PER_READJUSTMENT = 1024;
        initialReward = 50;
        epochCount = 1;
        latestDifficultyPeriodStarted = block.number;
        miningTarget = _MAXIMUM_TARGET;
        tokensMinted = 0;
        challengeNumber = blockhash(block.number - 1);
        rewardEra = 0;
        maxSupplyForEra = totalSupply - totalSupply.div(2 ** (rewardEra + 1));
    }

    function mint(uint256 _nonce, bytes32 _challenge_digest) public returns (bool) {
        ITreasure treasure = ITreasure(registry.getAddressOf("Treasure"));
        IArea area = IArea(registry.getAddressOf("Area"));

        // check miningSolution
        checkMintSolution(_nonce, _challenge_digest, challengeNumber, miningTarget);

        // solution have to be unique
        require(solutionForChallenge[challengeNumber] == 0x0, "this challenge number has solution ");
        solutionForChallenge[challengeNumber] = _challenge_digest;

        // check total amount during era
        uint256 miningReward = getMiningReward();
        tokensMinted = tokensMinted.add(miningReward);
        require(tokensMinted <= maxSupplyForEra, "total amount of token in this era is already minted");

        // divide treasure between miner & holder
        address holder;
        uint256 ratio;
        (holder, ratio) = area.getCurrentBeneficiaryInfo();
        uint256 holderTreasureAmount;
        ratio == 0 ? holderTreasureAmount = 0 : holderTreasureAmount = miningReward.div(5).div(uint256(1000).div(ratio));
        //        uint256 minerTreasureAmount = minedTreasureAmount.sub(holderTreasureAmount);

        // send treasure
        if (holder != address(0)) treasure.detectResource(tokenId, holder, holderTreasureAmount);
        treasure.detectResource(tokenId, msg.sender, miningReward.sub(holderTreasureAmount));

        // update last Reward info
        lastRewardTo = msg.sender;
        lastRewardAmount = miningReward;
        lastRewardEthBlockNumber = block.number;

        // start new epoch
        uint256 totalSupply = treasure.totalSupply(tokenId);
        _startNewMiningEpoch(miningReward, totalSupply);

        // announce mining
        emit Mint(msg.sender, miningReward, epochCount, challengeNumber);

        // request move cursor
        area.moveCursor();

        return true;
    }

    function _startNewMiningEpoch(uint256 _miningReward, uint _totalSupply) private {

        //  mint 된 총 량은 그 기간안에서 줄 수 있는 최대량보다 작아야 하며
        // 40 번째 주기에서는 거의 토큰이 없으므로 이를 체크하여 rewardEra (기간) 를 결정한다.
        if (tokensMinted.add(_miningReward) > maxSupplyForEra && rewardEra < 39) {
            rewardEra = rewardEra + 1;

            // max supply 를 계산한다.
            maxSupplyForEra = _totalSupply - _totalSupply.div(2 ** (rewardEra + 1));
        }

        // epoch count 를 증가 시킨다.
        epochCount = epochCount.add(1);

        // epochCount 가 난이도 조절해야 하는 count 에 도달하면 체크한다.
        if (epochCount % _BLOCKS_PER_READJUSTMENT == 0) {
            _reAdjustDifficulty();
        }

        // 최근 이더리움 block hash 를 challengeNumber 에 넣는다.
        challengeNumber = blockhash(block.number - 1);

    }

    function _reAdjustDifficulty() private {

        // 난이도 조절 기간에 다다를 때, 그 사이에 얼마나 많은 block number 수가 있었는지 확인 (보통 한시간에 360 블럭이 있다(3600s / 10s))
        uint256 ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;

        // 이 토큰이 원하는 만큼의 block 수를 정의 (예측)
        // btc 는 10 분에 하나의 블록이 생성되는데 이더리움은 60 블록이 생성되므로 60 을 곱해준다.(비트코인은 1024 블락이지만 이더리움에서는 60을 곱한 블락 수만큼 생기기 때문)
        uint256 epochsMined = _BLOCKS_PER_READJUSTMENT;
        uint256 targetEthBlocksPerDiffPeriod = epochsMined * 60;

        // 실제 block 수가 작다는 것은 사람들이 빠르게 마이닝 했다는 소리이므로
        // 실제 block 수가 예측한 block 수보다 작다면 난이도를 높힌다. (아니라면 난이도를 낮춘다.)
        if (ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod) {
            uint256 excess_block_pct = (targetEthBlocksPerDiffPeriod.mul(100)).div(ethBlocksSinceLastDifficultyPeriod);
            uint256 excess_block_pct_extra = excess_block_pct.sub(100).min(1000);

            // 난이도를 높힌다(mining target 을 낮춘다)
            miningTarget = miningTarget.sub(miningTarget.div(2000).mul(excess_block_pct_extra));

        } else {
            uint256 shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod.mul(100)).div(targetEthBlocksPerDiffPeriod);
            uint256 shortage_block_pct_extra = shortage_block_pct.sub(100).min(1000);

            // 난이도를 낮춘다(mining target 을 높힌다)
            miningTarget = miningTarget.add(miningTarget.div(2000).mul(shortage_block_pct_extra));

        }

        // 다음 번 난이도 조절을 위한 starting block number 설정
        latestDifficultyPeriodStarted = block.number;


        // 만약 설정한 max/min 난이도를 벗어난다면 조절
        if (miningTarget < _MINIMUM_TARGET) {
            miningTarget = _MINIMUM_TARGET;
        }

        if (miningTarget > _MAXIMUM_TARGET) {
            miningTarget = _MAXIMUM_TARGET;
        }
    }

    function getChallengeNumber() public view returns (bytes32) {
        return challengeNumber;
    }

    function getMiningDifficulty() public view returns (uint256) {
        return _MAXIMUM_TARGET.div(miningTarget);
    }

    function getMiningTarget() public view returns (uint256) {
        return miningTarget;
    }

    function getTotalMinted() public view returns (uint256) {
        return tokensMinted;
    }

    function getLastMiner() public view returns (address) {
        return lastRewardTo;
    }

    function getMiningReward() public view returns (uint256) {
        ITreasure treasure = ITreasure(registry.getAddressOf("Treasure"));
        uint8 decimals = treasure.decimals(tokenId);
        return (initialReward * 10 ** uint(decimals)).div(2 ** rewardEra);
    }

    function getMintDigest(uint256 _nonce, bytes32 _challenge_digest, bytes32 _challenge_number) public view returns (bytes32) {
        bytes32 digest = keccak256(abi.encodePacked(_challenge_number, msg.sender, _nonce));
        return digest;
    }

    function getMintDigestBySha256(uint256 _nonce, bytes32 _challenge_digest, bytes32 _challenge_number) public view returns (bytes32) {
        bytes32 digest = sha256(abi.encodePacked(_challenge_number, msg.sender, _nonce));
        return digest;
    }

    function checkMintSolutionByKeccak256(uint256 _nonce, bytes32 _challenge_digest, bytes32 _challenge_number, uint _testTarget) public view returns (bool) {
        bytes32 digest = getMintDigest(_nonce, _challenge_digest, _challenge_number);
        require(uint256(digest) < _testTarget, "this solution can not pass the mining target");
        return (digest == _challenge_digest);
    }

    function checkMintSolutionBySha256(uint256 _nonce, bytes32 _challenge_digest, bytes32 _challenge_number, uint _testTarget) public view returns (bool) {
        bytes32 digest = getMintDigestBySha256(_nonce, _challenge_digest, _challenge_number);
        require(uint256(digest) < _testTarget, "this solution can not pass the mining target");
        return (digest == _challenge_digest);
    }

    function checkMintSolution(uint256 _nonce, bytes32 _challenge_digest, bytes32 _challenge_number, uint _testTarget) public view returns (bool) {
        // check digest
        bytes32 digestByKeccak256 = getMintDigest(_nonce, _challenge_digest, _challenge_number);
        bytes32 digestBySha256 = getMintDigestBySha256(_nonce, _challenge_digest, _challenge_number);
        require(_challenge_digest == digestByKeccak256 || _challenge_digest == digestBySha256, "hash result is not correct");

        // check difficulty
        // require(uint256(_challenge_digest) < _testTarget, "this solution can not pass the mining target");

        return true;
    }
}

