// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {BasicNft} from "../src/BasicNft.sol";
import {DeployBasicNft} from "../script/DeployBasicNft.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeployBasicNftTest is Test {
    DeployBasicNft public deployer;
    BasicNft public basicNft;
    HelperConfig public helperConfig;

    function setUp() public {
        deployer = new DeployBasicNft();
    }

    function testDeploymentSucceeds() public {
        basicNft = deployer.run();

        // Verify the contract is deployed (not address zero)
        assert(address(basicNft) != address(0));
    }

    function testContractIsDeployedWithCorrectName() public {
        basicNft = deployer.run();
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig
            .getNetworkConfig();

        // Verify the name matches the configuration
        assertEq(basicNft.name(), config.name);
    }

    function testContractIsDeployedWithCorrectSymbol() public {
        basicNft = deployer.run();
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig
            .getNetworkConfig();

        // Verify the symbol matches the configuration
        assertEq(basicNft.symbol(), config.symbol);
    }

    function testTokenCounterStartsAtZero() public {
        basicNft = deployer.run();

        // Verify token counter is initialized to 0
        assertEq(basicNft.tokenCounter(), 0);
    }

    function testOwnerIsSet() public {
        basicNft = deployer.run();

        // Verify the deployer is the owner
        assertEq(basicNft.owner(), address(this));
    }

    function testMintFeeIsCorrect() public {
        basicNft = deployer.run();

        // Verify mint fee is set correctly
        assertEq(basicNft.mintFee(), 0.001 ether);
    }

    function testVaultAddressIsSet() public {
        basicNft = deployer.run();

        // Verify vault address is set to the owner initially
        assertEq(basicNft.vaultAddress(), address(this));
    }

    function testDeployerIsWhitelisted() public {
        basicNft = deployer.run();

        // Verify the owner/deployer is whitelisted
        assertTrue(basicNft.whitelistedTransferers(address(this)));
    }

    function testCanMintAfterDeployment() public {
        basicNft = deployer.run();

        string memory testUri = "ipfs://QmTestURI/";

        // Mint an NFT with sufficient fee
        vm.deal(address(this), 1 ether);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(testUri);

        // Verify token was minted
        assertEq(tokenId, 0);
        assertEq(basicNft.tokenCounter(), 1);
        assertEq(basicNft.ownerOfNft(tokenId), address(this));
    }

    function testTokenIsLockedAfterMint() public {
        basicNft = deployer.run();

        string memory testUri = "ipfs://QmTestURI/";

        vm.deal(address(this), 1 ether);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(testUri);

        // Verify token is locked after minting
        assertTrue(basicNft.isTokenLocked(tokenId));
    }

    function testTokenUriIsSetCorrectly() public {
        basicNft = deployer.run();

        string memory testUri = "ipfs://QmTestURI/metadata1";

        vm.deal(address(this), 1 ether);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(testUri);

        // Verify token URI is set correctly
        assertEq(basicNft.tokenURI(tokenId), testUri);
    }
}
