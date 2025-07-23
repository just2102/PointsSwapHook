// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library CalcLibrary {
    uint8 public constant POINTS_DIVISOR = 5;

    // @param ethSpent The amount of ETH spent on the swap
    // @return The amount of points the user should be awarded
    function calcPointsForSwap(uint256 ethSpent) internal pure returns (uint256) {
        return ethSpent / POINTS_DIVISOR;
    }
}
