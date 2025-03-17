// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MahjongNFT} from "../src/NFT.sol";

contract CounterScript is Script {
    MahjongNFT public mahjong;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        mahjong = new MahjongNFT();

        vm.stopBroadcast();
    }
}
