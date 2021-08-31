//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";

contract NFiTMarket {
    using Counters for Counters.Counter;
    Counters.Counter private _itemNum;

    enum State { Normal, Published, Pawned, Retrieval }

    struct NFiTItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable creator;
        address payable pawnor;
        address payable owner;
        uint256 sellPrice;
        uint256 loanPrice;
        uint256 redeemPrice;
        uint256 royalty;
        uint256 deadline;
        State state;
    }

    mapping(uint256 => NFiTItem) private id2NFiTItem;

    function uploadNFT(
        address nftContract,
        uint256 tokenId, 
        uint256 royalty) public returns (uint256) {
        _itemNum.increment();
        uint256 itemId = _itemNum.current();
        id2NFiTItem[itemId] = NFiTItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            payable(msg.sender),
            0,
            0,
            0,
            royalty,
            0,
            State.Normal
        );

        IERC721Full(nftContract).transferFrom(msg.sender, address(this), tokenId);
    }

    function retrieveNFT(uint itemId) public {
        require(id2NFiTItem[itemId].owner == msg.sender, "No permission to retrieve NFT");
        require(id2NFiTItem[itemId].state == State.Normal, "Not Normal State Now");

        id2NFiTItem[itemId].state = State.Retrieval;
        IERC721Full(nftContract).transferFrom(msg.sender, address(this), tokenId);
    }

    // set the NFT into Published state and prepare to sell or pawn it
    function sellNFT (uint itemId, uint32 sellPrice, uint32 loanPrice, uint32 redeemPrice, uint32 deadline) public {
        require(id2NFiTItem[itemId].state == State.Normal, "Not Normal State Now");
        require(id2NFiTItem[itemId].owner == msg.sender, "No permission to sell NFT");
        require(sellPrice > 0 || loanPrice > 0, "Choose either sell or loan");
        require(redeemPrice >= loanPrice, "The redeem price is less than loan price");

        id2NFiTItem[itemId].state = State.Published;
        id2NFiTItem[itemId].sellPrice = sellPrice;
        id2NFiTItem[itemId].loanPrice = loanPrice;
        id2NFiTItem[itemId].redeemPrice = redeemPrice;
        id2NFiTItem[itemId].deadline = deadline;
    }

    // pay for the NFT, the value would be distributed to owner and creator
    function buyNFT (uint itemId) public payable {
        require(id2NFiTItem[itemId].state == State.Published, "The NFT is not in Published");
        require(id2NFiTItem[itemId].sellPrice > 0, "The NFT is not for sell");
        require(msg.value >= id2NFiTItem[itemId].sellPrice, "No enough value to buy");
        
        id2NFiTItem[itemId].state = State.Normal;
        id2NFiTItem[itemId].owner = payable(msg.sender);

        uint256 royalityValue = (msg.value).mul(id2NFiTItem[itemId].royality) / 100;
        id2NFiTItem[itemId].creator.transfer(royalityValue);
        id2NFiTItem[itemId].owner.transfer(msg.value - royalityValue);
    }

    // pay for the loan, the value would be distributed to the owner and creator
    function receiveNFT (uint itemId) public payable {
        require(id2NFiTItem[itemId].state == State.Published, "The NFT is not in Published");
        require(msg.value >= id2NFiTItem[itemId].loanPrice, "No enough value to loan");

        id2NFiTItem[itemId].state = State.Pawned;
        id2NFiTItem[itemId].pawnor = payable(msg.sender);
        
        uint royalityValue = msg.value.mul(id2NFiTItem[itemId].royality) / 100;
        id2NFiTItem[itemId].creator.transfer(royalityValue);
        id2NFiTItem[itemId].owner.transfer(msg.value - royalityValue);
    }

    // pay for the redeem, the value would be distributed to the pawnor and creator
    function redeemNFT (uint itemId) public payable {
        require(id2NFiTItem[itemId].state == State.Pawned, "The NFT is not in Pawned");
        require(msg.value >= id2NFiTItem[itemId].redeemPrice, "No enough value to loan");
        require(id2NFiTItem[itemId].deadline >= block.timestamp, "The NFT is due");

        id2NFiTItem[itemId].state = State.Normal;

        uint royalityValue = msg.value.mul(item.royality) / 100;
        item.creator.transfer(royalityValue);
        item.pawnor.transfer(msg.value - royalityValue);
    }

    function retrieveNFT (uint id) public {
        NFT storage item = totalList[id];
        require(item.state == State.Pawned, "The NFT is not in Pawned");
        require(item.deadline < block.timestamp, "The NFT is not due");

        item.owner = item.pawnor;
        item.state = State.Normal;
    }
}