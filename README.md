# crosschain-token
### Solution
The presented problem largely relies on availability of communication between two chains.

If two chains were able to pass validated data back and forth, a contract can be created to allow the transfer of tokens from one chain to another, but that is not possible as of today.

The task requires validated data to be transported securely from chain A to chain B to validate the intent to transfer from chain A to chain B, locking up/burning of tokens in chain A and minting/releasing of tokens on chain B.

As of today, oracle solutions are limited in what they can provide in terms of reliability and consistency, so for that particular solution I decided to rely on a trusted party or potentially a consortium of parties, known from here on as 'validators.'

For this a user U1 on chain A is able to initiate a crosschain transfer for N tokens to user U2 on chain B, which would burn those tokens and emit a CrosschainSend event with the following information: user U1 address, originating chain ID (an arbitrary number identifying the chain), user U2 address, destination chain ID, and amount of tokens in wei.

A validator or a set of validators can listen to the event and behave as trusted entities sending a confirmation transaction to chain B, confirming the transfer and minting the tokens.

Each validator will send transaction to validateCrosschainTransfer with the appropriate data received in the CrosschainSend event.

After a certain amount of validators have voted and a set threshold is met, the tokens are minted and transferred to user U2.

In this solution, we can mitigate potential of a single validator becoming compromised. Further incentives can be provided to keep the validators honest such as staking and validation rewards. Also, by setting a threshold of n out m validators as threshold for finalizing a transfer we prevent downtime caused by a 1 or more validator being offline in the case of n out n validators required to finalize a transfer.

For simplicity and demo purposes, the solution provided here is a single solidity contract that can be deployed to different EVM chains. This particular prototype uses a single chain of your choice, and deploys to contracts, where a single account assumes all roles, U1, U2 and validator.

Assumptions:
* A single user facilitates need to transfer, without a second counterparty, preventing the ability to implement a two user crosschain atomic swap
* The token transfer is provided by the validators as a service, and all gas/costs used to validate crosschain transfers is not reimbursed by the user.
* A simple user facing system can keep track of all crosschain transfer that are pending or completed to promote trust for the end user.

### Setup

#### Chain Host
Update the chain host, port, and network_id in truffle.js

Update websocket to the chain in client/src/getWeb3.js

#### Environment

requires truffle to be installed globally

run npm install in root

run npm install in client

#### Migrating Contracts and UI

force compile and migrate contracts:  truffle migrate --reset --compile-all

start ui: cd client && npm run start
