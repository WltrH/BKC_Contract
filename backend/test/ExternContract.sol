// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract ExternContract {
    // Fonction fallback qui rejette tous les transferts d'Ether
    fallback() external payable {
        revert("Ce contrat refuse les transferts d'Ether");
    }

    // Fonction receive qui rejette également tous les transferts d'Ether
    receive() external payable {
        revert("Ce contrat refuse les transferts d'Ether");
    }

    // Fonction pour interagir avec le contrat Pool
    function interactWithPool(address poolAddress) external {
        // Cette fonction peut être utilisée pour appeler des fonctions sur le contrat Pool si nécessaire
        // Par exemple : Pool(poolAddress).withdraw();
    }
}
