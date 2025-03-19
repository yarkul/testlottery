//SPDX-License-Indentifier: MIT

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock } from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";


pragma solidity ^0.8.18;

contract CreateSubscribtion is Script {

    function CreateSubscribtionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        ( , , address vrfCoordinator, , , ,  address link, uint256 deployerKey) = helperConfig.activeNetworkConfig();

        return createSubscribtion(vrfCoordinator, deployerKey);
    }

    function createSubscribtion(address vrfCoordinator, uint256 deployerKey) public returns(uint64) {

        console.log("Creating subscribtion on ChainId:", block.chainid);
        vm.startBroadcast(deployerKey);
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Your sub Id:", subId);

        return subId;
    }

    function run() external returns(uint64){
        return CreateSubscribtionUsingConfig();
    }
}

contract FundSubscribtion is Script{
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscribtionUsingConfig() public {

        HelperConfig helperConfig = new HelperConfig();

        (,
         ,address vrfCooridnator
         , 
         ,uint64 subId
         ,
         ,address link
         ,uint256 deployerKey) = helperConfig.activeNetworkConfig();

         fundSubscribtion(vrfCooridnator, subId, link, deployerKey);
    }

    function fundSubscribtion(address vrfCoordinator, uint64 subId, address link, uint256 deployerKey) public{
        console.log("Funding Subscribtion", subId);
        console.log("VRFCoordinator", vrfCoordinator);
        console.log("ChainId", block.chainid);

        if(block.chainid == 31337){ //anvil ?
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(deployerKey);            
            LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();            

        }
            
    }    

    function run() external {
        fundSubscribtionUsingConfig();
    }
}

contract AddConsumer is Script {

    function addConsumer(address raffle, address vrfCoordinator, uint64 subId, uint256 deployerKey) public {

        console.log("Adding consumer contract:", raffle);
        console.log("Using VRF Coordinator:", vrfCoordinator);
        console.log("ChainId: ", block.chainid);

        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, raffle);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address raffle) public  {
        HelperConfig helperConfig = new HelperConfig();

        ( , , address vrfCoordinator, , uint64 subId, , , uint256 deployerKey) = helperConfig.activeNetworkConfig();

        addConsumer(raffle, vrfCoordinator, subId, deployerKey);
    }    

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(raffle);
    }
}