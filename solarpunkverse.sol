// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract Solarpunks is Initializable, ERC721Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    mapping(uint256 => string) private _tokenMetadata;
    mapping(uint256 => bool) private _tokenExists;
    mapping(uint256 => address) private _metadataChangeApprovals;
    mapping(uint256 => string) private _newMetadataUrls;
    mapping(address => uint256[]) private userMintedTokens;

   
    function initialize() public initializer {
        __ERC721_init("Solarpunks", "SLRPNK");
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }
    uint256 private latestTokenId;
    function mint(address to, uint256 tokenId, string memory metadataUrl) public onlyOwner whenNotPaused nonReentrant {
        require(!_tokenExists[tokenId], "Token ID already exists");
        _mint(to, tokenId);
        _tokenMetadata[tokenId] = metadataUrl;
        _tokenExists[tokenId] = true;
        latestTokenId = tokenId;
        // Record minted token for the user
        userMintedTokens[to].push(tokenId);
    }

    function requestMetadataChange(uint256 tokenId, string memory newMetadataUrl) public whenNotPaused nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Only NFT owner can request change");
        _metadataChangeApprovals[tokenId] = msg.sender;
        _newMetadataUrls[tokenId] = newMetadataUrl; // Store the new metadata URL for approval
    }

    function approveMetadataChange(uint256 tokenId) public whenNotPaused nonReentrant onlyOwner {
        // require(_metadataChangeApprovals[tokenId] == msg.sender, "Not authorized to approve metadata change");

        // Update the metadata URL after approval
        _tokenMetadata[tokenId] = _newMetadataUrls[tokenId];

        // Reset the approval
        delete _metadataChangeApprovals[tokenId];
    }

    function burn(uint256 tokenId) public whenNotPaused nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Only NFT owner can burn token");
        _burn(tokenId);
        delete _tokenMetadata[tokenId];
        _tokenExists[tokenId] = false; // Update _tokenExists to mark the token as not existing
        delete _metadataChangeApprovals[tokenId];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_tokenExists[tokenId], "Token does not exist");
        return _tokenMetadata[tokenId];
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getMintedTokens(address user) public view returns (uint256[] memory) {
        return userMintedTokens[user];
    }

  function getAllRequests() public view returns (uint256[] memory, address[] memory) {
    uint256 totalRequests = 0;

    // Count the total number of requests
    for (uint256 tokenId = 0; tokenId <256; tokenId++) {
        if (_tokenExists[tokenId] && _metadataChangeApprovals[tokenId] != address(0)) {
            totalRequests++;
        }
    }

    // Initialize arrays with the correct size
    uint256[] memory requestedTokenIds = new uint256[](totalRequests);
    address[] memory owners = new address[](totalRequests);

    // Populate arrays with data
    uint256 index = 0;
    for (uint256 tokenId = 0; tokenId < 256; tokenId++) {
        if (_tokenExists[tokenId] && _metadataChangeApprovals[tokenId] != address(0)) {
            requestedTokenIds[index] = tokenId;
            owners[index] = ownerOf(tokenId);
            index++;
        }
    }

    return (requestedTokenIds, owners);
}
function rejectMetadataChange(uint256 tokenId) public onlyOwner whenNotPaused nonReentrant {
    require(_metadataChangeApprovals[tokenId] != address(0), "No metadata change request for this token");
    
    // Reset the approval
    delete _metadataChangeApprovals[tokenId];
    delete _newMetadataUrls[tokenId];
}
 function getLatestTokenId() public view returns (uint256) {
        return latestTokenId;
    }
}
