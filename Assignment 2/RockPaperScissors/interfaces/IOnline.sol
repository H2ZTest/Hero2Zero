// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IOnline{

    function createOnlineGameBNB(address user, bytes32 answerHash, uint bet)external returns(uint gameId);

    function participateOnlineGameBNB(address user, uint gameId, uint answer)external returns(uint bet, address user1);

    function finishOnlineGameBNB(address user, uint gameId, uint answer, string memory salt)external returns(address user2, address winner, uint bet);

    function refundBetFromExpiredOnlineGameBNB(address user, uint gameId)external returns(address user1, uint bet);

    function cancelOnlineGameBNB(address user, uint gameId)external returns(uint bet);

    function createOnlineGameToken(address user, bytes32 answerHash, address token, uint amount)external returns(uint gameId);

    function participateOnlineGameToken(address user, uint gameId, uint answer)external returns(uint bet, address user1, address token);

    function finishOnlineGameToken(address user, uint gameId, uint answer, string memory salt)external returns(address winner, address user2, address token, uint bet);

    function refundBetFromExpiredOnlineGameToken(address user, uint gameId)external returns(address user1, address token, uint bet);

    function cancelOnlineGameToken(address user, uint gameId)external returns(address token, uint bet);
}

