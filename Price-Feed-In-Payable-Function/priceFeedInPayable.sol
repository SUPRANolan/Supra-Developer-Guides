// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

//TODO: Add comments, pass feed contract address as param to constructor, import interface file

//interface to interact with price feed, refer to documentation https://supraoracles.com/docs/get-started
interface ISupraSValueFeed {
    function checkPrice(string memory marketPair) external view returns (int256 price, uint256 timestamp);
}
 
contract PayableEtherExample {
    int mintPrice;
    ISupraSValueFeed sValueFeed;
    address owner;
 
    constructor(){
        sValueFeed = ISupraSValueFeed(0x25DfdeD39bf0A4043259081Dc1a31580eC196ee7);
        mintPrice = 100;
        owner = msg.sender;
    }
 
     //modifier used for access control
    modifier onlyOwner(){
        require(msg.sender == owner, 'User is not the owner.');
        _;
    }
 
     //modifier used to validate the amount sent in the transaction
    modifier validAmount(){
        (int ethPrice,) = sValueFeed.checkPrice("eth_usdt");
        ethPrice = ethPrice * (10 ** 10);
        int mintPriceWei = mintPrice * (10 ** 18);
        int requiredAmount = (mintPriceWei * (10 ** 18)) / ethPrice;
        require(msg.value >= uint(requiredAmount), 'Not enough ETH sent.');
        _;
    }
 
     //arbitrary PAYABLE function with the validAmount modifier
    function mint() external payable validAmount() {
        //mint logic here
    }
 
     //withdraw function
    function withdraw(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }
 
}