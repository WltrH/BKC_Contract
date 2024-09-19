// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {Pool} from "../src/Pool.sol";
import {ExternContract} from "./ExternContract.sol";

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

    function test_ContractIsDeployedSuccefully() public {
        address _owner = pool.owner();
        assertEq(owner, _owner);
        uint256 _end = pool.end();
        assertEq(block.timestamp + DURATION, _end);
        uint256 _goal = pool.goal();
        assertEq(GOAL, _goal);
    }

    // Contribute
    function test_RevertWhen_EndIsReached() public {
        vm.warp(pool.end() + 3600);

        bytes4 selector = bytes4(keccak256("CollectIsFinished()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        vm.prank(user1);
        vm.deal(user1, 1 ether);
        pool.contribute{value: 1 ether}();
    }

    function test_RevertWhen_NotEnoughFunds() public {
        bytes4 selector = bytes4(keccak256("NotEnoughFunds()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        vm.prank(user1);
        pool.contribute();
    }

    function test_ExpecEmit_SuccessfulContribute(uint96 _amount) public {
        vm.assume(_amount > 0);
        vm.expectEmit(true, false, false, true);
        emit Pool.Contribut(address(user1), _amount);

        vm.prank(user1);
        vm.deal(user1, _amount);
        pool.contribute{value: _amount}();
    }

    function test_UserIsInMapping_AfterContribution() public {
        uint256 _amount = 1 ether;

        vm.prank(user1);
        vm.deal(user1, _amount);
        pool.contribute{value: _amount}();

        uint256 userContribution = pool.contributions(user1);
        assertEq(
            userContribution,
            _amount,
            "La contribution de l'utilisateur n'est pas correctement enregistree dans le mapping"
        );
    }

    function test_Collect_IsNotFinished_Time() public {
        // Avancer le temps juste avant la fin
        vm.warp(pool.end() - 1);

        // Contribuer au pool
        vm.prank(user1);
        vm.deal(user1, 1 ether);
        pool.contribute{value: 1 ether}();

        // Tenter de retirer les fonds
        bytes4 selector = bytes4(keccak256("CollectIsNotFinished()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        vm.prank(owner);
        pool.withdraw();
    }

    function test_Collect_IsNotFinished_Funds(uint256 _amount) public {
        // Assurer que le montant est inférieur à l'objectif
        vm.assume(_amount > 0 && _amount < pool.goal());

        // Contribuer au pool
        vm.prank(user1);
        vm.deal(user1, _amount);
        pool.contribute{value: _amount}();

        // Avancer le temps jusqu'à la fin de la collecte
        vm.warp(pool.end());

        // Tenter de retirer les fonds
        bytes4 selector = bytes4(keccak256("CollectIsNotFinished()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        vm.prank(owner);
        pool.withdraw();
    }

    function test_Failed_ToSendEther() public {
        // Contribuer au pool avec le montant exact de l'objectif
        vm.deal(user1, pool.goal());
        vm.prank(user1);
        pool.contribute{value: pool.goal()}();

        // Avancer le temps jusqu'à la fin de la collecte
        vm.warp(pool.end());

        // Créer un contrat malveillant qui rejette les transferts d'Ether
        address externContract = address(new ExternContract());

        // Transférer la propriété du pool au contrat malveillant
        vm.prank(owner);
        pool.transferOwnership(externContract);

        // Tenter de retirer les fonds
        bytes4 selector = bytes4(keccak256("FailedToSendEther()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        vm.prank(externContract);
        pool.withdraw();
    }

    function test_Refund_CollectIsNotFiniched() public {
        // Avancer le temps juste avant la fin
        vm.warp(pool.end() - 1);

        // Contribuer au pool
        vm.prank(user1);
        vm.deal(user1, 1 ether);
        pool.contribute{value: 1 ether}();

        // Tenter de se faire refund les fonds
        bytes4 selector = bytes4(keccak256("CollectIsNotFinished()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        // Tenter de se faire refund
        vm.prank(user1);
        pool.refund();
    }

    function test_Refund_GoalAlreadyReached(uint256 _amount) public {
        // Assurer que le montant est supérieur à l'objectif
        vm.assume(_amount > pool.goal());

        // Contribuer au pool avec le montant _amount
        vm.deal(user1, _amount);
        vm.prank(user1);
        pool.contribute{value: _amount}();

        // Avancer le temps jusqu'à la fin de la collecte
        vm.warp(pool.end());

        // Tenter le refund alors que l'objectif est déjà atteint
        bytes4 selector = bytes4(keccak256("GoalAlreadyReached()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        vm.prank(user1);
        pool.refund();
    }

    function test_Refund_NoContribution() public {
        // Avancer le temps jusqu'à la fin de la collecte
        vm.warp(pool.end());

        // Tenter de se faire rembourser sans avoir contribué
        bytes4 selector = bytes4(keccak256("NoContribution()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        vm.prank(user1);
        pool.refund();
    }

    function test_Refund_FailedToSendEther() public {
        // Contribuer au pool
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        pool.contribute{value: 1 ether}();

        // Avancer le temps jusqu'à la fin de la collecte
        vm.warp(pool.end());

        // Créer un contrat externe qui rejette les transferts d'Ether
        ExternContract externContract = new ExternContract();

        // Transférer la propriété du contrat Pool à ExternContract
        vm.prank(owner);
        pool.transferOwnership(address(externContract));

        // Configurer l'attente d'un revert avec le message spécifique
        bytes4 selector = bytes4(keccak256("FailedToSendEther()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        // Tenter le remboursement, qui devrait échouer car ExternContract rejette les transferts d'Ether
        vm.prank(user1);
        pool.refund();
    }
    
}
