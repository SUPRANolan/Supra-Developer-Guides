# SupraOracles - Using Price Feeds in payable functions // Solidity

This guide uses our S-Value Price Feeds to validate that the amount of ether sent to a payable function is greater than or equal to a defined dollar value. EVM - Solidity

# Intro

One common problem that developers may encounter is the need to accept a specific/correct amount of ether based on the going exchange rate.
Imagine this: you're creating an NFT project and want your minting price to be exactly $100. That is, whenever a user mints your token, they must also send the equivalent amount of USD in ETH based on the current exchange rate.

If the going rate of ETH is $2000 and the set minting price is $100, we would expect the user to send 0.05 ether ($100/$2000 = 0.05) in addition to the gas cost of calling the function. If the user sent too little, the transaction would revert.

This is where the S-Value price feeds come into play. In this guide, we will touch on the following.

|                       |          |
|----------------------------------|-------------------|
| Interfaces | Modifiers  |
| SupraOracles S-Value Price Feeds | Payable Functions |

*Note: For the sake of this guide, we won't be implementing the minting function/ERC-721 token. We'll focus solely on the use of price feeds to validate the amount sent to any payable function.*

# Time To Code

Our smart contract will primarily consist of the interface to interact with the Supra ISupraSValueFeed contract, 2 modifiers for access control and verifying the correct amount of ether, and 2 functions for minting/accepting payment and withdrawing any amount of ether stored in the contract.

## Contract and Declaration

First things first. We'll create a new contract with an empty constructor and declare the interface that will allow us to access the S-Value price feeds.
pragma solidity ^0.8.13;
 
```solidity
interface ISupraSValueFeed {
    function checkPrice(string memory marketPair) external view returns (int256 price, uint256 timestamp);
}
 
contract PayableEtherExample {
 
    constructor(){
    }
```

Now, we will declare three variables. The first is mintPrice() which will be used to store the minting price of our minting function. The second is the sValueFeed which will be used to create an instance of the ISupraSValueFeed contract using the interface that we previously defined. We will use sValueFeed to retrieve the price of ETH/USDT later. The third is owner which is the address of the user that deployed the contract. We will use this to stop any calls to our withdraw function that aren’t from the owner of the contract.

```solidity
pragma solidity ^0.8.13;
 
interface ISupraSValueFeed {
    function checkPrice(string memory marketPair) external view returns (int256 price, uint256 timestamp);
}
 
contract PayableEtherExample {
    int mintPrice;
    ISupraSValueFeed sValueFeed;
    address owner;
 
    constructor(){
    }
}
```


Within our constructor, we'll now set the contract address of the ISupraSValueFeed contract, minting price, and the owner address. To find the correct contract address, navigate to this link.

As we are working with the Ethereum Goerli TestNet, we'll grab the following address (note that our S-Value price feeds are currently available on over 36 networks): 0x25DfdeD39bf0A4043259081Dc1a31580eC196ee7

Once we have that address, we can go ahead and set it within the constructor along with our mintPrice and owner variable. Note that the value of owner is set as the address that deployed this contract (as the constructor is only called once at time of deployment).

```solidity
pragma solidity ^0.8.13;
 
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
}
```


Moving forward, we're now able to obtain the price value for ETH/USDT at any time using the following line of code (note that checkPrice() returns both a price and a timestamp). For this example, we'll only be working with "eth_usdt". However, you may find other market pairs here. 

```solidity
(int ethPrice, /* uint timestamp */) = sValueFeed.checkPrice("eth_usdt");
```

## Modifiers and Payable Functions

Now, we have a few more things to do. We need to define the modifier that'll be used to validate the amount of ether sent to the minting function, the mint() function itself, a modifier to restrict access to the withdraw() function, and the withdraw() function itself to withdraw ether from the contract.

We'll declare the modifier validAmount() and use it to check the amount of ether sent. It's important to note that as Solidity does not fully support floating point numbers, we must first convert our values into wei (18 points of precision) in order to make the comparison.

Here is the full code for our validAmount(), we'll go ahead and walk through this now.

```solidity
 modifier validAmount(){
        (int ethPrice, /* uint timestamp */) = sValueFeed.checkPrice("eth_usdt");
        ethPrice = ethPrice * (10 ** 10); 
        int mintPriceWei = mintPrice * (10 ** 18); 
        int requiredAmount = (mintPriceWei * (10 ** 18)) / ethPrice;
        require(msg.value >= uint(requiredAmount), 'Not enough ETH sent.');
        _; 
    }
```

The first step is to store the current price of ETH/USDT into the variable ethPrice using the line of code that we mentioned above.

```solidity
(int ethPrice, /* uint timestamp */) = sValueFeed.checkPrice("eth_usdt");
```

We'll now convert our retrieved ETH/USDT value into wei, as well as the minting price that we set within the contract constructor. We then complete some math on the two values to determine the required amount.

```solidity
ethPrice = ethPrice * (10 ** 10); //get from 8, to 18 points of precision
int mintPriceWei = mintPrice * (10 ** 18); //wei has 18 points of precision
int requiredAmount = (mintPriceWei * (10 ** 18)) / ethPrice; //price in wei
```

Next, we add in the line that checks for the requirement that the amount of ether sent with the transaction (msg.value - a global variable that provides the amount of ether sent as wei) is greater than or equal to our requiredAmount. If not, we revert the transaction and alert the user. Note that we must cast the requiredAmount from int to uint to perform the comparison with msg.value. Additionally, the _; instruction is used to define when we want to execute the function that the modifier is attached to. The _; instruction will be replaced by the actual function body for execution.

```solidity
require(msg.value >= uint(requiredAmount), 'Not enough ETH sent.');
_; 
```

Now that our modifier is declared, let's go ahead and define the function that would make use of the modifier. For the sake of this example, we will leave the minting logic empty. However, the important thing to note is the payable and validAmount() modifiers. This allows for the function to act as a payable function and receive payment while verifying that the amount sent to the function is correct before function execution begins.

```solidity
function mint() external payable validAmount() {
   //mint logic here
}
```

Almost done!

## Withdrawing

Now all we need to do is define a withdraw() function so that we're able to retrieve the ether sent to the contract. Along with this, we're going to want to restrict who can actually call the withdraw() function. There're a few different ways to do this, but for this example we'll use a simple onlyOwner modifier.  If you remember in the constructor above, we set the owner variable value equal to the address that deployed the contract.

```solidity
modifier onlyOwner(){
    require(msg.sender == owner, 'User is not the owner.');
    _;
}
```

That means that only transactions coming from the defined owner address will be able to call functions that apply the onlyOwner modifier. As such, here is our withdraw() function. This function transfers the balance of this contract address to any payable address that was passed as the parameter for the function call.

```solidity
function withdraw(address payable _to) external onlyOwner {
    _to.transfer(address(this).balance);
}
```

# Final Code

All in all, your completed contract will look like this: 

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
 
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
```

Note that while the mint() doesn't have any code, it will accept ether as payment because we've set it to payable. So any ether sent to the function will trigger the validAmount() modifier. If the amount is valid, the ether gets deposited into the contract balance which can be withdrawn by the owner. 

# Conclusion

From here, the world is your oyster. You may even want to add functions that allow you to update or retrieve the minting price (set/get functions) and a function to allow for transfer of ownership! Regardless, you can apply this concept to your minting contract for your 721/1155 tokens, any dApp, or whatever you have in mind. Happy building!