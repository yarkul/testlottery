//SPDX-License-Indentifier: MIT

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock } from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

pragma solidity ^0.8.18;

contract CreateSubscribtion is Script {

    function CreateSubscribtionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (,,address vrfCoordinator, ,,) = helperConfig.activeNetworkConfig();

        return createSubscribtion(vrfCoordinator);
    }

    function createSubscribtion(address vrfCoordinator) public returns(uint64) {

        console.log("Creating subscribtion on ChainId:", block.chainid);
        vm.startBroadcast();
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

    }

    function run() external {
        fundSubscribtionUsingConfig();
    }
}