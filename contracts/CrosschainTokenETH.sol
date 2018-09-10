pragma solidity ^0.4.23;

import './CrosschainToken.sol';

contract CrosschainTokenETH is CrosschainToken {
  string public constant name = "XChainToken";
  string public constant symbol = "XCH";
  uint8 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 10000 * (10 ** uint256(decimals));
  uint16 public constant CHAIN_ID = 1;

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  constructor() public {
    totalSupply = INITIAL_SUPPLY;

    // ETH Chain starts with all tokens allocated on it
    tokensOnChain = INITIAL_SUPPLY;
    chainId = CHAIN_ID;

    balances[msg.sender] = tokensOnChain;
  }
}
