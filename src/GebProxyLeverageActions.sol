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
import "./uni/interfaces/IUniswapV2Router02.sol";
import "./uni/interfaces/IUniswapV2Pair.sol";
import "./uni/interfaces/IUniswapV2Factory.sol";

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a DSProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

contract FlashSwapProxy is DSAuthority {
    address public proxy;
    address public uniswapPair;

    constructor(address _pair) public {
        proxy = msg.sender;
        uniswapPair = _pair;
    }

    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
        require(_sender == proxy, "invalid sender");
        require(msg.sender == uniswapPair, "invalid uniswap pair");

        // transfer coins
        (address _tokenBorrow,,,,,,,address _proxy) = abi.decode(_data, (address, uint, address, bool, bool, bytes, address, address));
        DSTokenLike(_tokenBorrow).transfer(proxy, (_amount0 > 0) ? _amount0 : _amount1);

        // call proxy
        (bool success,) = proxy.call(abi.encodeWithSignature("execute(address,bytes)", _proxy, msg.data));
        require(success, "");
    }

    function canCall(
        address src, address dst, bytes4 sig
    ) external override view returns (bool) {
        if( src == address(this) &&
            dst == proxy &&
            sig == 0x1cff79cd) // can only call uniswapCallback
            return true;
    }

    fallback() external payable {}
}

