// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;
  uint256 constant public THRESHOLD = 1 ether;
  uint256 public deadline = block.timestamp + 7 days;
  bool public openForWithdraw = false;

  mapping(address => uint256) public balances;

  event Stake(address indexed, uint256);

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  modifier b4Deadline() {
    require(block.timestamp < deadline, "Deadline has passed");
    _;
  }

  modifier afterDeadline() {
    require(block.timestamp >= deadline, "Deadline has not yet passed");
    _;
  }

  modifier notCompleted() {
    require(exampleExternalContract.completed() == false, "Example external contract has completed");
    _;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() payable public b4Deadline {
    balances[msg.sender] += msg.value;

    emit Stake(msg.sender, msg.value);
  }


  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  function execute() external afterDeadline notCompleted {
    if(address(this).balance > THRESHOLD){
      exampleExternalContract.complete{value: address(this).balance}();
    }else {
      openForWithdraw = true;
    }
  }

  // If the `threshold` was not met, allow everyone to call a `withdraw()` function
  function withdraw() external notCompleted {
    require(openForWithdraw == true, "Threshold has been met");
    require(balances[msg.sender] > 0);

    payable(msg.sender).transfer(balances[msg.sender]);
    balances[msg.sender] = 0;
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() external view returns(uint256) {
    if(block.timestamp >= deadline){
      return 0;
    }else{
      return deadline - block.timestamp;
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }

}
