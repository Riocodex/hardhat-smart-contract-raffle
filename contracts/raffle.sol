//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();
contract Raffle is VRFConsumerBaseV2{
    //state variables
    uint256 private immutable i_entranceFee;
    address payable [] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    //lottery variables
    address private s_recentWinner;

    //Events
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee ,
         bytes gasLane,
         uint64 subscriptionId,
         uint32 callbackGasLimit,
        ) VRFConsumerBaseV2(vrfCoordinatorV2){
            i_entranceFee = entranceFee;
            i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
            i_gasLane = gasLane;
            i_subscriptionId = subscriptionId;
            i_callbackGasLimit = callbackGasLimit;
    } 

    function enterRaffle()public payable{
        if(msg.value < i_entranceFee){
            revert Raffle__NotEnoughETHEntered();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }
     function requestRandomWinner() external{
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
             i_gasLane,
             i_subscriptionId,
             REQUEST_CONFIRMATIONS,
             i_callbackGasLimit,
             NUM_WORDS,
        );
        emit RequestedRaffleWinner(requestId);
     }
     function fufillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal override
     { 
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner]; 
        s_recentWinner = recentWinner;
        (bool success , ) = recentWinner.call{value: address(this).balance}("");
        //require(success)
        if(!success ){
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
      }
    /*View / Pure functions */
    function getEntranceFee() public view returns (uint256){
        return i_entranceFee;
    }
    function getPlayer(uint256 index)public view returns(address){
        return s_players[index];
    }
    function getRecentWinner() public view returns(address){
        return s_recentWinner;
    }
}