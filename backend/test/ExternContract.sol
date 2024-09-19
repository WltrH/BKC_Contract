// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract ExternContract {
    // Fonction fallback qui rejette tous les transferts d'Ether
    fallback() external payable {
        revert("Transfert d'Ether rejete");
    }

    // Fonction receive qui rejette également tous les transferts d'Ether
    receive() external payable {
        revert("Transfert d'Ether rejete");
    }

    // Fonction pour appeler withdraw sur le contrat Pool
    function externWithdraw(address poolAddress) external {
        (bool success, ) = poolAddress.call(abi.encodeWithSignature("withdraw()"));
        require(!success, "Le retrait aurait du echouer");
    }
}
