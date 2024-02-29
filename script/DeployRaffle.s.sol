// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";


contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); 
        AddConsumer addConsumer = new AddConsumer();

   ( 
    uint256 entranceFee,
    uint256 interval,
    address vrfCoordinator,
    bytes32 gasLane,
    uint64 subscriptionId,
    uint32 callbackLimit,
    address link,
    uint256 deployerKey
    ) = helperConfig.activeNetworkConfig();


    if (subscriptionId == 0) {
     CreateSubscription createSubscription = new CreateSubscription();
     subscriptionId = createSubscription.createSubscription(vrfCoordinator, deployerKey);

     FundSubscription fundSubscription = new FundSubscription();
     fundSubscription.fundSubscription(vrfCoordinator, subscriptionId, link, deployerKey);


            
    }
    

    vm.startBroadcast();
    Raffle raffle = new Raffle(
    entranceFee,
    interval,
    vrfCoordinator,
    gasLane,
    subscriptionId,
    callbackLimit
    );
    vm.stopBroadcast();

    
    addConsumer.addConsumer(vrfCoordinator, subscriptionId, address(raffle), deployerKey);

     return (raffle, helperConfig);  

   
    }

    
}