// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract GasConsumer {
    // Fonction fallback qui consomme tout le gaz disponible
    fallback() external payable {
        while(true) {}
    }

    // Fonction receive pour accepter les transferts d'Ether
    receive() external payable {}
}
