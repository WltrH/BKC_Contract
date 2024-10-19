//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";

// @Title Pool
// @Author William

error CollectIsFinished();
error CollectIsNotFinished();
error GoalAlreadyReached();
error FailedToSendEther();
error NoContribution();
error NotEnoughFunds();

contract Pool is Ownable {
    uint256 public end;
    uint256 public goal;
    uint256 public totalCollected;
    mapping(address => uint256) public contributions;

    event Contribut(address indexed contributor, uint256 amount);

    // Constructor of the contract, initializes the duration and the goal of the collection
    constructor(uint256 _duration, uint256 _goal) Ownable(msg.sender) {
        // Sets the end date of the collection
        end = block.timestamp + _duration;
        // Sets the goal of the collection
        goal = _goal;
    }
    //@notice Allows to contribute to the collection
    function contribute() external payable {
        // Checks if the collection is not finished
        if (block.timestamp >= end) {
            revert CollectIsFinished();
        }
        // Checks if the sent amount is greater than zero
        if (msg.value == 0) {
            revert NotEnoughFunds();
        }
        // Adds the sender's contribution
        contributions[msg.sender] += msg.value;
        // Updates the total collected
        totalCollected += msg.value;

        // Emits an event for the contribution
        emit Contribut(msg.sender, msg.value);
    }
    //@notice Allows the owner to withdraw the amount of the collection
    function withdraw() external onlyOwner {
        // Checks if the collection is finished and the goal is reached
        if (block.timestamp < end || totalCollected < goal) {
            revert CollectIsNotFinished();
        }
        // Attempts to send the contract balance to the owner
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        // Checks if the send was successful
        if (!sent) {
            revert FailedToSendEther();
        }
    }

    //@notice Allows to refund the amount to the sender
    function refund() external {
        // Checks if the collection is finished
        if (block.timestamp < end) {
            revert CollectIsNotFinished();
        }
        // Checks if the goal has not been reached
        if (totalCollected >= goal) {
            revert GoalAlreadyReached();
        }
        // Checks if the sender has a contribution
        if (contributions[msg.sender] == 0) {
            revert NoContribution();
        }

        // Retrieves the amount of the contribution
        uint256 amount = contributions[msg.sender];
        // Resets the sender's contribution
        contributions[msg.sender] = 0;
        // Subtracts the amount from the total collected
        totalCollected -= amount;
        // Attempts to send the refund to the sender
        (bool sent, ) = msg.sender.call{value: amount}("");
        // Checks if the send was successful
        if (!sent) {
            revert FailedToSendEther();
        }
    }
}
