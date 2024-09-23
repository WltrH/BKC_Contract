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

    // Fonction de test pour vérifier si le contrat est déployé correctement
    function test_ContractIsDeployedSuccefully() public view {
        // Récupère l'adresse du propriétaire du contrat
        address _owner = pool.owner();
        // Vérifie que l'adresse du propriétaire correspond à celle attendue
        assertEq(owner, _owner);
        // Récupère la date de fin de la collecte
        uint256 _end = pool.end();
        // Vérifie que la date de fin correspond à la durée prévue
        assertEq(block.timestamp + DURATION, _end);
        // Récupère l'objectif de la collecte
        uint256 _goal = pool.goal();
        // Vérifie que l'objectif correspond à celui défini
        assertEq(GOAL, _goal);
    }

    // Fonction de test pour la contribution
    // Teste le cas où la contribution est faite après la fin de la collecte
    function test_RevertWhen_EndIsReached() public {
        // Avance le temps au-delà de la fin de la collecte
        vm.warp(pool.end() + 3600);

        // Prépare le sélecteur pour l'erreur attendue
        bytes4 selector = bytes4(keccak256("CollectIsFinished()"));
        // Configure l'attente d'un revert avec le sélecteur spécifié
        vm.expectRevert(abi.encodeWithSelector(selector));

        // Simule l'action de l'utilisateur 1
        vm.prank(user1);
        // Attribue 1 ether à l'utilisateur 1
        vm.deal(user1, 1 ether);
        // Tente de contribuer, ce qui devrait échouer
        pool.contribute{value: 1 ether}();
    }

    // Teste le cas où la contribution est faite sans fonds suffisants
    function test_RevertWhen_NotEnoughFunds() public {
        // Prépare le sélecteur pour l'erreur attendue
        bytes4 selector = bytes4(keccak256("NotEnoughFunds()"));
        // Configure l'attente d'un revert avec le sélecteur spécifié
        vm.expectRevert(abi.encodeWithSelector(selector));

        // Simule l'action de l'utilisateur 1
        vm.prank(user1);
        // Tente de contribuer sans fonds, ce qui devrait échouer
        pool.contribute();
    }

    // Teste une contribution réussie et vérifie l'émission de l'événement
    function test_ExpecEmit_SuccessfulContribute(uint96 _amount) public {
        // Suppose que le montant est supérieur à zéro
        vm.assume(_amount > 0);
        // Configure l'attente de l'émission d'un événement spécifique
        vm.expectEmit(true, false, false, true);
        // Définit l'événement attendu
        emit Pool.Contribut(address(user1), _amount);

        // Simule l'action de l'utilisateur 1
        vm.prank(user1);
        // Attribue le montant spécifié à l'utilisateur 1
        vm.deal(user1, _amount);
        // Effectue la contribution
        pool.contribute{value: _amount}();
    }
    // Teste si l'utilisateur est dans le mapping après une contribution
    function test_UserIsInMapping_AfterContribution() public {
        // Définir le montant de la contribution à 1 ether
        uint256 _amount = 1 ether;

        // Simuler l'adresse de l'utilisateur 1 comme expéditeur
        vm.prank(user1);
        // Attribuer le montant _amount à l'utilisateur 1
        vm.deal(user1, _amount);
        // Effectuer une contribution au pool avec le montant _amount
        pool.contribute{value: _amount}();

        // Récupérer la contribution de l'utilisateur 1 depuis le mapping
        uint256 userContribution = pool.contributions(user1);
        // Vérifier que la contribution enregistrée correspond au montant envoyé
        assertEq(
            userContribution,
            _amount,
            "La contribution de l'utilisateur n'est pas correctement enregistree dans le mapping"
        );
    }

    // Teste si le propriétaire du contrat est le propriétaire du pool
    function test_RevertWhen_IsNotTheOwner() public {

        // Récupérer le sélecteur pour l'erreur attendue
        // L'erreur attendue est OwnableUnauthorizedAccount d'openzeppelin
        bytes4 selector = bytes4(keccak256("OwnableUnauthorizedAccount(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, user1));

        // Tenter de retirer les fonds avec l'adresse user1
        vm.prank(user1);
        pool.withdraw();
   
    }

    // Teste de la fonction withdraw si le temps n'est pas atteint
    function test_RevertWhen_CollectIsNotFinished() public {
        // Avancer le temps juste avant la fin
        vm.warp(pool.end() - 1);

        // Contribuer au pool
        vm.prank(user1); 
        vm.deal(user1, 1 ether);
        pool.contribute{value: 1 ether}();

        // Récupérer le sélecteur pour l'erreur attendue
        bytes4 selector = bytes4(keccak256("CollectIsNotFinished()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        // Tenter de retirer les fonds
        vm.prank(owner);
        pool.withdraw();

    }

    // Teste de la fonction withdraw si l'objectif n'est pas atteint
    function test_RevertWhen_CollectIsNoReached(uint256 _amount) public {
        // Avancer le temps jusqu'à la fin de la collecte
        vm.warp(pool.end());

        // Assurer que le montant est inférieur à l'objectif
        vm.assume(_amount > 0 && _amount < pool.goal());

        // Récupérer le sélecteur pour l'erreur attendue
        bytes4 selector = bytes4(keccak256("CollectIsNotFinished()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        // Tenter de retirer les fonds
        vm.prank(owner);
        pool.withdraw();
    }

    // Teste si la collecte n'est pas terminée en fonction du temps
    function test_Collect_IsNotFinished_Time() public {
        // Avancer le temps juste avant la fin
        vm.warp(pool.end() - 1);

        // Contribuer au pool
        vm.prank(user1); 
        vm.deal(user1, 1 ether);
        pool.contribute{value: 1 ether}();

        // Récupérer le sélecteur pour l'erreur attendue
        bytes4 selector = bytes4(keccak256("CollectIsNotFinished()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        // Tenter de retirer les fonds  
        vm.prank(owner);
        pool.withdraw();
    }

    // Teste si la collecte n'est pas terminée en fonction des fonds
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


    
}
