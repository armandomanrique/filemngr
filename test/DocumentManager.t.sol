// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/forge-std/src/Test.sol";
import "../documentRec.sol";

contract DocumentManagerTest is Test {
    DocumentManager public documentManager;
    
    // Test accounts
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);
    
    // Test data
    bytes32 public testHash1 = keccak256("test document 1");
    bytes32 public testHash2 = keccak256("test document 2");
    bytes32 public testHash3 = keccak256("test document 3");
    bytes public testSignature1 = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12";
    bytes public testSignature2 = "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890ab";
    bytes public testSignature3 = "0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba09";
    
    // Events
    event DocumentEntered(
        bytes32 indexed hash,
        address indexed signingAccount,
        bytes signature,
        uint256 timestamp
    );
    
    event DocumentVerified(string message);
    
    event DocumentListed(
        bytes32 hash,
        address signingAccount,
        bytes signature,
        uint256 timestamp
    );

    function setUp() public {
        // Deploy the contract
        documentManager = new DocumentManager();
        
        // Label addresses for better debugging
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(charlie, "Charlie");
        vm.label(address(documentManager), "DocumentManager");
    }

    // ============ enterDoc Tests ============

    function test_EnterDoc_Success() public {
        uint256 timestampBefore = block.timestamp;
        
        vm.expectEmit(true, true, false, true);
        emit DocumentEntered(
            testHash1,
            alice,
            testSignature1,
            block.timestamp
        );
        
        documentManager.enterDoc(testHash1, alice, testSignature1);
        
        // Verify document was stored correctly
        (bytes32 hash, address signingAccount, bytes memory signature, uint256 timestamp) = 
            documentManager.getDocument(testHash1);
        
        assertEq(hash, testHash1, "Hash mismatch");
        assertEq(signingAccount, alice, "Signing account mismatch");
        assertEq(signature, testSignature1, "Signature mismatch");
        assertGe(timestamp, timestampBefore, "Timestamp should be >= block.timestamp");
        
        // Verify document count increased
        assertEq(documentManager.getDocumentCount(), 1, "Document count should be 1");
    }

    function test_EnterDoc_RevertWhen_InvalidAddress() public {
        vm.expectRevert("Signing account must be a valid address");
        documentManager.enterDoc(testHash1, address(0), testSignature1);
    }

    function test_EnterDoc_RevertWhen_HashAlreadyExists() public {
        documentManager.enterDoc(testHash1, alice, testSignature1);
        
        vm.expectRevert("Hash already exists in contract");
        documentManager.enterDoc(testHash1, bob, testSignature2);
    }

    function test_EnterDoc_EmptySignature() public {
        bytes memory emptySignature = "";
        documentManager.enterDoc(testHash1, alice, emptySignature);
        
        (bytes32 hash, address signingAccount, bytes memory signature, ) = 
            documentManager.getDocument(testHash1);
        
        assertEq(hash, testHash1, "Hash mismatch");
        assertEq(signingAccount, alice, "Signing account mismatch");
        assertEq(signature.length, 0, "Signature should be empty");
    }

    function test_EnterDoc_DifferentAccountsSameHash() public {
        // This should fail because hash already exists
        documentManager.enterDoc(testHash1, alice, testSignature1);
        
        vm.expectRevert("Hash already exists in contract");
        documentManager.enterDoc(testHash1, bob, testSignature1);
    }

    // ============ verifyDoc Tests ============

    function test_VerifyDoc_Success() public {
        documentManager.enterDoc(testHash1, alice, testSignature1);
        
        vm.expectEmit(false, false, false, true);
        emit DocumentVerified("El documento es correcto");
        
        string memory result = documentManager.verifyDoc(testHash1, alice);
        assertEq(result, "El documento es correcto", "Verification should succeed");
    }

    function test_VerifyDoc_DocumentDoesNotExist() public {
        vm.expectEmit(false, false, false, true);
        emit DocumentVerified("El documento no existe en el contrato");
        
        string memory result = documentManager.verifyDoc(testHash1, alice);
        assertEq(result, "El documento no existe en el contrato", "Should return document not found");
    }

    function test_VerifyDoc_WrongSigningAccount() public {
        documentManager.enterDoc(testHash1, alice, testSignature1);
        
        vm.expectEmit(false, false, false, true);
        emit DocumentVerified("El documento no fue firmado por la cuenta indicada");
        
        string memory result = documentManager.verifyDoc(testHash1, bob);
        assertEq(result, "El documento no fue firmado por la cuenta indicada", "Should return wrong account");
    }

    // ============ listDoc Tests ============

    function test_ListDoc_EmptyList() public {
        // Should not revert, just emit no events
        documentManager.listDoc();
        
        assertEq(documentManager.getDocumentCount(), 0, "Document count should be 0");
    }

    function test_ListDoc_SingleDocument() public {
        documentManager.enterDoc(testHash1, alice, testSignature1);
        
        vm.expectEmit(false, false, false, true);
        emit DocumentListed(
            testHash1,
            alice,
            testSignature1,
            block.timestamp
        );
        
        documentManager.listDoc();
    }

    // ============ getDocumentCount Tests ============

    function test_GetDocumentCount_Empty() public {
        assertEq(documentManager.getDocumentCount(), 0, "Initial count should be 0");
    }

    // ============ getDocument Tests ============

    function test_GetDocument_Success() public {
        documentManager.enterDoc(testHash1, alice, testSignature1);
        
        (bytes32 hash, address signingAccount, bytes memory signature, uint256 timestamp) = 
            documentManager.getDocument(testHash1);
        
        assertEq(hash, testHash1, "Hash mismatch");
        assertEq(signingAccount, alice, "Signing account mismatch");
        assertEq(signature, testSignature1, "Signature mismatch");
        assertEq(timestamp, block.timestamp, "Timestamp mismatch");
    }

    function test_GetDocument_RevertWhen_DoesNotExist() public {
        vm.expectRevert("Document does not exist");
        documentManager.getDocument(testHash1);
    }

    function test_GetDocument_AllFields() public {
        uint256 timestampBefore = block.timestamp;
        documentManager.enterDoc(testHash1, alice, testSignature1);
        
        (bytes32 hash, address signingAccount, bytes memory signature, uint256 timestamp) = 
            documentManager.getDocument(testHash1);
        
        assertEq(hash, testHash1);
        assertEq(signingAccount, alice);
        assertEq(signature, testSignature1);
        assertGe(timestamp, timestampBefore);
    }

    // ============ Integration Tests ============

    function test_Integration_FullWorkflow() public {
        // 1. Enter document
        documentManager.enterDoc(testHash1, alice, testSignature1);
        
        // 2. Verify document exists
        assertEq(documentManager.getDocumentCount(), 1, "Should have 1 document");
        
        // 3. Get document
        (bytes32 hash, address account, , ) = documentManager.getDocument(testHash1);
        assertEq(hash, testHash1, "Hash should match");
        assertEq(account, alice, "Account should match");
        
        // 4. Verify document
        string memory result = documentManager.verifyDoc(testHash1, alice);
        assertEq(result, "El documento es correcto", "Document should verify");
        
        // 5. List documents
        vm.expectEmit(false, false, false, true);
        emit DocumentListed(testHash1, alice, testSignature1, block.timestamp);
        documentManager.listDoc();
    }

    // ============ Edge Cases ============

    function test_EdgeCase_MaxSignatureLength() public {
        // Create a large signature
        bytes memory largeSignature = new bytes(1000);
        for (uint i = 0; i < 1000; i++) {
            largeSignature[i] = bytes1(uint8(i % 256));
        }
        
        documentManager.enterDoc(testHash1, alice, largeSignature);
        
        (bytes32 hash, , bytes memory retrievedSignature, ) = 
            documentManager.getDocument(testHash1);
        
        assertEq(hash, testHash1);
        assertEq(retrievedSignature.length, 1000, "Signature length should match");
        assertEq(retrievedSignature, largeSignature, "Signature should match");
    }

}
