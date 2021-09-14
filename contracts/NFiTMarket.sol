//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFiTMarket {
    using SafeMath for uint256;
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

    mapping(uint256 => NFiTItem) public id2NFiTItem;

    function getCurrentItemId() external view returns (uint) {
        return _itemNum.current();
    }

    function getPublishedNFT() external view returns (NFiTItem[] memory itemList) {
        uint itemId = _itemNum.current();
        itemList = new NFiTItem[](itemId);
        uint idx = 0;
        for (uint i = 1; i <= itemId; i++) {
            if (id2NFiTItem[i].state == State.Published) {
                itemList[idx] = id2NFiTItem[i];
                idx += 1;
            }
        }
        return itemList;
    }

    function getUserOwnedNFT(address user) external view returns (NFiTItem[] memory itemList) {
        uint itemId = _itemNum.current();
        itemList = new NFiTItem[](itemId);
        uint idx = 0;
        for (uint i = 1; i <= itemId; i++) {
            if (id2NFiTItem[i].state == State.Normal && id2NFiTItem[i].owner == user) {
                itemList[idx] = id2NFiTItem[i];
                idx += 1;
            }
        }
        return itemList;
    }

    function getUserPawnedNFT(address user) external view returns (NFiTItem[] memory itemList) {
        uint itemId = _itemNum.current();
        itemList = new NFiTItem[](itemId);
        uint idx = 0;
        for (uint i = 1; i <= itemId; i++) {
            if (id2NFiTItem[i].state == State.Pawned && id2NFiTItem[i].owner == user) {
                itemList[idx] = id2NFiTItem[i];
                idx += 1;
            }
        }
        return itemList;
    }

    function getUserReceivedNFT(address user) external view returns (NFiTItem[] memory itemList) {
        uint itemId = _itemNum.current();
        itemList = new NFiTItem[](itemId);
        uint idx = 0;
        for (uint i = 1; i <= itemId; i++) {
            if (id2NFiTItem[i].state == State.Pawned && id2NFiTItem[i].pawnor == user) {
                itemList[idx] = id2NFiTItem[i];
                idx += 1;
            }
        }
        return itemList;
    }

    function getUserPublishedNFT(address user) external view returns (NFiTItem[] memory itemList) {
        uint itemId = _itemNum.current();
        itemList = new NFiTItem[](itemId);
        uint idx = 0;
        for (uint i = 1; i <= itemId; i++) {
            if (id2NFiTItem[i].state == State.Published && id2NFiTItem[i].owner == user) {
                itemList[idx] = id2NFiTItem[i];
                idx += 1;
            }
        }
        return itemList;
    }

    function getItemInfo(uint itemId) external view returns (NFiTItem memory) {
        return id2NFiTItem[itemId];
    }

    function uploadNFT(
        address nftContract,
        uint256 tokenId, 
        uint256 royalty) public returns (uint256 itemId) {
        _itemNum.increment();
        itemId = _itemNum.current();
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

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        return itemId;
    }

    function downloadNFT(uint itemId) public {
        require(id2NFiTItem[itemId].owner == msg.sender, "No permission to retrieve NFT");
        require(id2NFiTItem[itemId].state == State.Normal, "Not Normal State Now");

        id2NFiTItem[itemId].state = State.Retrieval;
        IERC721(id2NFiTItem[itemId].nftContract).transferFrom(address(this), msg.sender, id2NFiTItem[itemId].tokenId);
    }

    // set the NFT into Published state and prepare to sell or pawn it
    function sellNFT (uint itemId, uint sellPrice, uint loanPrice, uint redeemPrice, uint deadline) public {
        require(id2NFiTItem[itemId].owner == msg.sender, "No permission to sell NFT");
        require(id2NFiTItem[itemId].state == State.Normal, "Not Normal State Now");
        require(sellPrice > 0 || loanPrice > 0, "Choose either sell or loan");
        require(redeemPrice >= loanPrice, "The redeem price is less than loan price");
        require(deadline >= block.timestamp, "The deadline should be future");

        id2NFiTItem[itemId].state = State.Published;
        id2NFiTItem[itemId].sellPrice = sellPrice;
        id2NFiTItem[itemId].loanPrice = loanPrice;
        id2NFiTItem[itemId].redeemPrice = redeemPrice;
        id2NFiTItem[itemId].deadline = deadline;
    }

    // pay for the NFT, the value would be distributed to owner and creator
    function buyNFT (uint itemId) public payable {
        require(id2NFiTItem[itemId].owner != msg.sender, "Not allowed to buy your NFT");
        require(id2NFiTItem[itemId].state == State.Published, "The NFT is not in Published");
        require(id2NFiTItem[itemId].sellPrice > 0, "The NFT is not for sell");
        require(msg.value >= id2NFiTItem[itemId].sellPrice, "No enough value to buy");
        
        id2NFiTItem[itemId].state = State.Normal;
        id2NFiTItem[itemId].owner = payable(msg.sender);

        uint256 royaltyValue = (msg.value).mul(id2NFiTItem[itemId].royalty) / 100;
        id2NFiTItem[itemId].creator.transfer(royaltyValue);
        id2NFiTItem[itemId].owner.transfer(msg.value - royaltyValue);
    }

    // pay for the loan, the value would be distributed to the owner and creator
    function receiveNFT (uint itemId) public payable {
        require(id2NFiTItem[itemId].state == State.Published, "The NFT is not in Published");
        require(id2NFiTItem[itemId].loanPrice > 0, "The NFT is not for pawn");
        require(msg.value >= id2NFiTItem[itemId].loanPrice, "No enough value to loan");

        id2NFiTItem[itemId].state = State.Pawned;
        id2NFiTItem[itemId].pawnor = payable(msg.sender);
        
        uint royaltyValue = msg.value.mul(id2NFiTItem[itemId].royalty) / 100;
        id2NFiTItem[itemId].creator.transfer(royaltyValue);
        id2NFiTItem[itemId].owner.transfer(msg.value - royaltyValue);
    }

    // pay for the redeem, the value would be distributed to the pawnor and creator
    function redeemNFT (uint itemId) public payable {
        require(id2NFiTItem[itemId].owner == msg.sender, "No permission to redeem NFT");
        require(id2NFiTItem[itemId].state == State.Pawned, "The NFT is not in Pawned");
        require(msg.value >= id2NFiTItem[itemId].redeemPrice, "No enough value to loan");
        require(id2NFiTItem[itemId].deadline >= block.timestamp, "The NFT is due");

        id2NFiTItem[itemId].state = State.Normal;

        uint royaltyValue = msg.value.mul(id2NFiTItem[itemId].royalty) / 100;
        id2NFiTItem[itemId].creator.transfer(royaltyValue);
        id2NFiTItem[itemId].pawnor.transfer(msg.value - royaltyValue);
    }

    function retrieveNFT (uint itemId) public {
        require(id2NFiTItem[itemId].pawnor == msg.sender, "No permission to retrieve NFT");
        require(id2NFiTItem[itemId].state == State.Pawned, "The NFT is not in Pawned");
        require(id2NFiTItem[itemId].deadline < block.timestamp, "The NFT is not due");

        id2NFiTItem[itemId].owner = id2NFiTItem[itemId].pawnor;
        id2NFiTItem[itemId].state = State.Normal;
    }
}