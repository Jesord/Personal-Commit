// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {BasicNft} from "../src/BasicNft.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployBasicNft is Script {
    function run() public returns (BasicNft) {
        // Get the appropriate network configuration
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getNetworkConfig();

        // Start broadcast for deployment transaction
        vm.startBroadcast();

        // Deploy BasicNft contract
        BasicNft basicNft = new BasicNft(networkConfig.name, networkConfig.symbol);
        // Stop broadcast after deployment
        vm.stopBroadcast();

        return basicNft;
    }
}
