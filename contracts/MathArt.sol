//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MathArt is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    address public marketAddress;

    constructor(address marketplaceAddress) ERC721("MathArt", "MAT") {
        marketAddress = marketplaceAddress;
    }

    function updateMarketAddress(address _marketAddress) public {
        marketAddress = _marketAddress;
    }

    function getCurrentItemId() external view returns (uint) {
        return _tokenIds.current();
    }

    function createToken(string memory tokenURI) public returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);

        setApprovalForAll(marketAddress, true);
        return newItemId;
    }
}
