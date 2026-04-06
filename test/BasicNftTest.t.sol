// SPDX-License-Identifier: MIT

pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {BasicNft} from "../src/BasicNft.sol";

contract BasicNftTest is Test {
    BasicNft public basicNft;
    address public owner;
    address public user1;
    address public user2;
    address public vault;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        vault = makeAddr("vault");

        basicNft = new BasicNft(
            "TestNFT",
            "TNFT" //"ipfs://initial/"
        );
    }

    // ============ CONSTRUCTOR TESTS ============

    function testConstructorInitializes() public view {
        assertEq(basicNft.tokenCounter(), 0);
        assertEq(basicNft.name(), "TestNFT");
        assertEq(basicNft.symbol(), "TNFT");
        assertEq(basicNft.mintFee(), 0.001 ether);
        assertEq(basicNft.owner(), owner);
    }

    function testConstructorSetsVaultAddress() public view {
        assertEq(basicNft.vaultAddress(), owner);
    }

    function testConstructorWhitelistsOwner() public view {
        assertTrue(basicNft.whitelistedTransferers(owner));
    }

    // ============ MINT NFT TESTS ============

    function testMintNftSucceedsWithExactFee() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);

        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        assertEq(tokenId, 0);
        assertEq(basicNft.tokenCounter(), 1);
        assertEq(basicNft.ownerOfNft(tokenId), user1);
    }

    function testMintNftSucceedsWithExcessFee() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);

        uint256 tokenId = basicNft.mintNft{value: 0.05 ether}("ipfs://token1/");

        assertEq(tokenId, 0);
        assertEq(basicNft.ownerOfNft(tokenId), user1);
    }

    function testMintNftFailsWithInsufficientFee() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);

        vm.expectRevert("Insufficient payment for NFT mint");
        basicNft.mintNft{value: 0.0001 ether}("ipfs://token1/");
    }

    function testMintNftFailsWithoutPayment() public {
        vm.prank(user1);

        vm.expectRevert("Insufficient payment for NFT mint");
        basicNft.mintNft("ipfs://token1/");
    }

    function testMintNftIncrementsTokenCounter() public {
        vm.deal(user1, 10 ether);
        vm.prank(user1);

        basicNft.mintNft{value: 0.001 ether}("ipfs://token1/");
        assertEq(basicNft.tokenCounter(), 1);

        basicNft.mintNft{value: 0.001 ether}("ipfs://token2/");
        assertEq(basicNft.tokenCounter(), 2);

        basicNft.mintNft{value: 0.001 ether}("ipfs://token3/");
        assertEq(basicNft.tokenCounter(), 3);
    }

    function testMintNftSetsTokenUri() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);

        string
            memory tokenUri = "ipfs://bafybeifm5jlemvhc4qcuw7arocpny35dso423hudnrckgbkwc2p5hi3r6y/";
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(tokenUri);

        assertEq(basicNft.tokenURI(tokenId), tokenUri);
    }

    function testMintNftLocksTokenByDefault() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);

        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        assertTrue(basicNft.isTokenLocked(tokenId));
    }

    function testMintNftEmitsNftMintedEvent() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);

        vm.expectEmit(true, true, false, true);
        emit BasicNft.NftMinted(user1, 0, "ipfs://token1/", 0.001 ether);

        basicNft.mintNft{value: 0.001 ether}("ipfs://token1/");
    }

    function testMintNftEmitsTokenLockedEvent() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);

        vm.expectEmit(true, true, false, false);
        emit BasicNft.TokenLocked(0, user1);

        basicNft.mintNft{value: 0.001 ether}("ipfs://token1/");
    }

    function testMintNftSequentialTokenIds() public {
        vm.deal(user1, 10 ether);
        vm.prank(user1);

        uint256 id1 = basicNft.mintNft{value: 0.001 ether}("ipfs://token1/");
        uint256 id2 = basicNft.mintNft{value: 0.001 ether}("ipfs://token2/");
        uint256 id3 = basicNft.mintNft{value: 0.001 ether}("ipfs://token3/");

        assertEq(id1, 0);
        assertEq(id2, 1);
        assertEq(id3, 2);
    }

    // ============ OWNER OF NFT TESTS ============

    function testOwnerOfNftReturnsCorrectOwner() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        assertEq(basicNft.ownerOfNft(tokenId), user1);
    }

    function testOwnerOfNftRevertsForNonexistentToken() public {
        vm.expectRevert();
        basicNft.ownerOfNft(999);
    }

    function testOwnerOfNftMultipleTokens() public {
        vm.deal(user1, 10 ether);
        vm.prank(user1);

        uint256 token1 = basicNft.mintNft{value: 0.001 ether}("ipfs://token1/");
        uint256 token2 = basicNft.mintNft{value: 0.001 ether}("ipfs://token2/");

        assertEq(basicNft.ownerOfNft(token1), user1);
        assertEq(basicNft.ownerOfNft(token2), user1);
    }

    // ============ TOKEN URI TESTS ============

    function testTokenUriReturnsCorrectUri() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);

        string memory testUri = "ipfs://QmTest123/metadata.json";
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(testUri);

        assertEq(basicNft.tokenURI(tokenId), testUri);
    }

    function testTokenUriRevertsForNonexistentToken() public {
        vm.expectRevert();
        basicNft.tokenURI(999);
    }

    function testTokenUriDifferentForDifferentTokens() public {
        vm.deal(user1, 10 ether);
        vm.prank(user1);

        uint256 token1 = basicNft.mintNft{value: 0.001 ether}("ipfs://uri1/");
        uint256 token2 = basicNft.mintNft{value: 0.001 ether}("ipfs://uri2/");

        assert(
            keccak256(abi.encodePacked(basicNft.tokenURI(token1))) !=
                keccak256(abi.encodePacked(basicNft.tokenURI(token2)))
        );
    }

    // ============ IS TOKEN OWNER TESTS ============

    function testIsTokenOwnerReturnsTrue() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        assertTrue(basicNft.isTokenOwner(tokenId, user1));
    }

    function testIsTokenOwnerReturnsFalse() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        assertFalse(basicNft.isTokenOwner(tokenId, user2));
    }

    function testIsTokenOwnerReturnsFalseForNonexistentToken() public view {
        assertFalse(basicNft.isTokenOwner(999, user1));
    }

    // ============ LOCK TOKEN TESTS ============

    function testLockTokenByOwner() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        vm.prank(user1);
        basicNft.unlockToken(tokenId);

        assertFalse(basicNft.isTokenLocked(tokenId));

        vm.prank(user1);
        basicNft.lockToken(tokenId);

        assertTrue(basicNft.isTokenLocked(tokenId));
    }

    function testLockTokenFailsIfNotOwner() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        vm.prank(user1);
        basicNft.unlockToken(tokenId);

        vm.prank(user2);
        vm.expectRevert("Only token owner can lock");
        basicNft.lockToken(tokenId);
    }

    function testLockTokenEmitsEvent() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        vm.prank(user1);
        basicNft.unlockToken(tokenId);

        vm.prank(user1);
        vm.expectEmit(true, true, false, false);
        emit BasicNft.TokenLocked(tokenId, user1);
        basicNft.lockToken(tokenId);
    }

    // ============ UNLOCK TOKEN TESTS ============

    function testUnlockTokenByOwner() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        assertTrue(basicNft.isTokenLocked(tokenId));

        vm.prank(user1);
        basicNft.unlockToken(tokenId);

        assertFalse(basicNft.isTokenLocked(tokenId));
    }

    function testUnlockTokenFailsIfNotOwner() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        vm.prank(user2);
        vm.expectRevert("Only token owner can unlock");
        basicNft.unlockToken(tokenId);
    }

    function testUnlockTokenEmitsEvent() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        vm.prank(user1);
        vm.expectEmit(true, true, false, false);
        emit BasicNft.TokenUnlocked(tokenId, user1);
        basicNft.unlockToken(tokenId);
    }

    // ============ IS TOKEN LOCKED TESTS ============

    function testIsTokenLockedReturnsTrueForLockedToken() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        assertTrue(basicNft.isTokenLocked(tokenId));
    }

    function testIsTokenLockedReturnsFalseForUnlockedToken() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        vm.prank(user1);
        basicNft.unlockToken(tokenId);

        assertFalse(basicNft.isTokenLocked(tokenId));
    }

    // ============ TRANSFER FROM TESTS ============

    function testTransferFromFailsIfTokenLocked() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        vm.prank(user1);
        vm.expectRevert("Token is security-locked and cannot be transferred");
        basicNft.transferFrom(user1, user2, tokenId);
    }

    function testTransferFromSucceedsWhenUnlockedByOwner() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        vm.prank(user1);
        basicNft.unlockToken(tokenId);

        vm.prank(user1);
        basicNft.transferFrom(user1, user2, tokenId);

        assertEq(basicNft.ownerOfNft(tokenId), user2);
    }

    function testTransferFromFailsIfNotAuthorized() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        vm.prank(user1);
        basicNft.unlockToken(tokenId);

        vm.prank(user2);
        vm.expectRevert("Unauthorized transfer attempt");
        basicNft.transferFrom(user1, user2, tokenId);
    }

    function testTransferFromSucceedsIfWhitelisted() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        vm.prank(user1);
        basicNft.unlockToken(tokenId);

        vm.prank(owner);
        basicNft.whitelistTransferer(user2);

        vm.prank(user2);
        basicNft.transferFrom(user1, user2, tokenId);

        assertEq(basicNft.ownerOfNft(tokenId), user2);
    }

    function testTransferFromSucceedsIfFromIsApproved() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        vm.prank(user1);
        basicNft.unlockToken(tokenId);

        vm.prank(user1);
        basicNft.approve(user2, tokenId);

        vm.prank(user2);
        basicNft.transferFrom(user1, user2, tokenId);

        assertEq(basicNft.ownerOfNft(tokenId), user2);
    }

    // ============ SAFE TRANSFER FROM TESTS ============

    function testSafeTransferFromFailsIfTokenLocked() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        vm.prank(user1);
        vm.expectRevert("Token is security-locked and cannot be transferred");
        basicNft.safeTransferFrom(user1, user2, tokenId, "");
    }

    function testSafeTransferFromSucceedsWhenUnlockedByOwner() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        vm.prank(user1);
        basicNft.unlockToken(tokenId);

        vm.prank(user1);
        basicNft.safeTransferFrom(user1, user2, tokenId, "");

        assertEq(basicNft.ownerOfNft(tokenId), user2);
    }

    function testSafeTransferFromFailsIfNotAuthorized() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        vm.prank(user1);
        basicNft.unlockToken(tokenId);

        vm.prank(user2);
        vm.expectRevert("Unauthorized transfer attempt");
        basicNft.safeTransferFrom(user1, user2, tokenId, "");
    }

    function testSafeTransferFromSucceedsIfWhitelisted() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        vm.prank(user1);
        basicNft.unlockToken(tokenId);

        vm.prank(owner);
        basicNft.whitelistTransferer(user2);

        vm.prank(user2);
        basicNft.safeTransferFrom(user1, user2, tokenId, "");

        assertEq(basicNft.ownerOfNft(tokenId), user2);
    }

    // ============ SET MINT FEE TESTS ============

    function testSetMintFeeByOwner() public {
        assertEq(basicNft.mintFee(), 0.001 ether);

        vm.prank(owner);
        basicNft.setMintFee(0.01 ether);

        assertEq(basicNft.mintFee(), 0.01 ether);
    }

    function testSetMintFeeFailsIfNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        basicNft.setMintFee(0.01 ether);
    }

    function testSetMintFeeZero() public {
        vm.prank(owner);
        basicNft.setMintFee(0);

        assertEq(basicNft.mintFee(), 0);
    }

    function testSetMintFeeEnforcesNewFee() public {
        vm.prank(owner);
        basicNft.setMintFee(0.01 ether);

        vm.deal(user1, 1 ether);
        vm.prank(user1);
        vm.expectRevert("Insufficient payment for NFT mint");
        basicNft.mintNft{value: 0.001 ether}("ipfs://token1/");
    }

    // ============ SET VAULT ADDRESS TESTS ============

    function testSetVaultAddressByOwner() public {
        assertEq(basicNft.vaultAddress(), owner);

        vm.prank(owner);
        basicNft.setVaultAddress(vault);

        assertEq(basicNft.vaultAddress(), vault);
    }

    function testSetVaultAddressFailsIfNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        basicNft.setVaultAddress(vault);
    }

    function testSetVaultAddressFailsWithZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("Invalid vault address");
        basicNft.setVaultAddress(address(0));
    }

    // ============ WITHDRAW FEES TESTS ============

    function testWithdrawFeesSucceeds() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        basicNft.mintNft{value: 0.001 ether}("ipfs://token1/");

        uint256 contractBalance = address(basicNft).balance;
        assertEq(contractBalance, 0.001 ether);

        vm.prank(owner);
        basicNft.withdrawFees();

        assertEq(address(basicNft).balance, 0);
    }

    function testWithdrawFeesFailsIfNoBalance() public {
        vm.prank(owner);
        vm.expectRevert("No fees to withdraw");
        basicNft.withdrawFees();
    }

    function testWithdrawFeesEmitsEvent() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        basicNft.mintNft{value: 0.001 ether}("ipfs://token1/");

        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit BasicNft.FeeWithdrawn(owner, 0.001 ether);
        basicNft.withdrawFees();
    }

    function testWithdrawFeesTransfersToVault() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        basicNft.mintNft{value: 0.001 ether}("ipfs://token1/");

        vm.prank(owner);
        basicNft.setVaultAddress(vault);

        vm.prank(owner);
        basicNft.withdrawFees();

        assertEq(vault.balance, 0.001 ether);
    }

    function testWithdrawFeesMultipleTimes() public {
        vm.deal(user1, 2 ether);

        vm.prank(user1);
        basicNft.mintNft{value: 0.001 ether}("ipfs://token1/");

        vm.prank(owner);
        basicNft.withdrawFees();
        assertEq(address(basicNft).balance, 0);

        vm.prank(user1);
        basicNft.mintNft{value: 0.001 ether}("ipfs://token2/");

        vm.prank(owner);
        basicNft.withdrawFees();
        assertEq(address(basicNft).balance, 0);
    }

    // ============ WHITELIST TRANSFERER TESTS ============

    function testWhitelistTransfererByOwner() public {
        assertFalse(basicNft.whitelistedTransferers(user1));

        vm.prank(owner);
        basicNft.whitelistTransferer(user1);

        assertTrue(basicNft.whitelistedTransferers(user1));
    }

    function testWhitelistTransfererFailsIfNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        basicNft.whitelistTransferer(user2);
    }

    function testWhitelistTransfererAllowsTransfer() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        vm.prank(user1);
        basicNft.unlockToken(tokenId);

        vm.prank(owner);
        basicNft.whitelistTransferer(user2);

        vm.prank(user2);
        basicNft.transferFrom(user1, user2, tokenId);

        assertEq(basicNft.ownerOfNft(tokenId), user2);
    }

    // ============ REMOVE TRANSFERER WHITELIST TESTS ============

    function testRemoveTransfererWhitelistByOwner() public {
        vm.prank(owner);
        basicNft.whitelistTransferer(user1);
        assertTrue(basicNft.whitelistedTransferers(user1));

        vm.prank(owner);
        basicNft.removeTransfererWhitelist(user1);
        assertFalse(basicNft.whitelistedTransferers(user1));
    }

    function testRemoveTransfererWhitelistFailsIfNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        basicNft.removeTransfererWhitelist(user2);
    }

    function testRemoveTransfererWhitelistPreventsTransfer() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = basicNft.mintNft{value: 0.001 ether}(
            "ipfs://token1/"
        );

        vm.prank(user1);
        basicNft.unlockToken(tokenId);

        vm.prank(owner);
        basicNft.whitelistTransferer(user2);

        vm.prank(owner);
        basicNft.removeTransfererWhitelist(user2);

        vm.prank(user2);
        vm.expectRevert("Unauthorized transfer attempt");
        basicNft.transferFrom(user1, user2, tokenId);
    }

    // ============ RECEIVE TESTS ============

    function testReceiveEth() public {
        vm.deal(user1, 1 ether);

        vm.prank(user1);
        (bool success, ) = address(basicNft).call{value: 0.5 ether}("");

        assertTrue(success);
        assertEq(address(basicNft).balance, 0.5 ether);
    }

    function testReceiveEthMultipleTimes() public {
        vm.deal(user1, 3 ether);
        vm.deal(user2, 3 ether);

        vm.prank(user1);
        (bool success1, ) = address(basicNft).call{value: 0.5 ether}("");
        assertTrue(success1);

        vm.prank(user2);
        (bool success2, ) = address(basicNft).call{value: 0.3 ether}("");
        assertTrue(success2);

        assertEq(address(basicNft).balance, 0.8 ether);
    }

    // ============ TOKENS OF OWNER TESTS ============

    function testTokensOfOwnerEmpty() public view {
        uint256[] memory tokens = basicNft.tokensOfOwner(user1);
        assertEq(tokens.length, 0);
    }

    function testTokensOfOwnerSingleToken() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        basicNft.mintNft{value: 0.001 ether}("ipfs://token1/");

        uint256[] memory tokens = basicNft.tokensOfOwner(user1);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], 0);
    }

    function testTokensOfOwnerMultipleTokens() public {
        vm.deal(user1, 10 ether);
        vm.prank(user1);

        basicNft.mintNft{value: 0.001 ether}("ipfs://token1/");
        basicNft.mintNft{value: 0.001 ether}("ipfs://token2/");
        basicNft.mintNft{value: 0.001 ether}("ipfs://token3/");

        uint256[] memory tokens = basicNft.tokensOfOwner(user1);
        assertEq(tokens.length, 3);
        assertEq(tokens[0], 0);
        assertEq(tokens[1], 1);
        assertEq(tokens[2], 2);
    }

    function testTokensOfOwnerAfterTransfer() public {
        vm.deal(user1, 10 ether);
        vm.prank(user1);

        uint256 token1 = basicNft.mintNft{value: 0.001 ether}("ipfs://token1/");
        uint256 token2 = basicNft.mintNft{value: 0.001 ether}("ipfs://token2/");

        vm.prank(user1);
        basicNft.unlockToken(token1);

        vm.prank(user1);
        basicNft.transferFrom(user1, user2, token1);

        uint256[] memory user1Tokens = basicNft.tokensOfOwner(user1);
        uint256[] memory user2Tokens = basicNft.tokensOfOwner(user2);

        assertEq(user1Tokens.length, 1);
        assertEq(user1Tokens[0], token2);

        assertEq(user2Tokens.length, 1);
        assertEq(user2Tokens[0], token1);
    }

    function testTokensOfOwnerMixedOwners() public {
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);

        vm.prank(user1);
        basicNft.mintNft{value: 0.001 ether}("ipfs://token1/");
        basicNft.mintNft{value: 0.001 ether}("ipfs://token2/");

        vm.prank(user2);
        basicNft.mintNft{value: 0.001 ether}("ipfs://token3/");

        uint256[] memory user1Tokens = basicNft.tokensOfOwner(user1);
        uint256[] memory user2Tokens = basicNft.tokensOfOwner(user2);

        assertEq(user1Tokens.length, 2);
        assertEq(user2Tokens.length, 1);
    }

    // ============ INTEGRATION TESTS ============

    function testCompleteWorkflow() public {
        // Setup
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);

        // Mint tokens
        vm.prank(user1);
        uint256 token1 = basicNft.mintNft{value: 0.001 ether}("ipfs://token1/");

        vm.prank(user2);
        uint256 token2 = basicNft.mintNft{value: 0.001 ether}("ipfs://token2/");

        // Verify ownership
        assertEq(basicNft.ownerOfNft(token1), user1);
        assertEq(basicNft.ownerOfNft(token2), user2);

        // Unlock and transfer
        vm.prank(user1);
        basicNft.unlockToken(token1);

        vm.prank(user1);
        basicNft.transferFrom(user1, user2, token1);

        // Verify new ownership
        assertEq(basicNft.ownerOfNft(token1), user2);

        // Verify tokens of owner
        uint256[] memory user2Tokens = basicNft.tokensOfOwner(user2);
        assertEq(user2Tokens.length, 2);

        // Withdraw fees
        assertEq(address(basicNft).balance, 0.002 ether);

        vm.prank(owner);
        basicNft.withdrawFees();
        assertEq(address(basicNft).balance, 0);
    }
}