contract GebProxyLeverageActions is BasicActions {

    // Internal functions
        /// @notice Initiates a flashSwap
    /// @param _tokenBorrow address
    /// @param _amount uint
    /// @param _tokenPay address
    /// @param _data bytes
    /// @param uniswapPair address - Uniswap pair address
    /// @param weth address - Address of weth
    /// @param proxy address - Proxy contract that contains logic for receiving the Uniswap callback
    function _startSwap(address _tokenBorrow, uint256 _amount, address _tokenPay, bytes memory _data, address uniswapPair, address weth, address proxy) internal {
        require(_tokenBorrow == address(0) || _tokenPay == address(0), "only eth/token or token/eth swaps valid");
        bool isBorrowingEth;
        bool isPayingEth;
        address tokenBorrow = _tokenBorrow;
        address tokenPay = _tokenPay;

        if (tokenBorrow == address(0)) { // eth
            isBorrowingEth = true;
            tokenBorrow = weth; // we'll borrow WETH from UniswapV2 but then unwrap it for the user
        }
        if (tokenPay == address(0)) {
            isPayingEth = true;
            tokenPay = weth; // we'll wrap the user's ETH before sending it back to UniswapV2
        }

        uint amount0Out = tokenBorrow == IUniswapV2Pair(uniswapPair).token0() ? _amount : 0;
        uint amount1Out = tokenBorrow == IUniswapV2Pair(uniswapPair).token1() ? _amount : 0;

        bytes memory data = abi.encode(
            tokenBorrow,
            _amount,
            tokenPay,
            isBorrowingEth,
            isPayingEth,
            _data,
            weth,
            proxy
        );

        FlashSwapProxy flashSwapProxy = new FlashSwapProxy(uniswapPair);
        DSAuth(address(this)).setAuthority(DSAuthority(address(flashSwapProxy))); // temporarily setting as authority

        IUniswapV2Pair(uniswapPair).swap(amount0Out, amount1Out, address(flashSwapProxy), data);
    }

    // @notice Function is called by the Uniswap V2 pair's `swap` function
    /// @param _sender address - Initiator of the flashSwap
    /// @param _data bytes
    function uniswapV2Call(address _sender, uint /* _amount0 */, uint /* _amount1 */, bytes calldata _data) external {
        require(_sender == address(this), "only this contract may initiate");
        DSAuth(address(this)).setAuthority(DSAuthority(address(0)));

        // decode data
        (
            address _tokenBorrow,
            uint _amount,
            address _tokenPay,
            bool _isBorrowingEth,
            bool _isPayingEth,
            bytes memory _userData,
            address weth,
            // address proxy
        ) = abi.decode(_data, (address, uint, address, bool, bool, bytes, address, address));

        // unwrap WETH if necessary
        if (_isBorrowingEth) {
            WethLike(weth).withdraw(_amount);
        }

        // compute the amount of _tokenPay that needs to be repaid
        // address pairAddress = permissionedPairAddress; // gas efficiency
        uint pairBalanceTokenBorrow = DSTokenLike(_tokenBorrow).balanceOf(FlashSwapProxy(msg.sender).uniswapPair());
        uint pairBalanceTokenPay = DSTokenLike(_tokenPay).balanceOf(FlashSwapProxy(msg.sender).uniswapPair());
        uint amountToRepay = ((1000 * pairBalanceTokenPay * _amount) / (997 * pairBalanceTokenBorrow)) + 1;

        // do whatever the user wants
        if (_isBorrowingEth)
            flashLeverageCallback(_amount, amountToRepay, _userData);
        else
            flashDeleverageCallback(_amount, amountToRepay, _userData);

        // payback loan
        // wrap ETH if necessary
        if (_isPayingEth) {
            WethLike(weth).deposit{value: amountToRepay}();
        }
        DSTokenLike(_tokenPay).transfer(FlashSwapProxy(msg.sender).uniswapPair(), amountToRepay);
    }

    /// @notice Opens Safe, locks Eth, and leverages it to a user defined ratio
    /// @param uniswapV2Pair address
    /// @param manager address
    /// @param ethJoin address
    /// @param coinJoin address
    /// @param weth address
    /// @param callbackProxy Proxy contract that contains logic for receiving the Uniswap callback
    /// @param collateralType bytes32 - The ETH type used to generate debt
    /// @param leverage uint - leverage ratio, 3 decimal places, 2.5 == 2500
    function openLockETHLeverage(
        address uniswapV2Pair,
        address manager,
        address ethJoin,
        address coinJoin,
        address weth,
        address callbackProxy,
        bytes32 collateralType,
        uint256 leverage
    ) public payable returns (uint safe) {
        safe = openSAFE(manager, collateralType, address(this));
        _lockETH(manager, ethJoin, safe, msg.value);
        flashLeverage(
            uniswapV2Pair,
            manager,
            ethJoin,
            coinJoin,
            weth,
            callbackProxy,
            collateralType,
            safe,
            leverage
        );
    }

    /// @notice Locks Eth, and leverages it to a user defined ratio
    /// @param uniswapV2Pair address
    /// @param manager address
    /// @param ethJoin address
    /// @param coinJoin address
    /// @param weth address
    /// @param callbackProxy Proxy contract that contains logic for receiving the Uniswap callback
    /// @param collateralType bytes32 - The ETH type used to generate debt
    /// @param safe uint - Safe Id
    /// @param leverage uint - leverage ratio, 3 decimal places, 2.5 == 2500
    function lockETHLeverage(
        address uniswapV2Pair,
        address manager,
        address ethJoin,
        address coinJoin,
        address weth,
        address callbackProxy,
        bytes32 collateralType,
        uint safe,
        uint leverage // 3 decimal places, 2.5 == 2500
    ) public payable {
        _lockETH(manager, ethJoin, safe, msg.value);
        flashLeverage(
            uniswapV2Pair,
            manager,
            ethJoin,
            coinJoin,
            weth,
            callbackProxy,
            collateralType,
            safe,
            leverage
        );
    }

    /// @notice Leverages a safe to a user defined ratio
    /// @param uniswapV2Pair address
    /// @param manager address
    /// @param ethJoin address
    /// @param coinJoin address
    /// @param weth address
    /// @param callbackProxy Proxy contract that contains logic for receiving the Uniswap callback
    /// @param collateralType bytes32 - The ETH type used to generate debt
    /// @param safe uint256 - Safe Id
    /// @param leverage uint256 - leverage ratio, 3 decimal places, 2.5 == 2500
    function flashLeverage(
        address uniswapV2Pair,
        address manager,
        address ethJoin,
        address coinJoin,
        address weth,
        address callbackProxy,
        bytes32 collateralType,
        uint256 safe,
        uint256 leverage // 3 decimal places, 2.5 == 2500
    ) public {
        (uint collateralBalance,) = SAFEEngineLike(ManagerLike(manager).safeEngine()).safes(collateralType, ManagerLike(manager).safes(safe));

        // flashswap
        _startSwap(
          address(0),
          subtract((multiply(collateralBalance, leverage) / 1000), collateralBalance),
          address(CoinJoinLike(coinJoin).systemCoin()),
          abi.encode(
              manager,
              ethJoin,
              safe,
              coinJoin
          ),
          uniswapV2Pair,
          weth,
          callbackProxy
        );
    }

    /// @notice Flash leverage callback. This function is called by the FlashSwap proxy with the borrowed funds in hands
    /// @param collateralAmount uint - amont of collateral borrowed
    /// @param amountToRepay uint - amount to repay in COIN
    /// @param data bytes - data passed back from Uniswap
    function flashLeverageCallback(uint collateralAmount, uint amountToRepay, bytes memory data) internal {
        require(collateralAmount == address(this).balance, "funds not here");

        // decode data
        (
            address manager,
            address ethJoin,
            uint safe,
            address coinJoin
        ) = abi.decode(data, (address, address, uint, address));
        _lockETH(manager, ethJoin, safe, collateralAmount);
        _generateDebt(manager, coinJoin, safe, amountToRepay, address(this));
    }

    /// @notice Will repay all debt and free ETH (sends it to msg.sender)
    /// @param uniswapV2Pair address
    /// @param manager address
    /// @param ethJoin address
    /// @param coinJoin address
    /// @param weth address
    /// @param callbackProxy Proxy contract that contains logic for receiving the Uniswap callback
    /// @param collateralType bytes32 - The ETH type used to generate debt
    /// @param safe uint - Safe Id
    /// @param amountToFree uint - amount of ETH to free
    function flashDeleverageFreeETH(
        address uniswapV2Pair,
        address manager,
        address ethJoin,
        address coinJoin,
        address weth,
        address callbackProxy,
        bytes32 collateralType,
        uint safe,
        uint amountToFree
    ) public {
        flashDeleverage(
            uniswapV2Pair,
            manager,
            ethJoin,
            coinJoin,
            weth,
            callbackProxy,
            collateralType,
            safe
        );
        freeETH(manager, ethJoin, safe, amountToFree);
    }

    /// @notice Will repay all debt using a flashSwap
    /// @param uniswapV2Pair address
    /// @param manager address
    /// @param ethJoin address
    /// @param coinJoin address
    /// @param weth address
    /// @param callbackProxy Proxy contract that contains logic for receiving the Uniswap callback
    /// @param collateralType bytes32 - The ETH type used to generate debt
    /// @param safe uint - Safe Id
    function flashDeleverage(
        address uniswapV2Pair,
        address manager,
        address ethJoin,
        address coinJoin,
        address weth,
        address callbackProxy,
        bytes32 collateralType,
        uint safe
    ) public {
        (,uint generatedDebt) = SAFEEngineLike(ManagerLike(manager).safeEngine()).safes(collateralType, ManagerLike(manager).safes(safe));

        // encoding data
        bytes memory data = abi.encode(
            manager,
            ethJoin,
            safe,
            coinJoin
        );
        // flashswap
        _startSwap(address(CoinJoinLike(coinJoin).systemCoin()), generatedDebt, address(0), data, uniswapV2Pair, weth, callbackProxy);
    }

    /// @notice FlashDeleverage Callback, this function is called by the FlashSwap proxy with the borrowed funds in hands
    /// @param coinAmount uint - amont of COIN borrowed
    /// @param amountToRepay uint - amount to repay in ETH
    /// @param data bytes - data passed back from Uniswap
    function flashDeleverageCallback(uint coinAmount, uint amountToRepay, bytes memory data) internal {
        // decode data
        (
            address manager,
            address ethJoin,
            uint safe,
            address coinJoin
        ) = abi.decode(data, (address, address, uint, address));
        require(coinAmount == CoinJoinLike(coinJoin).systemCoin().balanceOf(address(this)), "funds not here");

        _repayDebtAndFreeETH(manager, ethJoin, coinJoin, safe, amountToRepay, coinAmount, false);
    }
}
