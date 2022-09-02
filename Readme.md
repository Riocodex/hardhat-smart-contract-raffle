//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
//for randomness
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
//for upkeepness(that is being automated and running by itself)
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();
error Raffle_NotOpen();
error Raffle__UpKeepNotNeeded(
    uint256 currentBalance , 
    uint256 numPlayers , 
    uint256 raffleState
);

/**@title A sample Raffle or lottery contract
 * @author Onwuka Rosario
 * @notice this contract is for creating an untamperable automated decentralized smart contract
 * @dev this implements chainlink VRF v2 and Chainlink keepers
 * 
 */

contract Raffle is VRFConsumerBaseV2 , KeeperCompatibleInterface{
    //Type declarations
    enum RaffleState{
        OPEN,
        CALCULATING 
    }
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
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    //Events
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee ,
         bytes32 gasLane,
         uint64 subscriptionId,
         uint32 callbackGasLimit , 
         uint256 interval
        ) VRFConsumerBaseV2(vrfCoordinatorV2){
            i_entranceFee = entranceFee;
            i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
            i_gasLane = gasLane;
            i_subscriptionId = subscriptionId;
            i_callbackGasLimit = callbackGasLimit;
            s_raffleState = RaffleState.OPEN;
            s_lastTimeStamp = block.timestamp;
            i_interval = interval;
    } 

    function enterRaffle()public payable{
        if(msg.value < i_entranceFee){
            revert Raffle__NotEnoughETHEntered();
        }
        //if raffle isnt open
        if(s_raffleState != RaffleState.OPEN){
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }
    /**
     * @dev this is the function the chain keeper nodes call
     * they look for the 'upKeepNeeded' to return true
     * when it returns true thats when the random number changes
     * the following should be true in order to return true:
     * 1)Our time interval should have passed
     * 2)The lottery should have atleast 1 player, and have some ETH
     * 3)our subscription is funded with LINK
     * 4)the lottery should be in an open state.
     */
    function checkUpKeep(bytes calldata /*checkdata*/)public override returns(bool upKeepNeeded , bytes memory /*performData*/{
        //to chech whether the lottery is open
        bool isOpen = (RaffleState.OPEN == s_raffleState);
        //to check whether the time interval has passed
        bool timePassed  = ((block.timestamp - s_lastTimeStamp) > i_interval);
        //to check if the lottery has atleast one player
        bool hasPlayers = (s_players.length > 0);
        //to check whether the smartcontract has any balance
        bool hasBalance  = address(this).balance > 0;
        //to rap up all the bools and put it in the inherited chainlink function to retur one last statement
        bool upKeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }
     function performUpKeep(bytes memory /*performdata*/) external override{
        (bool upKeepNeeded , ) = checkUpKeep("");
        //if upkeep is not true
        if(!upKeepNeeded) {
            revert Raffle__UpKeepNotNeeded(
                //this variables are to show the user the cause of the problem..whether there is no money in the smartcontract,or there are no players or the lottery isnt open yet
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = Raffle.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
             i_gasLane,
             i_subscriptionId,
             REQUEST_CONFIRMATIONS,
             i_callbackGasLimit,
             NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
     }
     function fufillRandomWords(
        uint256, /*requestId */
        uint256[] memory randomWords)
        internal override
     { 
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner]; 
        s_recentWinner = recentWinner;
        //when there is a winner the lottery is open
        s_raffleState = RaffleState.OPEN;
        //when a winner has been picked array of users refresh
        s_players = new address payable[](0);
        //when theres a winner the timestamp resets
        s_lastTimeStamp = block.timestamp;
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
    function getRaffleState() public pure returns(RaffleState){
        return s_raffleState;
    }
    function getNumberOfPlayers()public view returns(uint256){
        return s_players.length;
    }
    function getLatestTimeStamp() public view returns (uint256){
        return s_lastTimeStamp;
    }
    function getRequestConfirmations()public pure returns (uint256){
        return REQUEST_CONFIRMATIONS;
    }
}