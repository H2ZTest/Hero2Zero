// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ISolo.sol";
import "./interfaces/IOnline.sol";

contract RockPaperScissors is AccessControl, ReentrancyGuard{
    using SafeERC20 for IERC20; 
   
    uint public rewardBNBPool;
    
    uint public constant OPTION_ROCK = 0;
    uint public constant OPTION_PAPER = 1;
    uint public constant OPTION_SCISSORS = 2;
    uint public constant MINIMAL_BNB_BET = 1e14;
    uint public constant MULTIPLIER_BY_NFT_HOLD = 10;

    address public immutable tokenMultiplierAddress;
    address public immutable soloCore;
    address public immutable onlineCore;

    mapping(address => uint) public rewardTokenPool;

    event CreatedSoloGameBNB(uint indexed gameId, address indexed user, uint answer, uint bet, uint time);
    event FinishedSoloGameBNB(uint indexed gameId, address indexed user, address winner, uint bet, uint time);
    event CreatedSoloGameToken(uint indexed gameId, address indexed user, address indexed token, uint answer, uint bet, uint time);
    event FinishedSoloGameToken(uint indexed gameId, address indexed user, address indexed token, address winner, uint bet, uint time);
    event CreatedOnlineGameBNB(uint indexed gameId, address indexed user, bytes32 answerHash, uint bet, uint time);
    event ParticipatedOnlineGameBNB(uint indexed gameId, address indexed user, address indexed userTwo, uint answerTwo, uint time);
    event FinishedOnlineGameBNB(uint indexed gameId, address indexed user, address indexed userTwo, address winner, uint bet, uint time);
    event CanceledOnlineGameBNB(uint indexed gameId, address indexed user, uint time);
    event CreatedOnlineGameToken(uint indexed gameId, address indexed user, bytes32 answerHash, address indexed token, uint bet, uint time);
    event ParticipatedOnlineGameToken(uint indexed gameId, address indexed user, address userTwo, address indexed token, uint answerTwo, uint time);
    event FinishedOnlineGameToken(uint indexed gameId, address indexed user, address userTwo, address winner, address indexed token, uint bet, uint time);
    event CanceledOnlineGameToken(uint indexed gameId, address indexed user, address indexed token, uint time);

    constructor(address _NFToken, address _soloCore, address _onlineCore) payable {
        rewardBNBPool += msg.value;
        tokenMultiplierAddress = _NFToken;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); 
        soloCore = _soloCore;
        onlineCore = _onlineCore; 
    }

    function createSoloGameBNB(uint _answer)external payable nonReentrant() returns(uint _gameId){
        address _user = msg.sender;
        uint _bet = msg.value;
        require(rewardBNBPool > _bet, "RockPaperScissors: Not enough tBNB to your prize");
        require(_bet >= MINIMAL_BNB_BET, "RockPaperScissors: Not enough tBNB to bet");
        _gameId = ISolo(soloCore).createSoloGameBNB(_user, _answer, _bet);

        emit CreatedSoloGameBNB(_gameId, _user, _answer, _bet, block.timestamp);
    }

    function finishSoloGameBNB(uint _gameId)external nonReentrant(){
        address _user = msg.sender;
        (address _winner, uint _bet) = ISolo(soloCore).finishSoloGameBNB(_user, _gameId);
        repaymentBNBInternal(_user, address(this), _winner, _bet);

        emit FinishedSoloGameBNB(_gameId, _user, _winner, _bet, block.timestamp);
    }

    function forceFinishSoloGameBNB(uint _gameId, address _user)external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant(){
        (address _winner, uint _bet) = ISolo(soloCore).finishSoloGameBNB(_user, _gameId);
        repaymentBNBInternal(_user, address(this), _winner, _bet);

        emit FinishedSoloGameBNB(_gameId, _user, _winner, _bet, block.timestamp);
    }

    function createSoloGameToken(uint _answer, address _token, uint _amount)external nonReentrant() returns(uint _gameId){
        address _user = msg.sender;
        require(rewardTokenPool[_token] >= _amount, "RockPaperScissors: Not enough tokens to reward");
        _gameId = ISolo(soloCore).createSoloGameToken(_user, _answer, _token, _amount);
        IERC20(_token).safeTransferFrom(_user, address(this), _amount);

        emit CreatedSoloGameToken(_gameId, _user, _token, _answer, _amount, block.timestamp);
    }

    function finishSoloGameToken(uint _gameId)external nonReentrant(){
        address _user = msg.sender;
        (address _winner, address _token, uint _bet) = ISolo(soloCore).finishSoloGameToken(_user, _gameId);
        repaymentTokenInternal(_user, address(this), _winner, _token, _bet);

        emit FinishedSoloGameToken(_gameId, _user, _token, _winner, _bet, block.timestamp);
    }

    function forceFinishSoloGameToken(uint _gameId, address _user)external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant(){
        (address _winner, address _token, uint _bet) = ISolo(soloCore).finishSoloGameToken(_user, _gameId);
        repaymentTokenInternal(_user, address(this), _winner, _token, _bet);

        emit FinishedSoloGameToken(_gameId, _user, _token, _winner, _bet, block.timestamp);
    }

    function createOnlineGameBNB(bytes32 _answerHash)external payable nonReentrant() returns(uint _gameId){
        address _user = msg.sender;
        uint _bet = msg.value;
        require(_bet >= MINIMAL_BNB_BET, "RockPaperScissors: Not enough tBNB to bet");
        _gameId = IOnline(onlineCore).createOnlineGameBNB(_user, _answerHash, _bet);

        emit CreatedOnlineGameBNB(_gameId, _user, _answerHash, _bet, block.timestamp);
    }

    function participateOnlineGameBNB(uint _gameId, uint _answer)external payable nonReentrant(){
        address _user = msg.sender;
        uint userBet = msg.value;
        (uint actualBet, address user1) = IOnline(onlineCore).participateOnlineGameBNB(_user, _gameId, _answer); 
        require(userBet >= actualBet, "RockPaperScissors: Not enough tBNB to bet");
        if(userBet > actualBet){
            uint refund = userBet - actualBet;
            (bool success,) = _user.call{value: refund}("");
            require(success);
        }

        emit ParticipatedOnlineGameBNB(_gameId, user1, _user, _answer, block.timestamp);
    }

    function finishOnlineGameBNB(uint _gameId, uint _answer, string memory _salt)external nonReentrant(){
        address _user = msg.sender;
        (address user2, address winner, uint bet) = IOnline(onlineCore).finishOnlineGameBNB(_user, _gameId, _answer, _salt);
        repaymentBNBInternal(
            _user, 
            user2, 
            winner, 
            bet
        );
        
        emit FinishedOnlineGameBNB(_gameId, _user, user2, winner, bet, block.timestamp);
    }

    function refundBetFromExpiredOnlineGameBNB(uint _gameId)external nonReentrant(){
        address _user = msg.sender;
        (address user1, uint bet) = IOnline(onlineCore).refundBetFromExpiredOnlineGameBNB(_user, _gameId);
        repaymentBNBInternal(
            user1, 
            _user, 
            _user, 
            bet
        );
        
        emit FinishedOnlineGameBNB(_gameId, user1, _user, _user, bet, block.timestamp);
    }

    function cancelOnlineGameBNB(uint _gameId)external nonReentrant(){
        address _user = msg.sender;
        uint bet = IOnline(onlineCore).cancelOnlineGameBNB(_user, _gameId);
        (bool success,) = _user.call{value: bet}("");
        require(success);

        emit CanceledOnlineGameBNB(_gameId, _user, block.timestamp);
    }

    function createOnlineGameToken(bytes32 _answerHash, address _token, uint _amount)external nonReentrant() returns(uint _gameId){
        address _user = msg.sender;
        _gameId = IOnline(onlineCore).createOnlineGameToken(_user, _answerHash, _token, _amount);
        IERC20(_token).safeTransferFrom(_user, address(this), _amount);

        emit CreatedOnlineGameToken(_gameId, _user, _answerHash, _token, _amount, block.timestamp);
    }

    function participateOnlineGameToken(uint _gameId, uint _answer)external nonReentrant(){
        address _user = msg.sender;
        (uint bet, address user1, address token) = IOnline(onlineCore).participateOnlineGameToken(_user, _gameId, _answer);
        IERC20(token).safeTransferFrom(_user, address(this), bet);

        emit ParticipatedOnlineGameToken(_gameId, user1, _user, token, _answer, block.timestamp);
    }

    function finishOnlineGameToken(uint _gameId, uint _answer, string memory _salt)external nonReentrant(){
        address _user = msg.sender;
        (address winner, address user2, address token, uint bet) = IOnline(onlineCore).finishOnlineGameToken(_user, _gameId, _answer, _salt);
        repaymentTokenInternal(
            _user, 
            user2, 
            winner, 
            token,
            bet
        );

        emit FinishedOnlineGameToken(_gameId, _user, user2, winner, token, bet, block.timestamp);
    }

    function refundBetFromExpiredOnlineGameToken(uint _gameId)external nonReentrant(){
        address _user = msg.sender;
        (address user1, address token, uint bet) = IOnline(onlineCore).refundBetFromExpiredOnlineGameToken(_user, _gameId);
        repaymentTokenInternal(
            user1, 
            _user, 
            _user, 
            token,
            bet
        );
        
        emit FinishedOnlineGameToken(_gameId, user1, _user, _user, token, bet, block.timestamp);
    }

    function cancelOnlineGameToken(uint _gameId)external nonReentrant(){
        address _user = msg.sender;
        (address token, uint bet) = IOnline(onlineCore).cancelOnlineGameToken(_user, _gameId);
        IERC20(token).safeTransfer(_user, bet);

        emit CanceledOnlineGameToken(_gameId, _user, token, block.timestamp);
    }

    function fillBNBRewardPool()external payable nonReentrant(){
        rewardBNBPool += msg.value;
    }

    function fillTokenRewardPool(address _token, uint _amount)external nonReentrant(){
        address _user = msg.sender;
        require(IERC20(_token).balanceOf(_user) >= _amount, "RockPaperScissors: Not enough tokens");
        rewardTokenPool[_token] += _amount;
        IERC20(_token).safeTransferFrom(_user, address(this), _amount);
    }

    function withdrawBNB(uint _amount)external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant(){
        require(rewardBNBPool >= _amount, "RockPaperScissors: Not enough tBNB to withdraw");
        (bool success,) = msg.sender.call{value: _amount}("");
        require(success);
    }

    function withdrawToken(address _token, uint _amount)external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant(){
        require(rewardTokenPool[_token] >= _amount, "RockPaperScissors: Not enough tokens to withdraw");
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    function createHash(uint answer, string memory salt)external pure returns(bytes32 hash){
        require(answer == OPTION_ROCK || answer == OPTION_PAPER || answer == OPTION_SCISSORS, "RockPaperScissors: Choosed wrong option");
        return keccak256(abi.encode(answer, salt));
    }

    function checkNFTHold(address _user)internal view returns(bool result){
        if(IERC721(tokenMultiplierAddress).balanceOf(_user) > 0){
            return true;
        } 
    }

    function repaymentBNBInternal(address _user1, address _user2, address _winner, uint _bet)internal {
        uint bet2 = _bet * 2;
        uint bonusAmount = _bet / MULTIPLIER_BY_NFT_HOLD;
        if(_user2 != address(this)){
            if(_winner == address(0)){
                (bool success,) = _user1.call{value: _bet}("");
                require(success);
                (bool success1,) = _user2.call{value: _bet}("");
                require(success1);
            } else {
                if(_winner == _user1){
                    if (checkNFTHold(_user1) == true && rewardBNBPool > bonusAmount){
                        bet2 += bonusAmount;
                        rewardBNBPool -= bonusAmount;
                    }
                    (bool success2,) = _user1.call{value: bet2}("");
                    require(success2);
                } else {
                    if (checkNFTHold(_user2) == true && rewardBNBPool > bonusAmount){
                        bet2 += bonusAmount;
                        rewardBNBPool -= bonusAmount;
                    }
                    (bool success3,) = _user2.call{value: bet2}("");
                    require(success3);
                }
            }
        } else {
            if(_winner == address(0)){
                (bool success,) = _user1.call{value: _bet}("");
                require(success);
            } else {
                if(_winner == _user1){
                    if (checkNFTHold(_user1) == true && rewardBNBPool > bonusAmount){
                        bet2 += bonusAmount;
                        rewardBNBPool -= bonusAmount;
                    }
                    (bool success2,) = _user1.call{value: bet2}("");
                    require(success2);
                    rewardBNBPool -= _bet;
                } else {
                    rewardBNBPool += _bet;
                }
            }
        }
    }

    function repaymentTokenInternal(address _user1, address _user2, address _winner, address _token, uint _bet)internal {
        uint bet2 = _bet * 2;
        uint bonusAmount = _bet / MULTIPLIER_BY_NFT_HOLD;
        if(_user2 != address(this)){
            if(_winner == address(0)){
                IERC20(_token).safeTransfer(_user1, _bet);
                IERC20(_token).safeTransfer(_user2, _bet);
            } else {
                if(_winner == _user1){
                    if (checkNFTHold(_user1) == true && rewardTokenPool[_token] > bonusAmount){
                        bet2 += bonusAmount;
                        rewardTokenPool[_token] -= bonusAmount;
                    }
                    IERC20(_token).safeTransfer(_user1, bet2);
                } else {
                    if (checkNFTHold(_user2) == true && rewardTokenPool[_token] > bonusAmount){
                        bet2 += bonusAmount;
                        rewardTokenPool[_token] -= bonusAmount;
                    }
                    IERC20(_token).safeTransfer(_user2, bet2);
                }
            }
        } else {
            if(_winner == address(0)){
                IERC20(_token).safeTransfer(_user1, _bet);
            } else {
                if(_winner == _user1){
                    if (checkNFTHold(_user1) == true && rewardTokenPool[_token] > bonusAmount){
                        bet2 += bonusAmount;
                        rewardTokenPool[_token] -= bonusAmount;
                    }
                    IERC20(_token).safeTransfer(_user1, bet2);
                    rewardTokenPool[_token] -= _bet;
                } else {
                    rewardTokenPool[_token] += _bet;
                }
            }
        }
    } 
            
    receive()external payable nonReentrant(){
        rewardBNBPool += msg.value;
    }
}

