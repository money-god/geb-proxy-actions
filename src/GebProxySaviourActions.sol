/// GebProxySaviourActions.sol

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

abstract contract GebSaviourLike {
    function deposit(uint256, uint256) virtual external;
    function deposit(bytes32, uint256, uint256) virtual external;
    function withdraw(uint256, uint256, address) virtual external;
    function withdraw(bytes32, uint256, uint256, address) virtual external;
    function getReserves(uint256, address) virtual external;
}

/// @title Saviour proxy actions
/// @notice This contract is supposed to be used alongside a DSProxy contract.
/// @dev These functions are meant to be used as a a library for a DSProxy
contract GebProxySaviourActions {
    // --- Internal Logic ---
    /*
    * @notice Transfer a token from the caller to the proxy and approve another address to pull the tokens from the proxy
    * @param token The token being transferred and approved
    * @param target The address that can pull tokens from the proxy
    * @param amount The amount of tokens being transferred and approved
    */
    function transferTokenFromAndApprove(address token, address target, uint256 amount) internal {
        DSTokenLike(token).transferFrom(msg.sender, address(this), amount);
        DSTokenLike(token).approve(target, 0);
        DSTokenLike(token).approve(target, amount);
    }

    // --- External Logic
    /*
    * @notice Transfer all tokens that the proxy has out of an array of tokens to the caller
    * @param tokens The array of tokens being transfered
    */
    function transferTokensToCaller(address[] memory tokens) public {
        for (uint i = 0; i < tokens.length; i++) {
            uint256 selfBalance = DSTokenLike(tokens[i]).balanceOf(address(this));
            if (selfBalance > 0) {
              DSTokenLike(tokens[i]).transfer(msg.sender, selfBalance);
            }
        }
    }
    /*
    * @notice Attach a saviour to a SAFE
    * @param saviour The saviour contract being attached
    * @param manager The SAFE manager contract
    * @param safe The ID of the SAFE being covered
    * @param liquidationEngine The LiquidationEngine contract
    */
    function protectSAFE(
        address saviour,
        address manager,
        uint safe,
        address liquidationEngine
    ) public {
        ManagerLike(manager).protectSAFE(safe, liquidationEngine, saviour);
    }
    /*
    * @notice Deposit cover in a saviour contract
    * @param collateralSpecific Whether the collateral type of the SAFE needs to be passed to the saviour contract
    * @param saviour The saviour contract being attached
    * @param manager The SAFE manager contract
    * @param token The token being used as cover
    * @param safe The ID of the SAFE being covered
    * @param tokenAmount The amount of tokens being deposited as cover
    */
    function deposit(
        bool collateralSpecific,
        address saviour,
        address manager,
        address token,
        uint256 safe,
        uint256 tokenAmount
    ) public {
        transferTokenFromAndApprove(token, saviour, tokenAmount);

        if (collateralSpecific) {
          GebSaviourLike(saviour).deposit(ManagerLike(manager).collateralTypes(safe), safe, tokenAmount);
        } else {
          GebSaviourLike(saviour).deposit(safe, tokenAmount);
        }
    }
    /*
    * @notice Withdraw cover from a saviour contract
    * @param collateralSpecific Whether the collateral type of the SAFE needs to be passed to the saviour contract
    * @param saviour The saviour contract from which to withdraw cover
    * @param manager The SAFE manager contract
    * @param safe The ID of the SAFE being covered
    * @param tokenAmount The amount of tokens being withdrawn
    * @param dst The address that will receive the withdrawn tokens
    */
    function withdraw(
        bool collateralSpecific,
        address saviour,
        address manager,
        uint256 safe,
        uint256 tokenAmount,
        address dst
    ) public {
        if (collateralSpecific) {
          GebSaviourLike(saviour).withdraw(ManagerLike(manager).collateralTypes(safe), safe, tokenAmount, dst);
        } else {
          GebSaviourLike(saviour).withdraw(safe, tokenAmount, dst);
        }
    }
    /*
    * @notice Attach a saviour to a SAFE and deposit cover in it
    * @param collateralSpecific Whether the collateral type of the SAFE needs to be passed to the saviour contract
    * @param saviour The saviour contract being attached
    * @param manager The SAFE manager contract
    * @param token The token being used as cover
    * @param liquidationEngine The LiquidationEngine contract
    * @param safe The ID of the SAFE being covered
    * @param tokenAmount The amount of tokens being deposited as cover
    */
    function protectSAFEDeposit(
        bool collateralSpecific,
        address saviour,
        address manager,
        address token,
        address liquidationEngine,
        uint256 safe,
        uint256 tokenAmount
    ) public {
        protectSAFE(saviour, manager, safe, liquidationEngine);
        deposit(collateralSpecific, saviour, manager, token, safe, tokenAmount);
    }
    /*
    * @notice Withdraw cover from a saviour and uncover a SAFE
    * @param collateralSpecific Whether the collateral type of the SAFE needs to be passed to the saviour contract
    * @param saviour The saviour contract being detached
    * @param manager The SAFE manager contract
    * @param token The token being used as cover
    * @param liquidationEngine The LiquidationEngine contract
    * @param safe The ID of the SAFE being covered
    * @param tokenAmount The amount of tokens being withdrawn
    * @param dst The address that will receive the withdrawn tokens
    */
    function withdrawProtectSAFE(
        bool collateralSpecific,
        address saviour,
        address manager,
        address token,
        address liquidationEngine,
        uint256 safe,
        uint256 tokenAmount,
        address dst
    ) public {
        withdraw(collateralSpecific, saviour, manager, safe, tokenAmount, dst);
        protectSAFE(address(0), manager, safe, liquidationEngine);
    }
    /*
    * @notice Withdraw cover from a saviour, cover a SAFE with a new saviour and deposit cover in the new saviour
    * @param withdrawCollateralSpecific Whether the collateral type of the SAFE needs to be passed to the withdraw saviour contract
    * @param depositCollateralSpecific Whether the collateral type of the SAFE needs to be passed to the deposit saviour contract
    * @param withdrawSaviour The saviour from which cover is being withdrawn
    * @param depositSaviour The new saviour that wil protect the SAFE
    * @param manager The SAFE manager contract
    * @param depositToken The token being deposited in the depositSaviour
    * @param liquidationEngine The LiquidationEngine contract
    * @param safe The SAFE being covered by the new saviour
    * @param withdrawTokenAmount The amount of tokens being withdrawn from the old saviour
    * @param depositTokenAmount The amount of tokens being deposited in the new saviour
    * @param withdrawDst The address that will receive the withdrawn tokens
    */
    function withdrawProtectSAFEDeposit(
        bool withdrawCollateralSpecific,
        bool depositCollateralSpecific,
        address withdrawSaviour,
        address depositSaviour,
        address manager,
        address depositToken,
        address liquidationEngine,
        uint safe,
        uint256 withdrawTokenAmount,
        uint256 depositTokenAmount,
        address withdrawDst
    ) public {
        withdraw(withdrawCollateralSpecific, withdrawSaviour, manager, safe, withdrawTokenAmount, withdrawDst);
        protectSAFE(depositSaviour, manager, safe, liquidationEngine);
        deposit(depositCollateralSpecific, depositSaviour, manager, depositToken, safe, depositTokenAmount);
    }
    /*
    * @notice Withdraw reserve tokens from a saviour
    * @param saviour The saviour from which to withdraw reserve assets
    * @param safe The ID of the SAFE that has tokens in reserves
    * @param The address that will receive the reserve tokens
    */
    function getReserves(address saviour, uint256 safe, address dst) public {
        GebSaviourLike(saviour).getReserves(safe, dst);
    }
}
