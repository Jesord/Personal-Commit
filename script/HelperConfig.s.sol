// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        string name;
        string symbol;
        string tokenUri;
        uint256 mintFee;
        address vaultAddress;
    }

    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant MAINNET_CHAIN_ID = 1;
    uint256 public constant LOCALHOST_CHAIN_ID = 31337;

    // Network configurations stored by chain ID
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;
    NetworkConfig public activeNetworkConfig;

    event NetworkConfigSet(uint256 indexed chainId);

    constructor() {
        // Setup configs for different networks
        setNetworkConfig(
            SEPOLIA_CHAIN_ID,
            NetworkConfig({
                name: "CrazyClowns",
                symbol: "CC",
                tokenUri: "ipfs://bafybeifm5jlemvhc4qcuw7arocpny35dso423hudnrckgbkwc2p5hi3r6y/",
                mintFee: 0.001 ether,
                vaultAddress: 0x480739ac1581923664A9593AB79Db9e10fb4aa2c
            })
        );
        //setNetworkConfig(MAINNET_CHAIN_ID, NetworkConfig());
        setNetworkConfig(
            LOCALHOST_CHAIN_ID,
            NetworkConfig({
                name: "CrazyClowns",
                symbol: "CC2",
                tokenUri: "ipfs://QmTestLocalMetadata/",
                mintFee: 0,
                vaultAddress: address(this)
            })
        );
    }

    /**
     * @notice Get the active network configuration based on current block.chainid
     * @return The NetworkConfig for the current chain
     */
    function getNetworkConfig() public view returns (NetworkConfig memory) {
        return getNetworkConfigByChainId(block.chainid);
    }

    /**
     * @notice Get network configuration by specific chain ID
     * @param chainId The chain ID to get config for
     * @return The NetworkConfig for the specified chain
     */
    function getNetworkConfigByChainId(uint256 chainId) public view returns (NetworkConfig memory) {
        activeNetworkConfig = networkConfigs[chainId];
        return activeNetworkConfig;
    }

    /**
     * @notice Set configuration for a specific network
     * @param chainId The chain ID to set config for
     * @param config The NetworkConfig to set
     */
    function setNetworkConfig(uint256 chainId, NetworkConfig memory config) public {
        networkConfigs[chainId] = config;
        emit NetworkConfigSet(chainId);
    }

    /**
     * @notice Get the current chain ID
     * @return The current block.chainid
     */
    function getChainId() public view returns (uint256) {
        return block.chainid;
    }

    /**
     * @notice Check if current network is Sepolia testnet
     * @return True if on Sepolia
     */
    function isSepolia() public view returns (bool) {
        return block.chainid == SEPOLIA_CHAIN_ID;
    }

    /**
     * @notice Check if current network is mainnet
     * @return True if on mainnet
     */
    function isMainnet() public view returns (bool) {
        return block.chainid == MAINNET_CHAIN_ID;
    }

    /**
     * @notice Check if current network is localhost
     * @return True if on localhost
     */
    function isLocalhost() public view returns (bool) {
        return block.chainid == LOCALHOST_CHAIN_ID;
    }
}
