// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackLimit;
    address link;
    uint256 deployerKey;

    event enteredRaffle(address indexed player);

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();

        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackLimit,
            link,
            
        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInOpen() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        vm.expectRevert(Raffle.Raffle__notEnoughEth.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee - 1}();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        address player = raffle.getPlayers(0);
        assert(PLAYER == player);
    }

    function testEmitsEventsOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit enteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCantEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpKeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    modifier enteredRaffleAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testCheckUpKeepReturnsFalseIfItHasNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseTimeHasNotPassed() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfNotOpen()
        public
        enteredRaffleAndTimePassed
    {
        raffle.performUpKeep("");

        (bool upKeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upKeepNeeded);
    }

    function testCheckUpkeepReturnsTrueWhenParametersAreGood()
        public
        enteredRaffleAndTimePassed
    {
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
    }

    function testPerformUpkeepCanRunIfPerformUpKeepIsTrue()
        public
        enteredRaffleAndTimePassed
    {
        raffle.performUpKeep("");
    }

    function testPerformUpkeepCannotRunIfPerformUpKeepIsFalse() public {
        uint256 currentBalance = raffle.getContractBalance();
        uint256 numPlayer = raffle.getTotalPlayers();
        uint256 raffleState = 0;

        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayer,
                raffleState
            )
        );
        raffle.performUpKeep("");
    }

    function testRaffleStateIsInCalculatingIfPerformUpkeepRuns()
        public
        enteredRaffleAndTimePassed
    {
        raffle.performUpKeep("");
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
    }

    function testPerformUpkeepEmitsRequestId()
        public
        enteredRaffleAndTimePassed
    {
        vm.recordLogs();
        raffle.performUpKeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        assert(uint256(requestId) > 0);
    }

     modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) public enteredRaffleAndTimePassed skipFork {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    
 function testFulfillRandomWordsPicksWinnerResetAndSendMoney() public enteredRaffleAndTimePassed skipFork {
    uint256 additionalEntrants = 5;
    uint256 startingIndex = 1;

    for (uint256 i = startingIndex; i < startingIndex + additionalEntrants; i++) {
      address player = address(uint160(i));
      hoax(player, STARTING_USER_BALANCE);
      raffle.enterRaffle{value: entranceFee}();

         }     


         uint256 prize = entranceFee * (additionalEntrants + 1);
         vm.recordLogs();
        raffle.performUpKeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        uint256 previousTimeStamp = raffle.getLastTimeStamp();

         
        
     VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
        uint256(requestId),
        address(raffle)
    ); 

    //  vm.expectEmit(true, false, false, false, address(raffle));
    //     emit PickedWinner(raffle.getRecentWinner());  


    assert(uint256(raffle.getRaffleState()) == 0);
    assert(raffle.getRecentWinner() != address(0));
    assert(raffle.getTotalPlayers() == 0); 
    assert(previousTimeStamp < raffle.getLastTimeStamp());
   
    assert(raffle.getRecentWinner().balance == STARTING_USER_BALANCE + prize - entranceFee);      


    
   }


}
