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

    constructor(uint256 _duration, uint256 _goal) Ownable(msg.sender) {
        end = block.timestamp + _duration;
        goal = _goal;
    }
    //@notice Allows to contribute to the pool
    function contribute() external payable {
        if (block.timestamp >= end) {
            revert CollectIsFinished();
        }
        if (msg.value == 0) {
            revert NotEnoughFunds();
        }
        contributions[msg.sender] += msg.value;
        totalCollected += msg.value;

        emit Contribut(msg.sender, msg.value);
    }
    //@notice Allow the owner to withdraw the amount of the pool
    function withdraw() external onlyOwner {
        if (block.timestamp < end || totalCollected < goal) {
            revert CollectIsNotFinished();
        }
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        if (!sent) {
            revert FailedToSendEther();
        }
    }

    //@notice Allow to refund the amount to the sender
    function refund() external {
        if (block.timestamp < end) {
            revert CollectIsNotFinished();
        }
        if (totalCollected >= goal) {
            revert GoalAlreadyReached();
        }
        if (contributions[msg.sender] == 0) {
            revert NoContribution();
        }

        uint256 amount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        totalCollected -= amount;
        (bool sent, ) = msg.sender.call{value: amount}("");
        if (!sent) {
            revert FailedToSendEther();
        }
    }
}
