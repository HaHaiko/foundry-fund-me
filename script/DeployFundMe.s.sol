// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // Before startBroadcast -> Not a real Tx
        HelperConfig helperConfig = new HelperConfig();

        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();

        // After startBroadcast -> A real Tx
        vm.startBroadcast(); //anything after vm.startBroadcast are sent to the RPC URL
        // Mock
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast(); // self explanatory
        return fundMe;
    }
}
