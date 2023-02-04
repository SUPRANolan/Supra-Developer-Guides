# SupraOracles - Simple Ether to USDC Collateral loan (Part 1) //Solidity

This guide uses our S-Value Price Feeds to offer Ether to USDC collateral loans. EVM- Solidity

# Intro

This is a two-part guide to create a collateral loan contract. The goal of this contract will be to allow users to deposit ether and take a percentage loan out in USDC. The user will be required to pay off the loan within a designated timeframe and maintain a specific collateral percentage. Otherwise, the user will be liquidated. 

In part 1 of this guide, we’re going to create a simple smart contract that allows a user to deposit ether and withdraw a set percentage of that deposited amount as USDC (the loan). The user will be required to pay off the original loan amount plus with fees in order to be returned their ether collateral. The contract will track the amount of deposited ether that is being used as collateral for the loan as well as the amount of USDC that can still be borrowed. The user will be able to deposit more, take more loaned USDC, and withdraw available/unused ether.

In part 2, we will improve this smart contract by adding loan durations and functionality for maintaining a specific collateral-to-loan percentage to account for price fluctuations. Additionally, we will implement a function to liquidate loans in the event that the user is unable to pay it off within the designated duration or is unable to maintain a set collateral-to-loan percentage.For now, let's just focus on building the foundation in part 1.

# Getting started

Example: the available loan is equal to 80% of the available deposit/collateral with a fee of 10% on top of the loaned amount. If a user deposits 1 ether at the going exchange rate of $1,577.23, they would be able to withdraw a loan of $1,261.784 in USDC. Including the fee, the user will be required to pay $1,387.9624 to get their initial collateral of 1 ether back.

For this guide, we're going to make the following assumptions...

* One (1) loan per user, but the user can increase the loan amount by depositing and withdrawing again
* User must pay off the loan entirely in one (1) transaction.
* User can deposit more than once.
* User can call withdraw as long as they have available/unused ether deposited.
* Time to code

# Time to Code

## Dependencies

We'll need a way to convert the deposited ether to USDC. For this, we're going to need the current price of ETH. This is where Supra's S-Value Price Feed comes into play. We'll use the following interface to interact with the SupraSValueFeed smart contract. 

