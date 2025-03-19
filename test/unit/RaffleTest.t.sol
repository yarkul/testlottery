//SPDX-License-Indentifier: MIT

import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Test, console} from "../../forge-std/Test.sol";
import {Vm} from "../../forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

pragma solidity ^0.8.18;

contract RaffleTest is Test{

    /*Events */
    event EnteredRaffle(address indexed player);
    
    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscribtionId;
    uint32 callBackGasLimit;
    address link;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 1 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();

        (entranceFee,
        interval,
        vrfCoordinator,
        gasLane,
        subscribtionId,
        callBackGasLimit,
        link,
        ) = helperConfig.activeNetworkConfig();

        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view{
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenYouDontPayEnougth() public {
        //Arrange
        vm.prank(PLAYER);

        //Act and Assert
        vm.expectRevert(Raffle.Raffle__NotEnogthEthSent.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordPlayerWhenTheyEnter() public {
        //Arrange
        vm.prank(PLAYER);

        //Act
        raffle.enterRaffle{value: entranceFee}();

        //Assert
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        //Arrange
        vm.prank(PLAYER);

        vm.expectEmit(true, false, false, false, address(raffle));

        emit EnteredRaffle(PLAYER);

        raffle.enterRaffle{value: entranceFee}();
    }

    function testCantEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    //check upkeep
    function testCheckUpKeepReturnsFalseIfItHasNoBalance() public {
        //Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        //Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfRaffleNotOpen() public {
            //Arrange
            vm.prank(PLAYER);
            raffle.enterRaffle{value:entranceFee}();
            vm.warp(block.timestamp + interval + 1);
            vm.roll(block.number + 1);
            raffle.performUpkeep("");

            //Act
            (bool upkeepNeeded, ) = raffle.checkUpkeep("");

            //Assert
            assert(!upkeepNeeded);
        }

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
            //Arragne
            vm.prank(PLAYER);
            raffle.enterRaffle{value: entranceFee}();
            vm.warp(block.timestamp + interval + 1);
            vm.roll(block.number + 1);    

            //Act / Assert
            raffle.performUpkeep("");        
        }

    function testPerformUpKeepRevertsIfCheckUpKeepIsFlase() public {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        uint256 raffleState = 0;

        vm.expectRevert(abi.encodeWithSelector(
            Raffle.Raffle__UpkeepNotNeeded.selector, 
            currentBalance, 
            numPlayers, 
            raffleState));

            //Act / Assert
            raffle.performUpkeep("");               
    }

    modifier raffleEnteredAndTimePassed() {
            vm.prank(PLAYER);
            raffle.enterRaffle{value: entranceFee}();
            vm.warp(block.timestamp + interval + 1);
            vm.roll(block.number + 1);
            _;        
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public
    raffleEnteredAndTimePassed {

        //Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState rState = raffle.getRaffleState();

        //Assert
        assert(uint256(requestId) > 0);
        assert(uint256(rState )== 1);
    }

    modifier skipFork(){
        if(block.chainid != 31337){
            return;
        }
        _;
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerfomUpKeep(uint256 randomRequestId) public
    raffleEnteredAndTimePassed skipFork {
        //Arrange
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));

    }

    function testFulfillRandomWordsPicksAWinnerResestsAndSendsMoney() public 
    raffleEnteredAndTimePassed skipFork{
        uint256 additionalEntrants = 5;
        uint256 startingIndex = 1;

        for(uint256 i = startingIndex; i < startingIndex + additionalEntrants; i++) {
            address player = address(uint160(i));
            hoax(player, 1 ether);
            raffle.enterRaffle{value:entranceFee}();
        }

        uint256 prize = entranceFee * (additionalEntrants + 1);

        vm.recordLogs();
        raffle.performUpkeep("");   //emit requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        uint256 previousTimeStamp = raffle.getLastTimeStamp();

        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        //assert
        //assert(uint256(raffle.getRaffleState()) == 0);
        //assert(raffle.getRecentWinner() != address(0));
        //assert(raffle.getLengthOfPlayers() == 0);
        //assert(previousTimeStamp < raffle.getLastTimeStamp());
        console.log(raffle.getRecentWinner().balance);
        console.log(STARTING_USER_BALANCE + prize - entranceFee);
        assert(raffle.getRecentWinner().balance  == STARTING_USER_BALANCE + prize - entranceFee);
    }
}