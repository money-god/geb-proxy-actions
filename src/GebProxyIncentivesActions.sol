/// GebProxyActions.sol

// Copyright (C) 2018-2020 Maker Ecosystem Growth Holdings, INC.

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.7;
pragma experimental ABIEncoderV2;

import "./GebProxyActions.sol";
import "./external/bunni/IBunniHub.sol";
import "./external/uni-v3/interfaces/IUniswapV3Pool.sol";

abstract contract TokenPoolLike {
    function token() public virtual view returns (DSTokenLike);
}

abstract contract GebIncentivesLike {
    function ancestorPool() virtual view public returns (TokenPoolLike);
    function rewardPool() virtual view public returns (TokenPoolLike);
    function join(uint256) virtual public;
    function exit(uint256) virtual public;
    function pendingRewards(address) virtual public view returns (uint256);
    function descendantBalanceOf(address) virtual public view returns (uint256);
    function getRewards() virtual public;
    function getRewards(address, address) virtual public;
}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a DSProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

/// @title Incentives proxy actions
/// @notice This contract is supposed to be used alongside a DSProxy contract.
/// @dev These functions are meant to be used as a a library for a DSProxy. Some are unsafe if you call them directly.
contract GebProxyIncentivesActions {
    // Internal functions

    /// @notice Provides liquidity on bunni.
    /// @param bunniHub Address of the bunni hub
    /// @param params The input parameters
    /// key The Bunni position's key
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return shares The new share tokens minted to the sender
    /// @return addedLiquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function _provideLiquidityBunni(address bunniHub, IBunniHub.DepositParams memory params) internal returns (uint, uint128, uint, uint) {
        DSTokenLike(params.key.pool.token0()).approve(address(params.key.pool), params.amount0Desired);
        DSTokenLike(IUniswapV3Pool(params.key.pool).token1()).approve(address(params.key.pool), params.amount1Desired);

        return IBunniHub(bunniHub).deposit(params);
    }

    /// @notice Stakes in Incentives Pool (geb-incentives)
    /// @param incentives address - Liquidity mining pool
    function _stakeInMine(address incentives) internal {
        DSTokenLike lpToken = GebIncentivesLike(incentives).ancestorPool().token();
        lpToken.approve(incentives, uint(-1));
        GebIncentivesLike(incentives).join(lpToken.balanceOf(address(this)));
    }

    /// @notice Removes liquidity from Bunni
    /// @param bunniHub Address of the bunni hub
    /// @param params The input parameters
    /// key The Bunni position's key
    /// recipient The user if not withdrawing ETH, address(0) if withdrawing ETH
    /// shares The amount of share tokens to burn,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return removedLiquidity The amount of liquidity decrease
    /// @return amount0 The amount of token0 withdrawn to the recipient
    /// @return amount1 The amount of token1 withdrawn to the recipient
    function _removeLiquidityBunni(address bunniHub, IBunniHub.WithdrawParams memory params) internal returns (uint128, uint, uint) {
        IBunniToken shareToken = IBunniHub(bunniHub).getBunniToken(params.key);
        shareToken.approve(bunniHub, params.shares);
        return IBunniHub(bunniHub).withdraw(params);
    }

    /// @notice Provides liquidity on bunni.
    /// @param bunniHub Address of the bunni hub
    /// @param params The input parameters
    /// key The Bunni position's key
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return shares The new share tokens minted to the sender
    /// @return addedLiquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function provideLiquidityBunni(address bunniHub, IBunniHub.DepositParams calldata params) external returns (uint, uint128, uint, uint) {
        return _provideLiquidityBunni(bunniHub, params);        
    }

    /// @notice Stakes in liquidity mining pool
    /// @param incentives address - pool address
    /// @param wad uint - amount
    function stakeInMine(address incentives, uint wad) external {
        DSTokenLike lpToken = GebIncentivesLike(incentives).ancestorPool().token();
        lpToken.transferFrom(msg.sender, address(this), wad);
        _stakeInMine(incentives);
    }

    function provideLiquidityBunniAndStake(address bunniHub, IBunniHub.DepositParams calldata params, address incentives) external {
        _provideLiquidityBunni(bunniHub, params);  
        _stakeInMine(incentives);        
    }

    /// @notice Harvests rewards available 
    /// @param incentives address - Liquidity mining pool
    function getRewards(address incentives) public {
        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        DSTokenLike rewardToken = GebIncentivesLike(incentives).rewardPool().token();
        incentivesContract.getRewards();
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }

    /// @notice Harvests rewards available 
    /// @param incentives address - Liquidity mining pool
    function getRewards(address[] memory incentives) public {
        for (uint i; i < incentives.length; i++) getRewards(incentives[i]);
    }    

    /// @notice Harvests rewards available 
    /// @param safe Safe Id
    /// @param safeManager Safe manager address
    /// @param incentives Liquidity mining pooll
    function getDebtRewards(uint256 safe, address safeManager, address incentives) public {
        ManagerLike(safeManager).collectRewards(safe, incentives);
        DSTokenLike rewardToken = GebIncentivesLike(incentives).rewardPool().token();
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }    

    /// @notice Harvests rewards available 
    /// @param safes Safe Ids
    /// @param safeManager Safe manager address
    /// @param incentives Liquidity mining pool
    function getDebtRewards(uint256[] memory safes, address safeManager, address incentives) public {
        for (uint i; i < safes.length; i++)
            ManagerLike(safeManager).collectRewards(safes[i], incentives);
        DSTokenLike rewardToken = GebIncentivesLike(incentives).rewardPool().token();
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }  

    /// @notice Harvests rewards available on both types of rewards contracts (debt, others)
    /// @param safes Safe Ids
    /// @param safeManager Safe manager address
    /// @param debtIncentives Liquidity mining pool (debt)
    /// @param incentives Liquidity mining pool (others)
    function getMultipleRewards(uint256[] calldata safes, address safeManager, address debtIncentives, address[] calldata incentives) external {
        getDebtRewards(safes, safeManager, debtIncentives);
        getRewards(incentives);
    }      


    /// @notice Withdraw LP tokens from liquidity mining pool
    /// @param incentives address - Liquidity mining pool
    /// @param value uint - value to withdraw
    function withdrawFromMine(address incentives, uint value) external {
        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        DSTokenLike lpToken = GebIncentivesLike(incentives).ancestorPool().token();
        incentivesContract.exit(value);
        lpToken.transfer(msg.sender, lpToken.balanceOf(address(this)));
    }

    /// @notice Removes liquidity from Bunni
    /// @param bunniHub Address of the bunni hub
    /// @param params The input parameters
    /// key The Bunni position's key
    /// recipient The user if not withdrawing ETH, address(0) if withdrawing ETH
    /// shares The amount of share tokens to burn,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return removedLiquidity The amount of liquidity decrease
    /// @return amount0 The amount of token0 withdrawn to the recipient
    /// @return amount1 The amount of token1 withdrawn to the recipient
    function removeLiquidityBunni(address bunniHub, IBunniHub.WithdrawParams calldata params) external returns (uint128, uint, uint) {
        IBunniToken shareToken = IBunniHub(bunniHub).getBunniToken(params.key);
        shareToken.transferFrom(msg.sender, address(this), params.shares);        
        return _removeLiquidityBunni(bunniHub, params);
    }

    /// @notice Withdraws from liquidity mining pool and removes liquidity from Bunni
    /// @param bunniHub Address of the bunni hub
    /// @param params The input parameters
    /// key The Bunni position's key
    /// recipient The user if not withdrawing ETH, address(0) if withdrawing ETH
    /// shares The amount of share tokens to burn,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return removedLiquidity The amount of liquidity decrease
    /// @return amount0 The amount of token0 withdrawn to the recipient
    /// @return amount1 The amount of token1 withdrawn to the recipient
    function withdrawAndRemoveLiquidity(address incentives, uint value, address bunniHub, IBunniHub.WithdrawParams calldata params) external returns (uint128, uint, uint) {
        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        incentivesContract.exit(value);
        return _removeLiquidityBunni(bunniHub, params);
    }
}