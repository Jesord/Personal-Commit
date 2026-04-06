/**
 * ERC721 mintable NFT
 * - mintNft: mints token to caller
 * - ownerOfNft: returns owner for given token id
 * - owner-only caller helpers can be built on top
 *
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.33;

import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract BasicNft is ERC721URIStorage, Ownable {
    uint256 public tokenCounter;
    uint256 public mintFee = 0.001 ether; // Fee to mint NFT
    address public vaultAddress; // Secure vault for collected fees

    mapping(uint256 => bool) public tokenLocked; // Security lock for tokens
    mapping(address => bool) public whitelistedTransferers; // Addresses allowed to transfer

    event NftMinted(address indexed minter, uint256 indexed tokenId, string tokenUri, uint256 mintPrice);
    event TokenLocked(uint256 indexed tokenId, address indexed owner);
    event TokenUnlocked(uint256 indexed tokenId, address indexed owner);
    event FeeWithdrawn(address indexed to, uint256 amount);

    constructor(
        string memory name,
        string memory symbol
        //string memory tokenUri
    )
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        tokenCounter = 0;
        vaultAddress = msg.sender;
        whitelistedTransferers[msg.sender] = true;
    }

    function mintNft(string calldata _tokenUri) external payable returns (uint256) {
        require(msg.value >= mintFee, "Insufficient payment for NFT mint");

        uint256 newTokenId = tokenCounter;
        tokenCounter++;

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _tokenUri);

        // Lock token for security upon minting
        tokenLocked[newTokenId] = true;

        emit NftMinted(msg.sender, newTokenId, _tokenUri, msg.value);
        emit TokenLocked(newTokenId, msg.sender);

        return newTokenId;
    }

    function ownerOfNft(uint256 tokenId) external view returns (address) {
        return ownerOf(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function isTokenOwner(uint256 tokenId, address account) external view returns (bool) {
        return ownerOf(tokenId) == account;
    }

    // Security: Lock/unlock tokens to prevent unauthorized transfers
    function lockToken(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Only token owner can lock");
        tokenLocked[tokenId] = true;
        emit TokenLocked(tokenId, msg.sender);
    }

    function unlockToken(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Only token owner can unlock");
        tokenLocked[tokenId] = false;
        emit TokenUnlocked(tokenId, msg.sender);
    }

    function isTokenLocked(uint256 tokenId) external view returns (bool) {
        return tokenLocked[tokenId];
    }

    // Override transfer functions to enforce security locks
    function transferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) {
        require(!tokenLocked[tokenId], "Token is security-locked and cannot be transferred");
        require(
            msg.sender == from || msg.sender == to || whitelistedTransferers[msg.sender] || msg.sender == owner(),
            "Unauthorized transfer attempt"
        );
        super.transferFrom(from, to, tokenId);
    }

    /**
     * function safeTransferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) {
     *     require(!tokenLocked[tokenId], "Token is security-locked and cannot be transferred");
     *     require(
     *         msg.sender == from || msg.sender == to || whitelistedTransferers[msg.sender] || msg.sender == owner(),
     *         "Unauthorized transfer attempt"
     *     );
     *     super.safeTransferFrom(from, to, tokenId);
     *
     */

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(IERC721, ERC721)
    {
        require(!tokenLocked[tokenId], "Token is security-locked and cannot be transferred");
        require(
            msg.sender == from || msg.sender == to || whitelistedTransferers[msg.sender] || msg.sender == owner(),
            "Unauthorized transfer attempt"
        );
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Owner functions for secure fee management
    function setMintFee(uint256 newFee) external onlyOwner {
        mintFee = newFee;
    }

    function setVaultAddress(address newVault) external onlyOwner {
        require(newVault != address(0), "Invalid vault address");
        vaultAddress = newVault;
    }

    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        (bool success,) = payable(vaultAddress).call{value: balance}("");
        require(success, "Withdrawal failed");
        emit FeeWithdrawn(vaultAddress, balance);
    }

    function whitelistTransferer(address transferer) external onlyOwner {
        whitelistedTransferers[transferer] = true;
    }

    function removeTransfererWhitelist(address transferer) external onlyOwner {
        whitelistedTransferers[transferer] = false;
    }

    // Receive ETH payments
    receive() external payable {}

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 supply = tokenCounter;
        uint256 count = 0;

        for (uint256 i = 0; i < supply; i++) {
            if (_ownerOf(i) != address(0) && ownerOf(i) == owner) {
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        uint256 idx = 0;
        for (uint256 i = 0; i < supply; i++) {
            if (_ownerOf(i) != address(0) && ownerOf(i) == owner) {
                result[idx++] = i;
            }
        }

        return result;
    }
}
