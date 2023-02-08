// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import {IUniswapV3Pool} from "../uni-v3/interfaces/IUniswapV3Pool.sol";

/// @param pool The Uniswap V3 pool
/// @param tickLower The lower tick of the Bunni's UniV3 LP position
/// @param tickUpper The upper tick of the Bunni's UniV3 LP position
struct BunniKey {
    IUniswapV3Pool pool;
    int24 tickLower;
    int24 tickUpper;
}
