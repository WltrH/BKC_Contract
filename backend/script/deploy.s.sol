// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {Pool} from "../src/Pool.sol";

contract MyScript is Script {

    function run() external {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Configurer le contrat Pool
        uint256 goal = 10 ether;
        uint256 end = 4 weeks;

        // Deployement du contrat Pool
        Pool pool = new Pool(goal, end);
        console.log("Pool deployed at address:", address(pool));
        vm.stopBroadcast(); 
    }
}