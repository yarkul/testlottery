//SPDX-License-Indentifier: MIT

import {Script} from "../lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscribtion} from "./Interactions.s.sol";

pragma solidity ^0.8.18;

contract DeployRaffle is Script{

    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 gasLane,
            uint64 subscribtionId,
            uint32 callBackGasLimit
        ) = helperConfig.activeNetworkConfig();

        if(subscribtionId == 0){
            CreateSubscribtion createSubscribtion = new CreateSubscribtion();
            subscribtionId = createSubscribtion.createSubscribtion(vrfCoordinator);
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
        entranceFee, 
        interval, 
        vrfCoordinator,
        gasLane,
        subscribtionId,
        callBackGasLimit
        );
        vm.stopBroadcast();

        return (raffle, helperConfig);
    }
}