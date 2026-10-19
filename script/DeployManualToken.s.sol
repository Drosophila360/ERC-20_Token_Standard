//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ManualToken} from "../src/ManualToken.sol";
import {Script} from "forge-std/Script.sol";

contract DeployManualToken is Script {
    ManualToken public manualToken;

    function run() public returns (ManualToken) {
        vm.startBroadcast();
        manualToken = new ManualToken();
        vm.stopBroadcast();
        return manualToken;
    }
}