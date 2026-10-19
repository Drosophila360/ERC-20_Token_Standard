//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {OurToken} from "../src/OurToken.sol";
import {Script} from "forge-std/Script.sol";

contract DeployOurToken is Script {
    OurToken public ourToken;
    uint256 public constant INITIAL_SUPPLY = 1000000 ether;

    function run() public returns (OurToken) {
        vm.startBroadcast();
        ourToken = new OurToken(INITIAL_SUPPLY);
        vm.stopBroadcast();
        return ourToken;
    }
}
