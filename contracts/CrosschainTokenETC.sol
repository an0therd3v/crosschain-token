pragma solidity ^0.4.23;

import './CrosschainToken.sol';

contract CrosschainTokenETC is CrosschainToken {
  string public constant name = "XChainToken";
  string public constant symbol = "XCH";
  uint8 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 10000 * (10 ** uint256(decimals));
  uint16 public constant CHAIN_ID = 2;

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  constructor() public {
    totalSupply = INITIAL_SUPPLY;
    // ETC Chain starts with 0 tokens allocated on it
    tokensOnChain = 0;
    chainId = CHAIN_ID;
    balances[msg.sender] = tokensOnChain;
  }
}
