// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {PointsSwapHook} from "../src/PointsSwapHook.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import {PoolSwapTest} from "v4-core/test/PoolSwapTest.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {ERC1155, ERC1155TokenReceiver} from "solmate/src/tokens/ERC1155.sol";

import {Currency} from "v4-core/types/Currency.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId} from "v4-core/types/PoolId.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "v4-core/types/BalanceDelta.sol";
import {SwapParams, ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

import {Hooks} from "v4-core/libraries/Hooks.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";

contract PointsSwapHookTest is Test, Deployers, ERC1155TokenReceiver {
    Currency ethCurrency = Currency.wrap(address(0));
    Currency tokenCurrency;

    function setUp() public {
        deployFreshManagerAndRouters();
    }

    function prepareToken() internal returns (MockERC20) {
        MockERC20 token = new MockERC20("Test Token", "TEST", 18);
        tokenCurrency = Currency.wrap(address(token));

        token.mint(address(this), 1000 ether);
        token.mint(address(1), 1000 ether);

        // Appove our TOKEN for spending on the swap router and modify liquidity router
        token.approve(address(swapRouter), type(uint256).max);
        token.approve(address(modifyLiquidityRouter), type(uint256).max);

        return token;
    }

    function initPoolWithLiquidity(PointsSwapHook hook, MockERC20 token) internal returns (PoolKey memory key) {
        (key,) = initPool(
            ethCurrency, // Currency 0 = ETH
            tokenCurrency, // Currency 1 = TOKEN
            hook,
            3000,
            SQRT_PRICE_1_1 // Initial Sqrt(P) value = 1
        );

        int24 lowerTick = -60;
        int24 upperTick = 60;
        uint160 sqrtPriceAtTickLower = TickMath.getSqrtPriceAtTick(lowerTick);
        uint160 sqrtPriceAtTickUpper = TickMath.getSqrtPriceAtTick(upperTick);

        uint256 ethToAdd = 5 ether;
        uint128 liquidityDelta = LiquidityAmounts.getLiquidityForAmount0(SQRT_PRICE_1_1, sqrtPriceAtTickUpper, ethToAdd);
        uint256 tokenToAdd =
            LiquidityAmounts.getLiquidityForAmount1(sqrtPriceAtTickLower, SQRT_PRICE_1_1, liquidityDelta);
        console.log("Eth to add: %s", ethToAdd);
        console.log("Token to add: %s", tokenToAdd);

        if (token.allowance(address(this), address(modifyLiquidityRouter)) < tokenToAdd) {
            revert("Insufficient approval of token for liquidity simulation");
        }

        modifyLiquidityRouter.modifyLiquidity{value: ethToAdd}(
            key,
            ModifyLiquidityParams({
                tickLower: lowerTick,
                tickUpper: upperTick,
                liquidityDelta: int256(uint256(liquidityDelta)),
                salt: bytes32(0)
            }),
            ZERO_BYTES
        );

        return key;
    }

    function deployHook() internal returns (PointsSwapHook hook) {
        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG) | uint160(Hooks.AFTER_SWAP_FLAG);
        address owner = address(this);
        deployCodeTo("PointsSwapHook.sol", abi.encode(manager, owner), address(flags));

        return PointsSwapHook(address(flags));
    }

    function swap(PoolKey memory key, PointsSwapHook hook) internal {
        PoolId poolId = key.toId();
        uint256 poolIdUint = uint256(PoolId.unwrap(poolId));

        uint256 pointsBalanceBefore = hook.balanceOf(address(this), poolIdUint);
        console.log("Poinnts balance before swap: %s", pointsBalanceBefore);

        bytes memory hookData = abi.encode(address(this));

        uint256 amount = 0.001 ether;
        swapRouter.swap{value: uint256(amount)}(
            key,
            SwapParams({
                zeroForOne: true,
                amountSpecified: -int256(amount),
                sqrtPriceLimitX96: TickMath.getSqrtPriceAtTick(TickMath.MIN_TICK) + 1
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            hookData
        );

        uint256 pointsBalanceAfter = hook.balanceOf(address(this), poolIdUint);

        console.log("Points balance After swap: %s", pointsBalanceAfter);
        assertEq(pointsBalanceAfter - pointsBalanceBefore, amount / 5);
    }

    function test_Demo() external {
        MockERC20 token = prepareToken();

        PointsSwapHook hook = deployHook();

        PoolKey memory key = initPoolWithLiquidity(hook, token);

        swap(key, hook);
    }

    function test_ChangeBaseUri() external {
        PointsSwapHook hook = deployHook();
        string memory newBaseUri = "https://newApiUri.com";
        hook.changeBaseUri(newBaseUri);
        assertEq(hook.baseUri(), newBaseUri);
    }

    function test_ChangeBaseUriRevertWhen_NotAnOwner() external {
        PointsSwapHook hook = deployHook();
        vm.startPrank(address(1));
        vm.expectRevert("Not an owner");
        hook.changeBaseUri("https://newApiUri.com");
        vm.stopPrank();
    }

    function test_Uri() external {
        PointsSwapHook hook = deployHook();
        string memory baseUri = hook.baseUri();
        string memory uri = hook.uri(333);
        assertEq(uri, string.concat(baseUri, "/333"));
    }
}
