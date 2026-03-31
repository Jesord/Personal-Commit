// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {BasicNft} from "../src/BasicNft.sol";

contract Interactions is Script {
    function run() public returns (BasicNft) {
        // Deploy BasicNft by owner account
        vm.startBroadcast();
        BasicNft basicNft =
            new BasicNft("CrazyClowns", "CC", "ipfs/bafybeifm5jlemvhc4qcuw7arocpny35dso423hudnrckgbkwc2p5hi3r6y/");
        vm.stopBroadcast();

        // Run end-to-end interaction scenario
        runIntegrationScenario(basicNft);

        return basicNft;
    }

    // 1. Calls deployed contract functions (owner/reads)
    function callDeployedFunctions(BasicNft basicNft) public {
        uint256 feeBefore = basicNft.mintFee();
        address vaultBefore = basicNft.vaultAddress();

        vm.startBroadcast();
        basicNft.setMintFee(feeBefore + 0.005 ether);
        basicNft.setVaultAddress(address(0x1234));
        vm.stopBroadcast();

        vm.startBroadcast();
        basicNft.setMintFee(feeBefore);
        basicNft.setVaultAddress(vaultBefore);
        vm.stopBroadcast();
    }

    // 2. Simulates user actions: mint, unlock, approve, transfer
    function simulateUserActions(BasicNft basicNft, address user1, address user2) public {
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);

        uint256 mintPrice = basicNft.mintFee();

        vm.prank(user1);
        uint256 tokenId =
            basicNft.mintNft{value: mintPrice}("ipfs://bafybeifm5jlemvhc4qcuw7arocpny35dso423hudnrckgbkwc2p5hi3r6y/");

        assert(basicNft.ownerOfNft(tokenId) == user1);

        vm.prank(user1);
        basicNft.unlockToken(tokenId);

        vm.prank(user1);
        basicNft.approve(user2, tokenId);

        vm.prank(user2);
        basicNft.transferFrom(user1, user2, tokenId);

        assert(basicNft.ownerOfNft(tokenId) == user2);
    }

    // 3. Integration scenario for manual testing
    function runIntegrationScenario(BasicNft basicNft) public {
        callDeployedFunctions(basicNft);

        address alice = makeAddr("alice");
        address bob = makeAddr("bob");

        simulateUserActions(basicNft, alice, bob);

        uint256 lastTokenId = basicNft.tokenCounter() - 1;
        require(basicNft.ownerOfNft(lastTokenId) == bob, "final owner must be bob");

        bool locked = basicNft.isTokenLocked(lastTokenId);
        assert(!locked);
    }
}
