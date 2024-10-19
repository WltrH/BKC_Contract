// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {Pool} from "../src/Pool.sol";



contract PoolTest is Test {
    address owner = makeAddr("User0");
    address user1 = makeAddr("User1");
    address user2 = makeAddr("User2");
    address user3 = makeAddr("User3");

    Pool public pool;
    uint256 constant DURATION = 4 weeks;
    uint256 constant GOAL = 10 ether;

    function setUp() public {
        vm.prank(owner);
        pool = new Pool(DURATION, GOAL);
    }

    // Test function to check if the contract is deployed correctly
    function test_ContractIsDeployedSuccefully() public view {
        // Retrieve the contract owner's address
        address _owner = pool.owner();
        // Check that the owner's address matches the expected one
        assertEq(owner, _owner);
        // Retrieve the end date of the collection
        uint256 _end = pool.end();
        // Check that the end date matches the expected duration
        assertEq(block.timestamp + DURATION, _end);
        // Retrieve the collection goal
        uint256 _goal = pool.goal();
        // Check that the goal matches the defined one
        assertEq(GOAL, _goal);
    }

    // Test function for contribution
    // Test the case where the contribution is made after the end of the collection
    function test_RevertWhen_EndIsReached() public {
        // Advance time beyond the end of the collection
        vm.warp(pool.end() + 3600);

        // Prepare the selector for the expected error
        bytes4 selector = bytes4(keccak256("CollectIsFinished()"));
        // Set up the expectation of a revert with the specified selector
        vm.expectRevert(abi.encodeWithSelector(selector));

        // Simulate the action of user1
        vm.prank(user1);
        // Assign 1 ether to user1
        vm.deal(user1, 1 ether);
        // Attempt to contribute, which should fail
        pool.contribute{value: 1 ether}();
    }

    // Test the case where the contribution is made without sufficient funds
    function test_RevertWhen_NotEnoughFunds() public {
        // Prepare the selector for the expected error
        bytes4 selector = bytes4(keccak256("NotEnoughFunds()"));
        // Set up the expectation of a revert with the specified selector
        vm.expectRevert(abi.encodeWithSelector(selector));

        // Simulate the action of user1
        vm.prank(user1);
        // Attempt to contribute without funds, which should fail
        pool.contribute();
    }

    // Test a successful contribution and verify the emission of the event
    function test_ExpecEmit_SuccessfulContribute(uint96 _amount) public {
        // Assume that the amount is greater than zero
        vm.assume(_amount > 0);
        // Set up the expectation of the emission of a specific event
        vm.expectEmit(true, false, false, true);
        // Define the expected event
        emit Pool.Contribut(address(user1), _amount);

        // Simulate the action of user1
        vm.prank(user1);
        // Assign the specified amount to user1
        vm.deal(user1, _amount);
        // Make the contribution
        pool.contribute{value: _amount}();
    }
    // Test if the user is in the mapping after a contribution
    function test_UserIsInMapping_AfterContribution() public {
        // Define the contribution amount to 1 ether
        uint256 _amount = 1 ether;

        // Simulate the address of user1 as the sender
        vm.prank(user1);
        // Assign the amount _amount to user1
        vm.deal(user1, _amount);
        // Make a contribution to the pool with the amount _amount
        pool.contribute{value: _amount}();

        // Retrieve the contribution of user1 from the mapping
        uint256 userContribution = pool.contributions(user1);
        // Check that the recorded contribution matches the sent amount
        assertEq(
            userContribution,
            _amount,
            "The user's contribution is not correctly recorded in the mapping"
        );
    }

    // Test if the contract owner is the owner of the pool
    function test_RevertWhen_IsNotTheOwner() public {

        // Retrieve the selector for the expected error
        // The expected error is OwnableUnauthorizedAccount from openzeppelin
        bytes4 selector = bytes4(keccak256("OwnableUnauthorizedAccount(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, user1));

        // Attempt to withdraw funds with the address user1
        vm.prank(user1);
        pool.withdraw();
   
    }

    // Test the withdraw function if the time is not reached
    function test_RevertWhen_CollectIsNotFinished() public {
        // Advance time just before the end
        vm.warp(pool.end() - 1);

        // Contribute to the pool
        vm.prank(user1); 
        vm.deal(user1, 1 ether);
        pool.contribute{value: 1 ether}();

        // Retrieve the selector for the expected error
        bytes4 selector = bytes4(keccak256("CollectIsNotFinished()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        // Attempt to withdraw funds
        vm.prank(owner);
        pool.withdraw();

    }

    // Test the withdraw function if the goal is not reached
    function test_RevertWhen_CollectIsNoReached(uint256 _amount) public {
        // Advance time to the end of the collection
        vm.warp(pool.end());

        // Ensure that the amount is less than the goal
        vm.assume(_amount > 0 && _amount < pool.goal());

        // Retrieve the selector for the expected error
        bytes4 selector = bytes4(keccak256("CollectIsNotFinished()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        // Attempt to withdraw funds
        vm.prank(owner);
        pool.withdraw();
    }

    // Test the failure of sending ether in the withdraw function
    function test_RevertWhen_FailedToSendEther() public {
        // Deploy a new pool
        pool = new Pool(DURATION, GOAL);

        // Contribute ether to the pool with user1
        vm.deal(user1, 5 ether);
        vm.prank(user1);
        pool.contribute{value: 5 ether}();

        // Contribute ether to the pool with user2
        vm.deal(user2, 6 ether);
        vm.prank(user2);
        pool.contribute{value: 6 ether}();

        // Advance time to the end of the collection
        vm.warp(pool.end()+1);

        // Retrieve the selector for the expected error
        bytes4 selector = bytes4(keccak256("FailedToSendEther()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        // Withdraw funds
        pool.withdraw();

    }

    // Test the withdrawal of funds from the withdraw function
    function test_Withdraw_Success() public {
        // Contribute enough Ether to reach the goal
        // Contribute ether to the pool with user1
        vm.deal(user1, 5 ether);
        vm.prank(user1);
        pool.contribute{value: 5 ether}();

        // Contribute ether to the pool with user2
        vm.deal(user2, 6 ether);
        vm.prank(user2);
        pool.contribute{value: 6 ether}();

        // Advance time to the end of the collection
        vm.warp(pool.end()+1);

        // Withdraw funds
        vm.prank(owner);
        pool.withdraw();

    }
        
    // Test if the collection is not finished based on time
    function test_Collect_IsNotFinished_Time() public {
        // Advance time just before the end
        vm.warp(pool.end() - 1);

        // Contribute to the pool
        vm.prank(user1); 
        vm.deal(user1, 1 ether);
        pool.contribute{value: 1 ether}();

        // Retrieve the selector for the expected error
        bytes4 selector = bytes4(keccak256("CollectIsNotFinished()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        // Attempt to withdraw funds  
        vm.prank(owner);
        pool.withdraw();
    }

    // Test if the collection is not finished based on funds
    function test_Collect_IsNotFinished_Funds(uint256 _amount) public {
        // Ensure that the amount is less than the goal
        vm.assume(_amount > 0 && _amount < pool.goal());

        // Contribute to the pool
        vm.prank(user1);
        vm.deal(user1, _amount);
        pool.contribute{value: _amount}();

        // Advance time to the end of the collection
        vm.warp(pool.end());

        // Attempt to withdraw funds
        bytes4 selector = bytes4(keccak256("CollectIsNotFinished()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        vm.prank(owner);
        pool.withdraw();
    }

    function test_Refund_CollectIsNotFiniched() public {
        // Advance time just before the end
        vm.warp(pool.end() - 1);

        // Contribute to the pool
        vm.prank(user1);
        vm.deal(user1, 1 ether);
        pool.contribute{value: 1 ether}();

        // Attempt to refund the funds
        bytes4 selector = bytes4(keccak256("CollectIsNotFinished()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        // Attempt to refund
        vm.prank(user1);
        pool.refund();
    }

    function test_Refund_GoalAlreadyReached(uint256 _amount) public {
        // Ensure that the amount is greater than the goal
        vm.assume(_amount > pool.goal());

        // Contribute to the pool with the amount _amount
        vm.deal(user1, _amount);
        vm.prank(user1);
        pool.contribute{value: _amount}();

        // Advance time to the end of the collection
        vm.warp(pool.end());

        // Attempt to refund when the goal is already reached
        bytes4 selector = bytes4(keccak256("GoalAlreadyReached()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        vm.prank(user1);
        pool.refund();
    }

    function test_Refund_NoContribution() public {
        // Advance time to the end of the collection
        vm.warp(pool.end());

        // Attempt to refund without having contributed
        bytes4 selector = bytes4(keccak256("NoContribution()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        vm.prank(user1);
        pool.refund();
    }


    
}
