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

    // Constructeur du contrat, initialise la durée et l'objectif de la collecte
    constructor(uint256 _duration, uint256 _goal) Ownable(msg.sender) {
        // Définit la date de fin de la collecte
        end = block.timestamp + _duration;
        // Définit l'objectif de la collecte
        goal = _goal;
    }
    //@notice Permet de contribuer à la collecte
    function contribute() external payable {
        // Vérifie si la collecte n'est pas terminée
        if (block.timestamp >= end) {
            revert CollectIsFinished();
        }
        // Vérifie si le montant envoyé est supérieur à zéro
        if (msg.value == 0) {
            revert NotEnoughFunds();
        }
        // Ajoute la contribution de l'expéditeur
        contributions[msg.sender] += msg.value;
        // Met à jour le total collecté
        totalCollected += msg.value;

        // Émet un événement pour la contribution
        emit Contribut(msg.sender, msg.value);
    }
    //@notice Permet au propriétaire de retirer le montant de la collecte
    function withdraw() external onlyOwner {
        // Vérifie si la collecte est terminée et l'objectif atteint
        if (block.timestamp < end || totalCollected < goal) {
            revert CollectIsNotFinished();
        }
        // Tente d'envoyer le solde du contrat au propriétaire
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        // Vérifie si l'envoi a réussi
        if (!sent) {
            revert FailedToSendEther();
        }
    }

    //@notice Permet de rembourser le montant à l'expéditeur
    function refund() external {
        // Vérifie si la collecte est terminée
        if (block.timestamp < end) {
            revert CollectIsNotFinished();
        }
        // Vérifie si l'objectif n'a pas été atteint
        if (totalCollected >= goal) {
            revert GoalAlreadyReached();
        }
        // Vérifie si l'expéditeur a une contribution
        if (contributions[msg.sender] == 0) {
            revert NoContribution();
        }

        // Récupère le montant de la contribution
        uint256 amount = contributions[msg.sender];
        // Réinitialise la contribution de l'expéditeur
        contributions[msg.sender] = 0;
        // Soustrait le montant du total collecté
        totalCollected -= amount;
        // Tente d'envoyer le remboursement à l'expéditeur
        (bool sent, ) = msg.sender.call{value: amount}("");
        // Vérifie si l'envoi a réussi
        if (!sent) {
            revert FailedToSendEther();
        }
    }
}
