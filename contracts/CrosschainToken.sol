pragma solidity ^0.4.23;

import "zeppelin/ownership/Ownable.sol";
import "zeppelin/token/StandardToken.sol";

/**
* - user on chainA calls initiateCrosschainSend with amount,
*   destinationChain, destinationAddress.
* - validators listening to CrosschainSend event on chainA will
*   send a transaction on destinationChain to mint "amount" of tokens
*   if validators vote > transferVotesThreshold,
*   then emit CrosschainTransferred
* - on destinationChain to destinationAddress using
* - an admin listening to CrosschainSend events on chainA and
* CrosschainReceive on chainB
**/
contract CrosschainToken is Ownable, StandardToken {
  using SafeMath for uint256;

  uint16 public chainId;

  struct CrosschainTransaction {
    uint16 sourceChain;
    bytes32 transactionHash;
    bytes20 sourceAddress;
    address destinationAddress;
    uint256 amount;
    uint16 votes;
    bool validated;
  }

  // keccak256(sourceChain, transactionHashOnSourceChain) => (CrosschainTransaction)
  mapping (bytes32 => CrosschainTransaction) transfersIn;

  // keccak256(sourceChain, transactionHashOnSourceChain) => (validatorAddress => isValidatedByValidator)
  mapping (bytes32 => mapping (address => bool)) isValidatedBy;

  // percent of validators necessary before minting tokens
  uint32 transferVotesThreshold;

  // numbers of validators
  uint32 validatorsCount;

  // validators
  mapping (address => bool) validators;

  // number of tokens on this chain
  uint256 tokensOnChain;

  // supported chains
  mapping (uint16 => bool) supportedChains;

  constructor() public {
    owner = msg.sender;
    validators[owner] = true;
    validatorsCount = 1;
    transferVotesThreshold = 1;

    // init chain 1 and 2
    supportedChains[1] = true;
    supportedChains[2] = true;
  }

  event CrosschainSend(
    uint16 sourceChain,
    address sourceAddress,
    uint16 destinationChain,
    bytes20 destinationAddress,
    uint256 amount
  );

  event CrosschainTransferred(
    uint16 sourceChain,
    bytes32 originatingTransactionHash,
    bytes20 sourceAddress,
    uint16 destinationChain,
    address destinationAddress,
    uint256 amount
  );

  event ValidatorAdded (
    address validatorAdded
  );

  event ValidatorRemoved (
    address validatorRemoved
  );

  event SupportedChainAdded (
    uint16 chainSymbol
  );

  event SupportedChainRemoved (
    uint16 chainSymbol
  );

  modifier isValidator(){
    require(validators[msg.sender]);
    _;
  }

  // Simple add validator method
  function addValidator(address validator, bool incrementVoteThreshold) public onlyOwner {
    require(!validators[validator]);
    validators[validator] = true;
    validatorsCount += 1;
    if (incrementVoteThreshold){
      transferVotesThreshold += 1;
    }

    emit ValidatorAdded(validator);
  }

  // Simple remove validator method.
  function removeValidator(address validator, bool decrementVoteThreshold) public onlyOwner {
    require(validators[validator]);
    require(validator != owner);
    validators[validator] = false;
    validatorsCount -= 1;
    if (decrementVoteThreshold){
      require(transferVotesThreshold > 1);
      transferVotesThreshold -= 1;
    }

    emit ValidatorRemoved(validator);
  }

  // Simple add supported chain method
  // assumes it's a public chain with a unique coin symbol
  // can be modified to ID a chain by it's host or other ids
  function addSupportedChain(uint16 chainId) public onlyOwner {
    require(!supportedChains[chainId]);
    supportedChains[chainId] = true;
    emit SupportedChainAdded(chainId);
  }

  // Simple add supported chain method
  // assumes it's a public chain with a unique coin symbol
  // can be modified to ID a chain by it's host or other ids
  // todo: validate that there is no pending crosschain transfers
  function removeSupportedChain(uint16 chainId) public onlyOwner {
    require(supportedChains[chainId]);
    supportedChains[chainId] = false;
    emit SupportedChainAdded(chainId);
  }

  function getTokensOnChain() public view returns (uint256 totalTokensOnChain) {
    return tokensOnChain;
  }

  function initiateCrosschainSend(
    uint16 destinationChain,
    bytes20 destinationAddress,
    uint256 amount
  ) public {
    require(amount > 0); // can be a different threshold to prevent spam
    // is chain supported
    require(supportedChains[destinationChain]);

    tokensOnChain = tokensOnChain.sub(amount);
    balances[msg.sender] = balances[msg.sender].sub(amount);

    emit CrosschainSend(
      chainId,
      msg.sender,
      destinationChain,
      destinationAddress,
      amount
    );
  }

  // method to be called by a validator after CrosschainSend
  // is emitted on a different chain.
  function validateCrosschainTransfer(
    uint16 sourceChain,
    bytes32 transactionHash,
    bytes20 sourceAddress,
    uint16 destinationChain,
    address destinationAddress,
    uint256 amount
  ) public isValidator { // can only be called by a known validator
    require(amount > 0); // can be a different threshold to prevent spam
    require(destinationChain == chainId); // validate that the appropriate chain is being transferred to

    // hash of source chain ID and the source transaction
    bytes32 chainTransactionHash = keccak256(abi.encodePacked(sourceChain, transactionHash));

    // check if cross chain transaction is already voted for at least once (initialized)
    if (transfersIn[chainTransactionHash].votes == 0){
      // if it's not, initialize it
      transfersIn[chainTransactionHash].sourceChain = sourceChain;
      transfersIn[chainTransactionHash].transactionHash = transactionHash;
      transfersIn[chainTransactionHash].sourceAddress = sourceAddress;
      transfersIn[chainTransactionHash].destinationAddress = destinationAddress;
      transfersIn[chainTransactionHash].amount = amount;

    } else {
      // if it's already initialized, validate it
      validateCrosschainTransfer(
        chainTransactionHash,
        transfersIn[chainTransactionHash],
        sourceChain,
        transactionHash,
        sourceAddress,
        destinationAddress,
        amount
      );

    }

    // add validator's vote
    isValidatedBy[chainTransactionHash][msg.sender] = true;
    transfersIn[chainTransactionHash].votes += 1;

    // if number of votes meets threshold, finalize transfer
    if (transfersIn[chainTransactionHash].votes >= transferVotesThreshold){
      tokensOnChain = tokensOnChain.add(amount);
      balances[destinationAddress] = balances[destinationAddress].add(amount);

      emit CrosschainTransferred(
        sourceChain,
        transactionHash,
        sourceAddress,
        destinationChain,
        destinationAddress,
        amount
      );
    }

  }

  // validates that CrosschainTransaction and arguments passed in are valid
  function validateCrosschainTransfer(
    bytes32 chainTransactionHash,
    CrosschainTransaction xchainTransaction,
    uint16 sourceChain,
    bytes32 transactionHash,
    bytes20 sourceAddress,
    address destinationAddress,
    uint256 amount
  ) private view {
    require(!isValidatedBy[chainTransactionHash][msg.sender]);            // not already validated by this validator
    require(xchainTransaction.sourceChain == sourceChain);
    require(xchainTransaction.transactionHash == transactionHash);
    require(xchainTransaction.sourceAddress == sourceAddress);
    require(xchainTransaction.destinationAddress == destinationAddress);
    require(xchainTransaction.amount == amount);
  }
}
