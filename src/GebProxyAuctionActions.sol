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

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a DSProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

contract GebProxyDebtAuctionActions {

    /// @notice Starts auction. Bids if auction started and soldAmount is lower than current bid
    /// @param accountingEngine AccountingEngine
    /// @param soldAmount Sold amount
    function startAndDecraseSoldAmount(address accountingEngine, uint soldAmount) public {
        // this will first call AccountingEngine.auctionDebt() and then call decreaseSoldAmount to bid in the auction
    }

    /// @notice Bids on debt auctions
    /// @param accountingEngine AccountingEngine
    /// @param auctionId Auction Id
    /// @param soldAmount Sold amount
    function decreaseSoldAmount(address accountingEngine, uint auctionId, uint soldAmount) public {
        // simply bids in a debt auction; you must handle 2 cases: the auction is ongoing and you simply bid (offer RAI); the auction expired because no one bid in it so you first need to call restartAuction and then bid in it
    }

    /// @notice Mints FLX for your proxy and then the proxy sends all of its FLX balance to you
    /// @param accountingEngine AccountingEngine
    /// @param auctionId Auction Id
    function settleAuction(address accountingEngine, uint auctionId) public {
        // mints FLX for your proxy and then the proxy sends all of its FLX balance to you
    }

    /// @notice Claims the full FLX and RAI balances of your proxy and sends them to you
    function claimProxyFunds() public {
        // claims the full FLX and RAI balances of your proxy and sends them to you
    }

}

contract GebProxySurplusAuctionActions {

    /// @notice Starts auction and increases bid size. Bids if auction started and bidSize is larger than current bid
    /// @param accountingEngine AccountingEngine
    /// @param bidSize Bid size
    function startAndIncreaseBidSize(address accountingEngine, uint bidSize) public {
        // this will first call AccountingEngine.auctionSurplus() and then call increaseBidSize to bid in the auction
    }

    /// @notice Starts auction and increases bid size. Bids if auction started and bidSize is larger than current bid
    /// @param accountingEngine AccountingEngine
    /// @param auctionId Auction Id
    /// @param bidSize Bid size
    function increaseBidSize(address accountingEngine, uint auctionId, uint bidSize) public {
        // simply bids in a debt auction; you must handle 2 cases: the auction is ongoing and you simply bid (offer FLX); the auction expired because no one bid in it so you first need to call restartAuction and then bid in it
    }

    /// @notice Starts auction and increases bid size. Bids if auction started and bidSize is larger than current bid
    /// @param accountingEngine AccountingEngine
    /// @param auctionId Auction Id
    function settleAuction(address accountingEngine, uint auctionId) public {
        // gives RAI to your proxy and then the proxy sends all of its RAI balance to you
    }

    /// @notice Claims the full FLX and RAI balances of your proxy and sends them to you
    function claimProxyFunds() public {
        // claims the full FLX and RAI balances of your proxy and sends them to you
    }

}

