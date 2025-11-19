// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DocumentManager {
    // Struct to store document information
    struct Document {
        bytes32 hash;
        address signingAccount;
        bytes signature;
        uint256 timestamp;
    }

    // Mapping to store documents by hash
    mapping(bytes32 => Document) private documents;
    
    // Array to store all document hashes for listing
    bytes32[] private documentHashes;

    // Event emitted when a document is entered
    event DocumentEntered(
        bytes32 indexed hash,
        address indexed signingAccount,
        bytes signature,
        uint256 timestamp
    );

    // Event emitted when a document is verified
    event DocumentVerified(string message);

    // Event emitted when listing documents
    event DocumentListed(
        bytes32 hash,
        address signingAccount,
        bytes signature,
        uint256 timestamp
    );

    /**
     * @dev Enter a new document into the contract
     * @param _hash The hash of the document
     * @param _signingAccount The account that signed the document
     * @param _signature The signature of the document
     */
    function enterDoc(
        bytes32 _hash,
        address _signingAccount,
        bytes memory _signature
    ) public {
        // Validate that signing account is a valid address
        require(_signingAccount != address(0), "Signing account must be a valid address");
        
        // Validate that hash does not exist in contract
        require(documents[_hash].hash == bytes32(0), "Hash already exists in contract");

        // Store the document
        documents[_hash] = Document({
            hash: _hash,
            signingAccount: _signingAccount,
            signature: _signature,
            timestamp: block.timestamp
        });

        // Add hash to array for listing
        documentHashes.push(_hash);

        // Emit event with the four parameters
        emit DocumentEntered(
            _hash,
            _signingAccount,
            _signature,
            block.timestamp
        );
    }

    /**
     * @dev Verify a document
     * @param _hash The hash of the document to verify
     * @param _signingAccount The account that should have signed the document
     * @return message The verification result message
     */
    function verifyDoc(
        bytes32 _hash,
        address _signingAccount
    ) public returns (string memory) {
        // Check if hash exists in contract
        if (documents[_hash].hash == bytes32(0)) {
            emit DocumentVerified("El documento no existe en el contrato");
            return "El documento no existe en el contrato";
        }

        // Check if received account matches signing account
        if (documents[_hash].signingAccount != _signingAccount) {
            emit DocumentVerified("El documento no fue firmado por la cuenta indicada");
            return "El documento no fue firmado por la cuenta indicada";
        }

        // Document is correct
        emit DocumentVerified("El documento es correcto");
        return "El documento es correcto";
    }

    /**
     * @dev List all stored documents
     */
    function listDoc() public {
        // Emit event for each stored document
        for (uint256 i = 0; i < documentHashes.length; i++) {
            bytes32 docHash = documentHashes[i];
            Document memory doc = documents[docHash];
            
            emit DocumentListed(
                doc.hash,
                doc.signingAccount,
                doc.signature,
                doc.timestamp
            );
        }
    }

    /**
     * @dev Get the total number of documents
     * @return The number of documents stored
     */
    function getDocumentCount() public view returns (uint256) {
        return documentHashes.length;
    }

    /**
     * @dev Get document information by hash
     * @param _hash The hash of the document
     * @return hash signingAccount signature timestamp
     */
    function getDocument(bytes32 _hash) public view returns (
        bytes32 hash,
        address signingAccount,
        bytes memory signature,
        uint256 timestamp
    ) {
        require(documents[_hash].hash != bytes32(0), "Document does not exist");
        Document memory doc = documents[_hash];
        return (doc.hash, doc.signingAccount, doc.signature, doc.timestamp);
    }
}
