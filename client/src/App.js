import React, { Component } from "react";
import CrosschainTokenETH from "./contracts/CrosschainTokenETH.json";
import CrosschainTokenETC from "./contracts/CrosschainTokenETC.json";
import getWeb3 from "./utils/getWeb3";
import truffleContract from "truffle-contract";

import "./App.css";

class App extends Component {
  state = { storageValue: 0, web3: null, accounts: null, contract: null };

  componentDidMount = async () => {
    try {
      // Get network provider and web3 instance.
      const web3 = await getWeb3();

      // Use web3 to get the user's accounts.
      const accounts = await web3.eth.getAccounts();

      // Get the contract instance.
      const ETHContract = truffleContract(CrosschainTokenETH);
      const ETCContract = truffleContract(CrosschainTokenETC);
      ETHContract.setProvider(web3.currentProvider);
      ETCContract.setProvider(web3.currentProvider);
      const xChainEth = await ETHContract.deployed();
      const xChainEtc = await ETCContract.deployed();

      const self = this;
      xChainEth.CrosschainTransferred({}, (err, evt) => {
        console.log('ETH Chain:', 'Transferred',evt.args.amount,'to ETC chain successfully');
        self.update();
      });
      xChainEth.CrosschainSend({}, (err, evt) => {
        console.log('ETH Chain:', 'Crosschain Send Initialized for Amount',evt.args.amount,'to ETC chain successfully');

        xChainEtc.validateCrosschainTransfer(
          1,
          evt.transactionHash,
          evt.args.sourceAddress,
          evt.args.destinationChain,
          evt.args.destinationAddress,
          evt.args.amount,
          {from: accounts[0]}
        );
        console.log('ETH Chain:', 'called validateCrosschainTransfer on ETC Chain for Transaction',evt.transactionHash);
      });

      xChainEtc.CrosschainTransferred({}, (err, evt) => {
        console.log('ETC Chain:', 'Transferred',evt.args.amount.toString(),'to ETH chain successfully');
        self.update();
      });
      xChainEtc.CrosschainSend({}, (err, evt) => {
        console.log('ETC Chain:', 'Crosschain Send Initialized for Amount',evt.args.amount.toString(),'to ETH chain successfully');

        xChainEth.validateCrosschainTransfer(
          2,
          evt.transactionHash,
          evt.args.sourceAddress,
          evt.args.destinationChain,
          evt.args.destinationAddress,
          evt.args.amount,
          {from: accounts[0]}
        );
        console.log('ETC Chain:', 'called validateCrosschainTransfer on ETH Chain for Transaction',evt.transactionHash);
      });

      this.ethTransferVal = this.ethTransferVal.bind(this);
      this.etcTransferVal = this.etcTransferVal.bind(this);
      this.transferToEtc = this.transferToEtc.bind(this);
      this.transferToEth = this.transferToEth.bind(this);
      // Set web3, accounts, and contract to the state, and then proceed with an
      // example of interacting with the contract's methods.
      this.setState({ web3, accounts, ethContract: xChainEth, etcContract: xChainEtc }, this.update);
    } catch (error) {
      // Catch any errors for any of the above operations.
      alert(
        `Failed to load web3, accounts, or contract. Check console for details.`
      );
      console.log(error);
    }
  };

  update = async () => {
    const { accounts, ethContract, etcContract } = this.state;

    const ethChainBalance = await ethContract.balanceOf(accounts[0], { from: accounts[0] });
    const etcChainBalance = await etcContract.balanceOf(accounts[0], { from: accounts[0] });

    const ethTotalTokensOnChain = await ethContract.getTokensOnChain();
    const etcTotalTokensOnChain = await etcContract.getTokensOnChain();

    // Update state with the result.
    this.setState({
      ethChainBalance,
      etcChainBalance,
      ethTotalTokensOnChain,
      etcTotalTokensOnChain
    });
  };

  render() {
    if (!this.state.web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }

    return (
      <div className="App">
        <h2>ETH Chain</h2>
        <div>Token Balance: {this.state.ethChainBalance && this.state.ethChainBalance.toString()}</div>
        <div>Total Tokens on Chain: {this.state.ethTotalTokensOnChain && this.state.ethTotalTokensOnChain.toString()}</div>
        <div><label>Transfer to ETC Chain</label><input type="text" onChange={this.ethTransferVal}/><button onClick={this.transferToEtc}>Transfer</button></div>
        <h2>ETC Chain</h2>
        <div>Token Balance: {this.state.etcChainBalance && this.state.etcChainBalance.toString()}</div>
        <div>Total Tokens on Chain: {this.state.etcTotalTokensOnChain && this.state.etcTotalTokensOnChain.toString()}</div>
        <div><label>Transfer to ETH Chain</label><input type="text" onChange={this.etcTransferVal}/><button onClick={this.transferToEth}>Transfer</button></div>

      </div>
    );
  }

  ethTransferVal = (evt) => {
    this.setState({
      ethTransferVal: evt.target.value
    });
  }
  etcTransferVal = (evt) => {
    this.setState({
      etcTransferVal: evt.target.value
    });
  }

  transferToEtc = () => {
    const ethTransferVal = this.state.ethTransferVal;
    if (!ethTransferVal){
      alert('enter a value to transfer');
      return;
    }
    this.state.ethContract.initiateCrosschainSend(
      2, // destinationChain 2, ETC
      this.state.accounts[0],
      ethTransferVal,
      {from: this.state.accounts[0]}
    );
  }

  transferToEth = () => {
    const etcTransferVal = this.state.etcTransferVal;
    if (!etcTransferVal){
      alert('enter a value to transfer');
      return;
    }
    this.state.etcContract.initiateCrosschainSend(
      1, // destinationChain 1, ETH
      this.state.accounts[0],
      etcTransferVal,
      {from: this.state.accounts[0]}
    );
  }

}

export default App;
