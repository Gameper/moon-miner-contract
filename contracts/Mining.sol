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

    struct MiningInfo {
        uint256 blocksPerReAdjustment;
        uint8 initialReward;
        uint256 epochCount;
        uint256 latestDifficultyPeriodStarted;
        uint256 miningTarget;
        uint256 totalTreasureMined; // 현재 채굴된 총량
        bytes32 challengeNumber; // 새로운 reward 가 minting 되면 새로운 challenge number 생성 ( recent ethereum block hash)
        uint256 rewardEra; // 반감기 주기 기간
        uint256 maxSupplyForEra; // 기간 내 최대 줄 수 있는 토큰량

        // 마지막 reward 관련
        address lastRewardTo;
        uint256 lastRewardAmount;
        uint256 lastRewardEthBlockNumber;
    }

    mapping(uint256 => MiningInfo) public miningInfos;
    mapping(uint256 => mapping(bytes32 => bytes32)) public solutionForChallenge;
//    mapping(uint256 => bool) public locked;

    // a little & big number (target)
    uint256 public constant _MINIMUM_TARGET = 2 ** 16;
    uint256 public constant _MAXIMUM_TARGET = 2 ** 234;

    constructor() public {
        thisDomain = "Mining";
    }

    function() public payable {
        revert();
    }

    function createResource(string _name, string _symbol, uint8 _decimals, uint64 _amount) public permissioned {
        ITreasure treasure = ITreasure(registry.getAddressOf("Treasure"));
        uint id = treasure.create(_name, _symbol, _decimals, _amount, false);
        uint256 totalSupply = _amount * 10 ** uint(_decimals);
//        locked[id] = true;

        MiningInfo storage miningInfo = miningInfos[id];

        // initialize miningInfo
        miningInfo.blocksPerReAdjustment = 1024;
        miningInfo.epochCount = 1;
        miningInfo.latestDifficultyPeriodStarted = block.number;
        miningInfo.miningTarget = _MAXIMUM_TARGET;
        miningInfo.totalTreasureMined = 0;
        miningInfo.challengeNumber = blockhash(block.number - 1);
        miningInfo.rewardEra = 0;
        miningInfo.initialReward = 50;
        miningInfo.maxSupplyForEra = totalSupply - totalSupply.div(2 ** (miningInfo.rewardEra + 1));
    }

    function mine(uint256 _id, uint256 _nonce, bytes32 _challenge_digest) public returns (bool) {
        ITreasure treasure = ITreasure(registry.getAddressOf("Treasure"));
        IArea area = IArea(registry.getAddressOf("Area"));
        MiningInfo storage miningInfo = miningInfos[_id];

        // check miningSolution
        checkMiningSolutionAll(_id, _nonce, _challenge_digest, miningInfo.challengeNumber, miningInfo.miningTarget);

        // solution have to be unique
        require(solutionForChallenge[_id][miningInfo.challengeNumber] == 0x0);
        solutionForChallenge[_id][miningInfo.challengeNumber] = _challenge_digest;

        // check total amount during era
        uint256 minedTreasureAmount = getMiningReward(_id);
        uint256 totalTreasureMined = minedTreasureAmount.add(miningInfo.totalTreasureMined);
        require(totalTreasureMined <= miningInfo.maxSupplyForEra);

        // divide treasure between miner & holder
        address memory holder;
        uint256 ratio;
        (holder, ratio) = area.getCurrentBeneficiaryInfo();
        uint256 holderTreasureAmount = minedTreasureAmount.div(5).div(uint256(10**18).div(ratio));
//        uint256 minerTreasureAmount = minedTreasureAmount.sub(holderTreasureAmount);

        // send treasure
        treasure.detectResource(_id, holder, holderTreasureAmount);
        treasure.detectResource(_id, msg.sender, minedTreasureAmount.sub(holderTreasureAmount));

        // update info
        miningInfo.totalTreasureMined = totalTreasureMined;
        miningInfo.lastRewardTo = msg.sender;
        miningInfo.lastRewardAmount = minedTreasureAmount;
        miningInfo.lastRewardEthBlockNumber = block.number;

        // start new epoch
        _startNewMiningEpoch(miningInfo, minedTreasureAmount, treasure.totalSupply(_id));

        // announce mining
        emit Mine(msg.sender, _id, minedTreasureAmount, miningInfo.epochCount, miningInfo.challengeNumber);

        // request move cursor
        area.moveCursor();

        return true;
    }

    function _startNewMiningEpoch(MiningInfo storage _miningInfo, uint256 _minedTreasure, uint _totalSupply) private {

        //  mint 된 총 량은 그 기간안에서 줄 수 있는 최대량보다 작아야 하며
        // 40 번째 주기에서는 거의 토큰이 없으므로 이를 체크하여 rewardEra (기간) 를 결정한다.
        if (_miningInfo.totalTreasureMined.add(_minedTreasure) > _miningInfo.maxSupplyForEra && _miningInfo.rewardEra < 39) {
            _miningInfo.rewardEra = _miningInfo.rewardEra + 1;

            // max supply 를 계산한다.
            _miningInfo.maxSupplyForEra = _totalSupply - _totalSupply.div(2 ** (_miningInfo.rewardEra + 1));
        }

        // epoch count 를 증가 시킨다.
        _miningInfo.epochCount = _miningInfo.epochCount.add(1);

        // epochCount 가 난이도 조절해야 하는 count 에 도달하면 체크한다.
        if (_miningInfo.epochCount % _miningInfo.blocksPerReAdjustment == 0) {
            _reAdjustDifficulty(_miningInfo);
        }

        // 최근 이더리움 block hash 를 challengeNumber 에 넣는다.
        _miningInfo.challengeNumber = blockhash(block.number - 1);

    }

    function _reAdjustDifficulty(MiningInfo storage _miningInfo) private {

        // 난이도 조절 기간에 다다를 때, 그 사이에 얼마나 많은 block number 수가 있었는지 확인 (보통 한시간에 360 블럭이 있다(3600s / 10s))
        uint256 ethBlocksSinceLastDifficultyPeriod = block.number - _miningInfo.latestDifficultyPeriodStarted;

        // 이 토큰이 원하는 만큼의 block 수를 정의 (예측)
        // btc 는 10 분에 하나의 블록이 생성되는데 이더리움은 60 블록이 생성되므로 60 을 곱해준다.(비트코인은 1024 블락이지만 이더리움에서는 60을 곱한 블락 수만큼 생기기 때문)
        uint256 epochsMined = _miningInfo.blocksPerReAdjustment;
        uint256 targetEthBlocksPerDiffPeriod = epochsMined * 60;

        uint256 miningTarget = _miningInfo.miningTarget;

        // 실제 block 수가 작다는 것은 사람들이 빠르게 마이닝 했다는 소리이므로
        // 실제 block 수가 예측한 block 수보다 작다면 난이도를 높힌다. (아니라면 난이도를 낮춘다.)
        if (ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod ) {
            uint256 excess_block_pct = (targetEthBlocksPerDiffPeriod.mul(100)).div(ethBlocksSinceLastDifficultyPeriod);
            uint256 excess_block_pct_extra = excess_block_pct.sub(100).min(1000);

            // 난이도를 높힌다(mining target 을 낮춘다)
            _miningInfo.miningTarget = miningTarget.sub(miningTarget.div(2000).mul(excess_block_pct_extra));

        } else {
            uint256 shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod.mul(100)).div(targetEthBlocksPerDiffPeriod);
            uint256 shortage_block_pct_extra = shortage_block_pct.sub(100).min(1000);

            // 난이도를 낮춘다(mining target 을 높힌다)
            _miningInfo.miningTarget = miningTarget.add(miningTarget.div(2000).mul(shortage_block_pct_extra));

        }

        // 다음 번 난이도 조절을 위한 starting block number 설정
        _miningInfo.latestDifficultyPeriodStarted = block.number;


        // 만약 설정한 max/min 난이도를 벗어난다면 조절
        if( _miningInfo.miningTarget < _MINIMUM_TARGET) {
            _miningInfo.miningTarget = _MINIMUM_TARGET;
        }

        if( _miningInfo.miningTarget > _MAXIMUM_TARGET) {
            _miningInfo.miningTarget = _MAXIMUM_TARGET;
        }
    }

    function getChallengeNumber(uint256 _id) public view returns (bytes32) {
        return miningInfos[_id].challengeNumber;
    }

    function getMiningDifficulty(uint256 _id) public view returns (uint256) {
        MiningInfo memory miningInfo = miningInfos[_id];
        return _MAXIMUM_TARGET.div(miningInfo.miningTarget);
    }

    function getMiningTarget(uint256 _id) public view returns (uint256) {
        MiningInfo memory miningInfo = miningInfos[_id];
        return miningInfo.miningTarget;
    }

    function getMiningReward(uint256 _id) public view returns (uint256) {

        ITreasure treasure = ITreasure(registry.getAddressOf("Treasure"));
        uint8 decimals = treasure.decimals(_id);

        MiningInfo memory miningInfo = miningInfos[_id];
        uint256 rewardEra = miningInfo.rewardEra;
        uint8 initialReward = miningInfo.initialReward;

        return (initialReward * 10 ** uint(decimals)).div(2 ** rewardEra);
    }

    function getMiningDigestByKeccak256(uint256 _id, uint256 _nonce, bytes32 _challenge_digest, bytes32 _challenge_number) public view returns (bytes32) {
        bytes32 digest = keccak256(abi.encodePacked(_id, _challenge_number, msg.sender, _nonce));
        return digest;
    }

    function getMiningDigestBySha256(uint256 _id, uint256 _nonce, bytes32 _challenge_digest, bytes32 _challenge_number) public view returns (bytes32) {
        bytes32 digest = sha256(abi.encodePacked(_id, _challenge_number, msg.sender, _nonce));
        return digest;
    }

    function checkMiningSolutionByKeccak256(uint256 _id, uint256 _nonce, bytes32 _challenge_digest, bytes32 _challenge_number, uint _testTarget) public view returns (bool) {
        bytes32 digest = getMiningDigestByKeccak256(_id, _nonce, _challenge_digest, _challenge_number);
        require(uint256(digest) < _testTarget);
        return (digest == _challenge_digest);
    }

    function checkMiningSolutionBySha256(uint256 _id, uint256 _nonce, bytes32 _challenge_digest, bytes32 _challenge_number, uint _testTarget) public view returns (bool) {
        bytes32 digest = getMiningDigestBySha256(_id, _nonce, _challenge_digest, _challenge_number);
        require(uint256(digest) < _testTarget);
        return (digest == _challenge_digest);
    }

    function checkMiningSolutionAll(uint256 _id, uint256 _nonce, bytes32 _challenge_digest, bytes32 _challenge_number, uint _testTarget) public view returns (bool) {
        // check digest
        bytes32 digestByKeccak256 = getMiningDigestByKeccak256(_id, _nonce, _challenge_digest, _challenge_number);
        bytes32 digestBySha256 = getMiningDigestBySha256(_id, _nonce, _challenge_digest, _challenge_number);
        require(_challenge_digest == digestByKeccak256 || _challenge_digest == digestBySha256);

        // check difficulty
        require(uint256(_challenge_digest) < _testTarget);

        return true;
    }
}

