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

import "./GebProxyActions.sol";
import "./external/uni-v2/interfaces/IUniswapV2Router02.sol";
import "./external/uni-v2/interfaces/IUniswapV2Pair.sol";
import "./external/uni-v2/interfaces/IUniswapV2Factory.sol";

abstract contract GebIncentivesLike {
    function stakingToken() virtual public returns (address);
    function rewardsToken() virtual public returns (address);
    function stake(uint256) virtual public;
    function withdraw(uint256) virtual public;
    function exit() virtual public;
    function balanceOf(address) virtual public view returns (uint256);
    function getReward() virtual public;
}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a DSProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

/// @title Incentives proxy actions
/// @notice This contract is supposed to be used alongside a DSProxy contract.
/// @dev These functions are meant to be used as a a library for a DSProxy. Some are unsafe if you call them directly.
contract GebProxyIncentivesActions is BasicActions {
    // Internal functions

    /// @notice Provides liquidity on uniswap.
    /// @param coinJoin address
    /// @param uniswapRouter address - Uniswap Router V2
    /// @param tokenWad uint - amount of tokens to provide liquidity with
    /// @param ethWad uint - amount of ETH to provide liquidity with
    /// @param to address - receiver of the balance of generated LP Tokens
    /// @param minTokenAmounts uint - Minimum amounts of both ETH and the token (user selected acceptable slippage)
    /// @dev Uniswap will return unused tokens (it provides liquidity with the best current ratio)
    /// @dev Public funcitons should account for change sent from Uniswap
    function _provideLiquidityUniswap(address coinJoin, address uniswapRouter, uint tokenWad, uint ethWad, address to, uint[2] memory minTokenAmounts) internal {
        CoinJoinLike(coinJoin).systemCoin().approve(uniswapRouter, tokenWad);
        IUniswapV2Router02(uniswapRouter).addLiquidityETH{value: ethWad}(
            address(CoinJoinLike(coinJoin).systemCoin()),
            tokenWad,
            minTokenAmounts[0],
            minTokenAmounts[1],
            to,
            block.timestamp
        );
    }

    /// @notice Stakes in Incentives Pool (geb-incentives)
    /// @param incentives address - Liquidity mining pool
    function _stakeInMine(address incentives) internal {
        DSTokenLike lpToken = DSTokenLike(GebIncentivesLike(incentives).stakingToken());
        lpToken.approve(incentives, uint(0 - 1));
        GebIncentivesLike(incentives).stake(lpToken.balanceOf(address(this)));
    }

    /// @notice Removes liquidity from Uniswap
    /// @param uniswapRouter address - Uniswap Router V2
    /// @param systemCoin address - Address of COIN
    /// @param value uint - amount of LP Tokens to remove liquidity with
    /// @param to address - receiver of the balances of generated ETH / COIN
    /// @param minTokenAmounts uint - Minimum amounts of both ETH and the token (user selected acceptable slippage)
    function _removeLiquidityUniswap(address uniswapRouter, address systemCoin, uint value, address to, uint[2] memory minTokenAmounts) internal returns (uint amountA, uint amountB) {
        DSTokenLike(getWethPair(uniswapRouter, systemCoin)).approve(uniswapRouter, value);
        return IUniswapV2Router02(uniswapRouter).removeLiquidityETH(
            systemCoin,
            value,
            minTokenAmounts[0],
            minTokenAmounts[1],
            to,
            block.timestamp
        );
    }

    /// @notice Opens Safe, locks Eth, generates debt and sends COIN amount (deltaWad) and provides it as liquidity to Uniswap
    /// @param manager address
    /// @param taxCollector address
    /// @param ethJoin address
    /// @param coinJoin address
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param collateralType bytes32 - The ETH type used to generate debt
    /// @param deltaWad uint - Amount of debt to generate
    /// @param liquidityWad uint - Amount of ETH to be provided as liquidity (the remainder of msg.value will be used to collateralize the Safe)
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function openLockETHGenerateDebtProvideLiquidityUniswap(
        address manager,
        address taxCollector,
        address ethJoin,
        address coinJoin,
        address uniswapRouter,
        bytes32 collateralType,
        uint deltaWad,
        uint liquidityWad,
        uint[2] calldata minTokenAmounts
    ) external payable returns (uint safe) {
        safe = openSAFE(manager, collateralType, address(this));
        DSTokenLike systemCoin = DSTokenLike(CoinJoinLike(coinJoin).systemCoin());

        _lockETH(manager, ethJoin, safe, subtract(msg.value, liquidityWad));

        _generateDebt(manager, taxCollector, coinJoin, safe, deltaWad, address(this));

        _provideLiquidityUniswap(coinJoin, uniswapRouter, deltaWad, liquidityWad, msg.sender, minTokenAmounts);

        // sending back any leftover tokens/eth, necessary to manage change from providing liquidity
        msg.sender.call{value: address(this).balance}("");
        systemCoin.transfer(msg.sender, systemCoin.balanceOf(address(this)));
    }

    /// @notice Locks Eth, generates debt and sends COIN amount (deltaWad) and provides it as liquidity to Uniswap
    /// @param manager address
    /// @param taxCollector address
    /// @param ethJoin address
    /// @param coinJoin address
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param safe uint - Safe Id
    /// @param deltaWad uint - Amount of debt to generate
    /// @param liquidityWad uint - Amount of ETH to be provided as liquidity (the remainder of msg.value will be used to collateralize the Safe)
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function lockETHGenerateDebtProvideLiquidityUniswap(
        address manager,
        address taxCollector,
        address ethJoin,
        address coinJoin,
        address uniswapRouter,
        uint safe,
        uint deltaWad,
        uint liquidityWad,
        uint[2] calldata minTokenAmounts
    ) external payable {
        DSTokenLike systemCoin = DSTokenLike(CoinJoinLike(coinJoin).systemCoin());

        _lockETH(manager, ethJoin, safe, subtract(msg.value, liquidityWad));

        _generateDebt(manager, taxCollector, coinJoin, safe, deltaWad, address(this));

        _provideLiquidityUniswap(coinJoin, uniswapRouter, deltaWad, liquidityWad, msg.sender, minTokenAmounts);

        // sending back any leftover tokens/eth, necessary to manage change from providing liquidity
        msg.sender.call{value: address(this).balance}("");
        systemCoin.transfer(msg.sender, systemCoin.balanceOf(address(this)));
    }

    /// @notice Opens Safe, locks Eth, generates debt and sends COIN amount (deltaWad) and provides it as liquidity to Uniswap and stakes LP tokens in Farm
    /// @param manager address
    /// @param taxCollector address
    /// @param ethJoin address
    /// @param coinJoin address
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param incentives address - Liquidity mining pool
    /// @param collateralType bytes32 - The ETH type used to generate debt
    /// @param deltaWad uint256 - Amount of debt to generate
    /// @param liquidityWad uint256 - Amount of ETH to be provided as liquidity (the remainder of msg.value will be used to collateralize the Safe)
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function openLockETHGenerateDebtProvideLiquidityStake(
        address manager,
        address taxCollector,
        address ethJoin,
        address coinJoin,
        address uniswapRouter,
        address incentives,
        bytes32 collateralType,
        uint256 deltaWad,
        uint256 liquidityWad,
        uint256[2] calldata minTokenAmounts
    ) external payable returns (uint safe) {
        safe = openSAFE(manager, collateralType, address(this));
        DSTokenLike systemCoin = DSTokenLike(CoinJoinLike(coinJoin).systemCoin());

        _lockETH(manager, ethJoin, safe, subtract(msg.value, liquidityWad));

        _generateDebt(manager, taxCollector, coinJoin, safe, deltaWad, address(this));

        _provideLiquidityUniswap(coinJoin, uniswapRouter, deltaWad, liquidityWad, address(this), minTokenAmounts);

        _stakeInMine(incentives);

        // sending back any leftover tokens/eth, necessary to manage change from providing liquidity
        msg.sender.call{value: address(this).balance}("");
        systemCoin.transfer(msg.sender, systemCoin.balanceOf(address(this)));
    }

    /// @notice Locks Eth, generates debt and sends COIN amount (deltaWad) and provides it as liquidity to Uniswap and stakes LP tokens in Farm
    /// @param manager address
    /// @param taxCollector address
    /// @param ethJoin address
    /// @param coinJoin address
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param incentives address - Liquidity mining pool
    /// @param safe uint - Safe Id
    /// @param deltaWad uint - Amount of debt to generate
    /// @param liquidityWad uint - Amount of ETH to be provided as liquidity (the remainder of msg.value will be used to collateralize the Safe)
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function lockETHGenerateDebtProvideLiquidityStake(
        address manager,
        address taxCollector,
        address ethJoin,
        address coinJoin,
        address uniswapRouter,
        address incentives,
        uint safe,
        uint deltaWad,
        uint liquidityWad,
        uint[2] memory minTokenAmounts
    ) public payable {
        DSTokenLike systemCoin = DSTokenLike(CoinJoinLike(coinJoin).systemCoin());

        _lockETH(manager, ethJoin, safe, subtract(msg.value, liquidityWad));

        _generateDebt(manager, taxCollector, coinJoin, safe, deltaWad, address(this));

        _provideLiquidityUniswap(coinJoin, uniswapRouter, deltaWad, liquidityWad, address(this), minTokenAmounts);

        _stakeInMine(incentives);

        // sending back any leftover tokens/eth, necessary to manage change from providing liquidity
        msg.sender.call{value: address(this).balance}("");
        systemCoin.transfer(msg.sender, systemCoin.balanceOf(address(this)));
    }

    /// @notice Provides liquidity to Uniswap
    /// @param coinJoin address
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param wad uint - Amount of coin to provide (msg.value for ETH)
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function provideLiquidityUniswap(address coinJoin, address uniswapRouter, uint wad, uint[2] calldata minTokenAmounts) external payable {
        DSTokenLike systemCoin = DSTokenLike(CoinJoinLike(coinJoin).systemCoin());
        systemCoin.transferFrom(msg.sender, address(this), wad);
        _provideLiquidityUniswap(coinJoin, uniswapRouter, wad, msg.value, msg.sender, minTokenAmounts);

        // sending back any leftover tokens/eth, necessary to manage change from providing liquidity
        msg.sender.call{value: address(this).balance}("");
        systemCoin.transfer(msg.sender, systemCoin.balanceOf(address(this)));
    }

    /// @notice Generates debt and sends COIN amount (deltaWad) and provides it as liquidity to Uniswap and stakes LP tokens in Farm
    /// @param coinJoin address
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param incentives address - Liquidity mining pool
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function provideLiquidityStake(
        address coinJoin,
        address uniswapRouter,
        address incentives,
        uint wad,
        uint[2] memory minTokenAmounts
    ) public payable {
        DSTokenLike systemCoin = DSTokenLike(CoinJoinLike(coinJoin).systemCoin());
        systemCoin.transferFrom(msg.sender, address(this), wad);
        _provideLiquidityUniswap(coinJoin, uniswapRouter, wad, msg.value, address(this), minTokenAmounts);

        _stakeInMine(incentives);

        // sending back any leftover tokens/eth, necessary to manage change from providing liquidity
        msg.sender.call{value: address(this).balance}("");
        systemCoin.transfer(msg.sender, systemCoin.balanceOf(address(this)));
    }

    /// @notice Generates debt and sends COIN amount (deltaWad) and provides it as liquidity to Uniswap
    /// @param manager address
    /// @param taxCollector address
    /// @param coinJoin address
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param safe uint - Safe Id
    /// @param wad uint - Amount of debt to generate
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function generateDebtAndProvideLiquidityUniswap(
        address manager,
        address taxCollector,
        address coinJoin,
        address uniswapRouter,
        uint safe,
        uint wad,
        uint[2] calldata minTokenAmounts
    ) external payable {
        DSTokenLike systemCoin = DSTokenLike(CoinJoinLike(coinJoin).systemCoin());
        _generateDebt(manager, taxCollector, coinJoin, safe, wad, address(this));

        _provideLiquidityUniswap(coinJoin, uniswapRouter, wad, msg.value, msg.sender, minTokenAmounts);

        // sending back any leftover tokens/eth, necessary to manage change from providing liquidity
        msg.sender.call{value: address(this).balance}("");
        systemCoin.transfer(msg.sender, systemCoin.balanceOf(address(this)));
    }

    /// @notice Stakes in liquidity mining pool
    /// @param incentives address - pool address
    /// @param wad uint - amount
    function stakeInMine(address incentives, uint wad) external {
        DSTokenLike(GebIncentivesLike(incentives).stakingToken()).transferFrom(msg.sender, address(this), wad);
        _stakeInMine(incentives);
    }

    /// @notice Generates debt and sends COIN amount (deltaWad) and provides it as liquidity to Uniswap and stakes LP tokens in Farm
    /// @param manager address
    /// @param taxCollector address
    /// @param coinJoin address
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param incentives address - Liquidity mining pool
    /// @param safe uint - Safe Id
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function generateDebtAndProvideLiquidityStake(
        address manager,
        address taxCollector,
        address coinJoin,
        address uniswapRouter,
        address incentives,
        uint safe,
        uint wad,
        uint[2] calldata minTokenAmounts
    ) external payable {
        DSTokenLike systemCoin = DSTokenLike(CoinJoinLike(coinJoin).systemCoin());
        _generateDebt(manager, taxCollector, coinJoin, safe, wad, address(this));
        _provideLiquidityUniswap(coinJoin, uniswapRouter, wad, msg.value, address(this), minTokenAmounts);
        _stakeInMine(incentives);

        // sending back any leftover tokens/eth, necessary to manage change from providing liquidity
        msg.sender.call{value: address(this).balance}("");
        systemCoin.transfer(msg.sender, systemCoin.balanceOf(address(this)));
    }

    /// @notice Harvests rewards available (both instant and staked) 
    /// @param incentives address - Liquidity mining pool
    function getRewards(address incentives) public {
        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        DSTokenLike rewardToken = DSTokenLike(incentivesContract.rewardsToken());
        incentivesContract.getReward();
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }

    /// @notice Exits liquidity mining pool (withdraw LP tokens and getRewards for current campaign)
    /// @param incentives address - Liquidity mining pool
    function exitMine(address incentives) external {
        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        DSTokenLike rewardToken = DSTokenLike(incentivesContract.rewardsToken());
        DSTokenLike lpToken = DSTokenLike(incentivesContract.stakingToken());
        incentivesContract.exit();
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
        lpToken.transfer(msg.sender, lpToken.balanceOf(address(this)));
    }

    /// @notice Migrates from one campaign to another, claiming rewards
    /// @param _oldIncentives Old liquidity mining pool
    /// @param _newIncentives New liquidity mining pool
    function migrateCampaign(address _oldIncentives, address _newIncentives) external {
        GebIncentivesLike incentives = GebIncentivesLike(_oldIncentives);
        GebIncentivesLike newIncentives = GebIncentivesLike(_newIncentives);
        require(incentives.stakingToken() == newIncentives.stakingToken(), "geb-incentives/mismatched-staking-tokens");
        DSTokenLike rewardToken = DSTokenLike(incentives.rewardsToken());
        DSTokenLike lpToken = DSTokenLike(incentives.stakingToken());
        incentives.exit();

        _stakeInMine(_newIncentives);

        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }

    /// @notice Withdraw LP tokens from liquidity mining pool
    /// @param incentives address - Liquidity mining pool
    /// @param value uint - value to withdraw
    function withdrawFromMine(address incentives, uint value) external {
        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        DSTokenLike lpToken = DSTokenLike(incentivesContract.stakingToken());
        incentivesContract.withdraw(value);
        lpToken.transfer(msg.sender, lpToken.balanceOf(address(this)));
    }

    /// @notice Withdraw LP tokens from liquidity mining pool and harvests rewards
    /// @param incentives address - Liquidity mining pool
    /// @param value uint - value to withdraw
    function withdrawAndHarvest(address incentives, uint value) external {
        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        DSTokenLike rewardToken = DSTokenLike(incentivesContract.rewardsToken());
        DSTokenLike lpToken = DSTokenLike(incentivesContract.stakingToken());
        incentivesContract.withdraw(value);
        getRewards(incentives);
        lpToken.transfer(msg.sender, lpToken.balanceOf(address(this)));
    }

    /// @notice Withdraw LP tokens from liquidity mining pool and harvests rewards
    /// @param incentives address - Liquidity mining pool
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param systemCoin address
    /// @param value uint - value to withdraw
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function withdrawHarvestRemoveLiquidity(address incentives, address uniswapRouter, address systemCoin, uint value, uint[2] memory minTokenAmounts) public returns (uint amountA, uint amountB) {
        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        DSTokenLike rewardToken = DSTokenLike(incentivesContract.rewardsToken());
        DSTokenLike lpToken = DSTokenLike(incentivesContract.stakingToken());
        incentivesContract.withdraw(value);
        getRewards(incentives);
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
        return _removeLiquidityUniswap(uniswapRouter, systemCoin, lpToken.balanceOf(address(this)), msg.sender, minTokenAmounts);
    }

    /// @notice Removes liquidity from Uniswap
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param systemCoin address
    /// @param value uint - Amount of LP tokens to remove
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function removeLiquidityUniswap(address uniswapRouter, address systemCoin, uint value, uint[2] calldata minTokenAmounts) external returns (uint amountA, uint amountB) {
        DSTokenLike(getWethPair(uniswapRouter, systemCoin)).transferFrom(msg.sender, address(this), value);
        return _removeLiquidityUniswap(uniswapRouter, systemCoin, value, msg.sender, minTokenAmounts);
    }

    /// @notice Withdraws from liquidity mining pool and removes liquidity from Uniswap
    /// @param coinJoin address
    /// @param incentives address - Liquidity mining pool
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function withdrawAndRemoveLiquidity(address coinJoin, address incentives, uint value, address uniswapRouter, uint[2] calldata minTokenAmounts) external returns (uint amountA, uint amountB) {
        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        incentivesContract.withdraw(value);
        return _removeLiquidityUniswap(uniswapRouter, address(CoinJoinLike(coinJoin).systemCoin()), value, msg.sender, minTokenAmounts);
    }

    /// @notice Withdraws from liquidity mining pool, removes liquidity from Uniswap and repays debt
    /// @param manager address
    /// @param coinJoin address
    /// @param safe uint - Safe Id
    /// @param incentives address - Liquidity mining pool
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function withdrawRemoveLiquidityRepayDebt(address manager, address coinJoin, uint safe, address incentives, uint value, address uniswapRouter, uint[2] calldata minTokenAmounts) external {
        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        DSTokenLike rewardToken = DSTokenLike(incentivesContract.rewardsToken());
        DSTokenLike systemCoin = DSTokenLike(CoinJoinLike(coinJoin).systemCoin());
        incentivesContract.withdraw(value);

        _removeLiquidityUniswap(uniswapRouter, address(systemCoin), value, address(this), minTokenAmounts);
        _repayDebt(manager, coinJoin, safe, systemCoin.balanceOf(address(this)), false);
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
        msg.sender.call{value: address(this).balance}("");
    }

    /// @notice Exits from liquidity mining pool and removes liquidity from Uniswap
    /// @param coinJoin address
    /// @param incentives address - Liquidity mining pool
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function exitAndRemoveLiquidity(address coinJoin, address incentives, address uniswapRouter, uint[2] calldata minTokenAmounts) external returns (uint amountA, uint amountB) {
        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        DSTokenLike rewardToken = DSTokenLike(incentivesContract.rewardsToken());
        DSTokenLike lpToken = DSTokenLike(incentivesContract.stakingToken());
        incentivesContract.exit();
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
        return _removeLiquidityUniswap(uniswapRouter, address(CoinJoinLike(coinJoin).systemCoin()), lpToken.balanceOf(address(this)), msg.sender, minTokenAmounts);
    }

    /// @notice Exits from liquidity mining pool, removes liquidity from Uniswap and repays debt
    /// @param manager address
    /// @param coinJoin address
    /// @param safe uint - Safe Id
    /// @param incentives address - Liquidity mining pool
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function exitRemoveLiquidityRepayDebt(address manager, address coinJoin, uint safe, address incentives, address uniswapRouter, uint[2] calldata minTokenAmounts) external {

        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        DSTokenLike rewardToken = DSTokenLike(incentivesContract.rewardsToken());
        DSTokenLike lpToken = DSTokenLike(incentivesContract.stakingToken());
        DSTokenLike systemCoin = DSTokenLike(CoinJoinLike(coinJoin).systemCoin());
        incentivesContract.exit();
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));

        _removeLiquidityUniswap(uniswapRouter, address(systemCoin), lpToken.balanceOf(address(this)), address(this), minTokenAmounts);

        _repayDebt(manager, coinJoin, safe, systemCoin.balanceOf(address(this)), false);
        msg.sender.call{value: address(this).balance}("");
    }

    /// @notice Returns the address of a token-weth pair
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param token address of the token
    function getWethPair(address uniswapRouter, address token) public view returns (address) {
        IUniswapV2Router02 router = IUniswapV2Router02(uniswapRouter);
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        return factory.getPair(token, router.WETH());
    }
}
