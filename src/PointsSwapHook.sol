// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {ERC1155} from "solmate/src/tokens/ERC1155.sol";

import {Currency} from "v4-core/types/Currency.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId} from "v4-core/types/PoolId.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "v4-core/types/BalanceDelta.sol";
import {SwapParams, ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

import {Hooks} from "v4-core/libraries/Hooks.sol";
import {
    BeforeSwapDelta, BeforeSwapDeltaLibrary, toBeforeSwapDelta
} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";

import {Strings} from "./libraries/Strings.sol";
import {CalcLibrary} from "./libraries/Calc.sol";

contract PointsSwapHook is BaseHook, ERC1155 {
    BeforeSwapDelta public constant ZERO_DELTA = BeforeSwapDelta.wrap(0);
    string public baseUri = "https://api.example.com";
    address public owner;

    constructor(IPoolManager _manager, address _owner) BaseHook(_manager) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner");
        _;
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory id = Strings.toString(tokenId);
        return string.concat(baseUri, "/", id);
    }

    function changeBaseUri(string calldata newUri) external onlyOwner {
        baseUri = newUri;
    }

    function _afterSwap(
        address,
        PoolKey calldata key,
        SwapParams calldata swapParams,
        BalanceDelta delta,
        bytes calldata hookData
    ) internal override returns (bytes4, int128) {
        bytes4 selector = this.afterSwap.selector;
        // ensure user is buying Token with ETH
        if (!key.currency0.isAddressZero()) return (selector, 0);
        if (!swapParams.zeroForOne) return (selector, 0);

        uint256 ethSpent = uint256(int256(-delta.amount0()));

        _assignPoints(key.toId(), hookData, CalcLibrary.calcPointsForSwap(ethSpent));

        return (selector, 0);
    }

    function _assignPoints(PoolId poolId, bytes calldata hookData, uint256 points) internal {
        if (hookData.length == 0) return;

        address user = abi.decode(hookData, (address));

        if (user == address(0)) return;

        uint256 poolIdUint = uint256(PoolId.unwrap(poolId));
        _mint(user, poolIdUint, points, "");
    }

    function _beforeSwap(address, PoolKey calldata key, SwapParams calldata swapParams, bytes calldata hookData)
        internal
        pure
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        bytes4 selector = this.beforeSwap.selector;

        return (selector, ZERO_DELTA, 0);
    }
}
