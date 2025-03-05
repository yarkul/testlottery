# Provably Random Raffle Contracts

## About
This code is to create a provably random smart contract lottery.

## What we want it to do?

1. Users can enter by paying for a ticket
2. After a period of time, the lottery will automatically draw a winner
   1. And this will be done programmatically
      1. Using Chainlink VRF & Chainlink Automation
         1. Chainlink VRF -> Randomness
         2. Chainlink Automation -> Time-based trigger