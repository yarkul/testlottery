//SPDX-License-Indentifier: MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title A sample Raffle Contract
 * @author Yaroslav (via Patrick Collins steps)
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2
 */
contract Raffle is VRFConsumerBaseV2{

    error Raffle__NotEnogthEthSent();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

    enum RaffleState{
        OPEN, //0
        CALCULATING //1
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscribtionId;
    uint32 private immutable i_callBackGasLimit;

    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);

    constructor(
        uint256 entranceFee, 
        uint256 interval, 
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscribtionId,
        uint32 callBackGasLimit) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscribtionId = subscribtionId;
        i_callBackGasLimit = callBackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() public payable{
        if(msg.value < i_entranceFee){
            revert Raffle__NotEnogthEthSent();
        }

        if(s_raffleState != RaffleState.OPEN){
            revert Raffle__RaffleNotOpen();
        }
        
        s_players.push(payable(msg.sender));

        emit EnteredRaffle(msg.sender);
    }

    //when is the winner supposed to be picked? asw: 
    /*1. time interval passed between raffle runs 
      2. raffle is in OPEN state
      3. the contract has ETH(aka players)
      4. */
    function checkUpkeep(
        bytes memory /*checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /*performData */){

        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");

    }

    function performUpkeep(bytes calldata /*performData*/) external {

        (bool upkeepNeeded, ) = checkUpkeep("");

        if(!upkeepNeeded){
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        if((block.timestamp - s_lastTimeStamp) <= s_lastTimeStamp)
        {
            revert();            
        }

        s_raffleState = RaffleState.CALCULATING;

        i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscribtionId, 
            REQUEST_CONFIRMATIONS,
            i_callBackGasLimit,
            NUM_WORDS);

    }

    function fulfillRandomWords(uint256 /*requestId*/, uint256[] memory randomWords) 
    internal override {

        uint256 indexOfWinner = randomWords[0] % s_players.length; //pick index from 0 to player length

        address payable winner = s_players[indexOfWinner];

        s_recentWinner = winner;

        s_raffleState = RaffleState.OPEN;

        s_players = new address payable[](0);

        s_lastTimeStamp = block.timestamp;

        emit PickedWinner(winner);        

        (bool success, ) = winner.call{value: address(this).balance}("");

        if(!success){
            revert Raffle__TransferFailed();
        }
    }

    function getEntranceFee() external view returns (uint256){
        return i_entranceFee;
    }

    function getRaffleState() external view returns(RaffleState){
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns(address){
        return s_players[indexOfPlayer];
    }
}