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

abstract contract AccountingEngineLike {
    function debtAuctionHouse() external virtual returns (address);
    function surplusAuctionHouse() external virtual returns (address);
    function auctionDebt() external virtual returns (uint256);
    function auctionSurplus() external virtual returns (uint256);
}

abstract contract DebtAuctionHouseLike {
    function bids(uint) external virtual returns (uint, uint, address, uint48, uint48);
    function decreaseSoldAmount(uint256, uint256, uint256) external virtual;
    function restartAuction(uint256) external virtual;
    function settleAuction(uint256) external virtual;
    function protocolToken() external virtual returns (address);
}

abstract contract SurplusAuctionHouseLike {
    function bids(uint) external virtual returns (uint, uint, address, uint48, uint48);
    function increaseBidSize(uint256 id, uint256 amountToBuy, uint256 bid) external virtual;
    function restartAuction(uint256) external virtual;
    function settleAuction(uint256) external virtual;
}

abstract contract DSTokenLike {
    function balanceOf(address) external virtual returns (uint);
    function transfer(address, uint) external virtual returns (bool);
    function transferFrom(address, address, uint) external virtual returns (bool);
    function move(address, address, uint) external virtual returns (bool);
    function approve(address, uint) external virtual returns (bool);
}

contract Common {
    /// @notice Claims the full balance of any ERC20 token in the proxy's balance
    /// @param tokenAddress Address of the token
    function claimProxyFunds(address tokenAddress) public {
        DSTokenLike token = DSTokenLike(tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    /// @notice Claims the full balance of several ERC20 tokens in the proxy's balance
    /// @param tokenAddresses Addresses of the tokens
    function claimProxyFunds(address[] memory tokenAddresses) public {
        for (uint i = 0; i < tokenAddresses.length; i++)
            claimProxyFunds(tokenAddresses[i]);
    }
}

contract GebProxyDebtAuctionActions is Common {

    /// @notice Starts auction and bids
    /// @param accountingEngineAddress AccountingEngine
    /// @param amountToBuy Sold amount
    function startAndDecraseSoldAmount(address accountingEngineAddress, uint amountToBuy) public {
        AccountingEngineLike accountingEngine = AccountingEngineLike(accountingEngineAddress);
        DebtAuctionHouseLike debtAuctionHouse = DebtAuctionHouseLike(accountingEngine.debtAuctionHouse());
        uint auctionId = accountingEngine.auctionDebt();
        (uint bidAmount,,,,) = debtAuctionHouse.bids(auctionId);
        debtAuctionHouse.decreaseSoldAmount(auctionId, amountToBuy, bidAmount);
    }

    /// @notice Bids on auction. Restarts the auction if necessary
    /// @param auctionHouse Auction house address
    /// @param auctionId Auction Id
    /// @param amountToBuy Sold amount
    function decreaseSoldAmount(address auctionHouse, uint auctionId, uint amountToBuy) public {
        DebtAuctionHouseLike debtAuctionHouse = DebtAuctionHouseLike(auctionHouse);
        (uint bid,,, uint48 bidExpiry, uint48 auctionDeadline) = debtAuctionHouse.bids(auctionId); 
        
        if (auctionDeadline < now && bidExpiry == 0) {
            debtAuctionHouse.restartAuction(auctionId);
        }       
        debtAuctionHouse.decreaseSoldAmount(auctionId, amountToBuy, bid);
    }

    /// @notice Mints FLX for your proxy and then the proxy sends all of its FLX balance to you
    /// @param auctionHouse Auction house address
    /// @param auctionId Auction Id
    function settleAuction(address auctionHouse, uint auctionId) public {
        DebtAuctionHouseLike debtAuctionHouse = DebtAuctionHouseLike(auctionHouse);
        debtAuctionHouse.settleAuction(auctionId);
        DSTokenLike protocolToken = DSTokenLike(debtAuctionHouse.protocolToken());
        protocolToken.transfer(msg.sender, protocolToken.balanceOf(address(this)));
    }
}

contract GebProxySurplusAuctionActions is Common {

    /// @notice Starts surplus auction and bids
    /// @param accountingEngineAddress AccountingEngine
    /// @param bidAmount Bid size
    function startAndIncreaseBidSize(address accountingEngineAddress, uint bidAmount) public {
        // this will first call AccountingEngine.auctionSurplus() and then call increaseBidSize to bid in the auction
        AccountingEngineLike accountingEngine = AccountingEngineLike(accountingEngineAddress);
        SurplusAuctionHouseLike surplusAuctionHouse = SurplusAuctionHouseLike(accountingEngine.surplusAuctionHouse());
        uint auctionId = accountingEngine.auctionSurplus();
        (, uint amountToBuy,,,) = surplusAuctionHouse.bids(auctionId);
        surplusAuctionHouse.increaseBidSize(auctionId, amountToBuy, bidAmount);
    }

    /// @notice Bids in auction. Restarts the auction if necessary
    /// @param auctionHouse Auction house address
    /// @param auctionId Auction Id
    /// @param bidSize Bid size
    function increaseBidSize(address auctionHouse, uint auctionId, uint bidSize) public {
        SurplusAuctionHouseLike surplusAuctionHouse = SurplusAuctionHouseLike(auctionHouse);
        (, uint amountToBuy,, uint48 bidExpiry, uint48 auctionDeadline) = surplusAuctionHouse.bids(auctionId); 
        
        if (auctionDeadline < now && bidExpiry == 0) {
            surplusAuctionHouse.restartAuction(auctionId);
        }       
        surplusAuctionHouse.increaseBidSize(auctionId, amountToBuy, bidSize);
    }

    /// @notice Mints FLX for your proxy and then the proxy sends all of its FLX balance to you
    /// @param auctionHouse Auction house address
    /// @param auctionId Auction Id
    function settleAuction(address auctionHouse, uint auctionId) public {
        SurplusAuctionHouseLike surplusAuctionHouse = SurplusAuctionHouseLike(auctionHouse);
        surplusAuctionHouse.settleAuction(auctionId);

        // need to exit RAI from the system here
    }
}

