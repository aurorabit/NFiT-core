//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";

contract MathArt is ERC721Full {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    address public marketAddress;

    constructor(address marketplaceAddress) public ERC721Full("MathArt", "MAT") {
        marketAddress = marketplaceAddress;
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
