# NFiT Core Contracts

## How to test this contracts using remix

We meet some problems when deploy contracts on aurora testnet

1. change metamask to aurora testnet
2. add solidity file NFiTMarket.sol and MathArt.sol to remix 
![1631616483(1)](https://user-images.githubusercontent.com/25214732/133244383-8146e928-b5a7-4bd6-bf3d-64014ae1f1de.png)

3. compile NFiTMarket.sol first, and deploy it to get the address of the contract.
    Notice : ENVIRONMENT please choose Injected Web3 to connect with metamask.
    When deploy contract, the metamask will be called to pay the gas(which is 0 on aurora testnet now).
    
    
4. Then compile MathArt.sol, when deploy MathArt.sol, please input the address of **NFiTmarket.sol**.

![1631616827(1)](https://user-images.githubusercontent.com/25214732/133245118-cb14c777-3108-4c8d-a560-4b63fd5aea06.png)
5. use the deployment of MathArt.sol to call function createToken, the input is a string to show the url of NFT(You can input any string for test) 

6. call the function uploadNFT of NFiTMarket.sol 

    nftContract is the address of MathArt.sol 
    
    tokenId : the first one you can input "1"

    royalty: you can input any Integer between "1" to "100", for example "10".

7. then call the function sellNFT of NFiTMartket.sol
 to test you can input string below:
 
 
 itemId : "1"
 
 sellPrice: "100"
 
 loanPrice: "50"
 
 redeemPrice："100"
 
 deadlint: "1947150058"  
 
 and then we meet a problem : 
 ![1631617375(1)](https://user-images.githubusercontent.com/25214732/133246315-acd3c57f-87f7-40cd-b677-1f2d89f52fb1.png)
 
 the transaction hash is below:
 
 0xca8b0b8785ff4b20fa3c8929c1c8cc3c9019f590cbcf22ecc7a3d09e67535fdc
 
 Thanks for help very much !
