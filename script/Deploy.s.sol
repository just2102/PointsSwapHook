// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {PointsSwapHook} from "../src/PointsSwapHook.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Vm} from "forge-std/Vm.sol";

contract DeployScript is Script {
    PointsSwapHook public pointsHook;
    uint160 constant flags = uint160(Hooks.BEFORE_SWAP_FLAG) | uint160(Hooks.AFTER_SWAP_FLAG);
    address constant CREATE2_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Get pool manager address from environment variable with fallback
        address manager = vm.envOr("POOL_MANAGER", 0x1F98400000000000000000000000000000000004); // Default to Unichain
        console.log("Using Pool Manager: %s", manager);
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        Vm.Wallet memory wallet = vm.createWallet(deployerPrivateKey);
        address owner = wallet.addr;
        console.log("Owner: %s", owner);

        (address hookAddress, bytes32 salt) =
            HookMiner.find(CREATE2_DEPLOYER, flags, type(PointsSwapHook).creationCode, abi.encode(manager, owner));
        console.log("Hook address: %s", hookAddress);
        console.logBytes32(salt);

        pointsHook = new PointsSwapHook{salt: salt}(IPoolManager(manager), owner);

        console.log("Hook deployed to: %s", address(pointsHook));

        vm.stopBroadcast();
    }
}
