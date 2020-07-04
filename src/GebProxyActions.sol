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

pragma solidity ^0.6.7;

abstract contract CollateralLike {
    function approve(address, uint) virtual public;
    function transfer(address, uint) virtual public;
    function transferFrom(address, address, uint) virtual public;
    function deposit() virtual public payable;
    function withdraw(uint) virtual public;
}

abstract contract ManagerLike {
    function cdpCan(address, uint, address) virtual public view returns (uint);
    function collateralTypes(uint) virtual public view returns (bytes32);
    function ownsCDP(uint) virtual public view returns (address);
    function cdps(uint) virtual public view returns (address);
    function cdpEngine() virtual public view returns (address);
    function openCDP(bytes32, address) virtual public returns (uint);
    function transferCDPOwnership(uint, address) virtual public;
    function allowCDP(uint, address, uint) virtual public;
    function allowHandler(address, uint) virtual public;
    function modifyCDPCollateralization(uint, int, int) virtual public;
    function transferCollateral(uint, address, uint) virtual public;
    function transferInternalCoins(uint, address, uint) virtual public;
    function quitSystem(uint, address) virtual public;
    function enterSystem(address, uint) virtual public;
    function moveCDP(uint, uint) virtual public;
}

abstract contract CDPEngineLike {
    function canModifyCDP(address, address) virtual public view returns (uint);
    function collateralTypes(bytes32) virtual public view returns (uint, uint, uint, uint, uint);
    function coinBalance(address) virtual public view returns (uint);
    function cdps(bytes32, address) virtual public view returns (uint, uint);
    function modifyCDPCollateralization(bytes32, address, address, address, int, int) virtual public;
    function approveCDPModification(address) virtual public;
    function transferInternalCoins(address, address, uint) virtual public;
}

abstract contract CollateralJoinLike {
    function decimals() virtual public returns (uint);
    function collateral() virtual public returns (CollateralLike);
    function join(address, uint) virtual public payable;
    function exit(address, uint) virtual public;
}

abstract contract GNTJoinLike {
    function bags(address) virtual public view returns (address);
    function make(address) virtual public returns (address);
}

abstract contract DSTokenLike {
    function approve(address, uint) virtual public;
    function transfer(address, uint) virtual public;
    function transferFrom(address, address, uint) virtual public;
}

abstract contract CoinJoinLike {
    function cdpEngine() virtual public returns (CDPEngineLike);
    function systemCoin() virtual public returns (DSTokenLike);
    function join(address, uint) virtual public payable;
    function exit(address, uint) virtual public;
}

abstract contract ApproveCDPModificationLike {
    function approveCDPModification(address) virtual public;
    function denyCDPModification(address) virtual public;
}

abstract contract GlobalSettlementLike {
    function collateralCashPrice(bytes32) virtual public view returns (uint);
    function redeemCollateral(bytes32, uint) virtual public;
    function freeCollateral(bytes32) virtual public;
    function prepareCoinsForRedeeming(uint) virtual public;
    function processCDP(bytes32, address) virtual public;
}

abstract contract TaxCollectorLike {
    function taxSingle(bytes32) virtual public returns (uint);
}

abstract contract CoinSavingsAccountLike {
    function savings(address) virtual public view returns (uint);
    function updateAccumulatedRate() virtual public returns (uint);
    function deposit(uint) virtual public;
    function withdraw(uint) virtual public;
}

abstract contract ProxyRegistryLike {
    function proxies(address) virtual public view returns (address);
    function build(address) virtual public returns (address);
}

abstract contract ProxyLike {
    function owner() virtual public view returns (address);
}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a DSProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

contract Common {
    uint256 constant RAY = 10 ** 27;

    // Internal functions

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "mul-overflow");
    }

    // Public functions
    function coinJoin_join(address apt, address urn, uint wad) public {
        // Gets COIN from the user's wallet
        CoinJoinLike(apt).systemCoin().transferFrom(msg.sender, address(this), wad);
        // Approves adapter to take the COIN amount
        CoinJoinLike(apt).systemCoin().approve(apt, wad);
        // Joins COIN into the cdpEngine
        CoinJoinLike(apt).join(urn, wad);
    }
}

contract GebProxyActions is Common {
    // Internal functions

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }

    function toInt(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0, "int-overflow");
    }

    function toRad(uint wad) internal pure returns (uint rad) {
        rad = mul(wad, 10 ** 27);
    }

    function convertTo18(address collateralJoin, uint256 amt) internal returns (uint256 wad) {
        // For those collaterals that have less than 18 decimals precision we need to do the conversion before passing to frob function
        // Adapters will automatically handle the difference of precision
        wad = mul(
            amt,
            10 ** (18 - CollateralJoinLike(collateralJoin).decimals())
        );
    }

    function _getGeneratedDeltaDebt(
        address cdpEngine,
        address taxCollector,
        address urn,
        bytes32 collateralType,
        uint wad
    ) internal returns (int deltaDebt) {
        // Updates stability fee rate
        uint rate = TaxCollectorLike(taxCollector).taxSingle(collateralType);

        // Gets COIN balance of the urn in the cdpEngine
        uint coin = CDPEngineLike(cdpEngine).coinBalance(urn);

        // If there was already enough COIN in the cdpEngine balance, just exits it without adding more debt
        if (coin < mul(wad, RAY)) {
            // Calculates the needed deltaDebt so together with the existing coins in the cdpEngine is enough to exit wad amount of COIN tokens
            deltaDebt = toInt(sub(mul(wad, RAY), coin) / rate);
            // This is neeeded due lack of precision. It might need to sum an extra deltaDebt wei (for the given COIN wad amount)
            deltaDebt = mul(uint(deltaDebt), rate) < mul(wad, RAY) ? deltaDebt + 1 : deltaDebt;
        }
    }

    function _getRepaidDeltaDebt(
        address cdpEngine,
        uint coin,
        address cdp,
        bytes32 collateralType
    ) internal view returns (int deltaDebt) {
        // Gets actual rate from the cdpEngine
        (, uint rate,,,) = CDPEngineLike(cdpEngine).collateralTypes(collateralType);
        // Gets actual generatedDebt value of the cdp
        (, uint generatedDebt) = CDPEngineLike(cdpEngine).cdps(collateralType, cdp);

        // Uses the whole coin balance in the cdpEngine to reduce the debt
        deltaDebt = toInt(coin / rate);
        // Checks the calculated deltaDebt is not higher than cdp.generatedDebt (total debt), otherwise uses its value
        deltaDebt = uint(deltaDebt) <= generatedDebt ? - deltaDebt : - toInt(generatedDebt);
    }

    function _getWipeAllDebt(
        address cdpEngine,
        address usr,
        address cdp,
        bytes32 collateralType
    ) internal view returns (uint wad) {
        // Gets actual rate from the cdpEngine
        (, uint rate,,,) = CDPEngineLike(cdpEngine).collateralTypes(collateralType);
        // Gets actual generatedDebt value of the cdp
        (, uint generatedDebt) = CDPEngineLike(cdpEngine).cdps(collateralType, cdp);
        // Gets actual coin amount in the cdp
        uint coin = CDPEngineLike(cdpEngine).coinBalance(usr);

        uint rad = sub(mul(generatedDebt, rate), coin);
        wad = rad / RAY;

        // If the rad precision has some dust, it will need to request for 1 extra wad wei
        wad = mul(wad, RAY) < rad ? wad + 1 : wad;
    }

    // Public functions
    function transfer(address collateral, address dst, uint amt) public {
        CollateralLike(collateral).transfer(dst, amt);
    }

    function ethJoin_join(address apt, address cdp) public payable {
        // Wraps ETH in WETH
        CollateralJoinLike(apt).collateral().deposit{value: msg.value}();
        // Approves adapter to take the WETH amount
        CollateralJoinLike(apt).collateral().approve(address(apt), msg.value);
        // Joins WETH collateral into the cdpEngine
        CollateralJoinLike(apt).join(cdp, msg.value);
    }

    function tokenCollateralJoin_join(address apt, address cdp, uint amt, bool transferFrom) public {
        // Only executes for tokens that have approval/transferFrom implementation
        if (transferFrom) {
            // Gets token from the user's wallet
            CollateralJoinLike(apt).collateral().transferFrom(msg.sender, address(this), amt);
            // Approves adapter to take the token amount
            CollateralJoinLike(apt).collateral().approve(apt, amt);
        }
        // Joins token collateral into the cdpEngine
        CollateralJoinLike(apt).join(cdp, amt);
    }

    function approveCDPModification(
        address obj,
        address usr
    ) public {
        ApproveCDPModificationLike(obj).approveCDPModification(usr);
    }

    function denyCDPModification(
        address obj,
        address usr
    ) public {
        ApproveCDPModificationLike(obj).denyCDPModification(usr);
    }

    function openCDP(
        address manager,
        bytes32 collateralType,
        address usr
    ) public returns (uint cdp) {
        cdp = ManagerLike(manager).openCDP(collateralType, usr);
    }

    function transferCDPOwnership(
        address manager,
        uint cdp,
        address usr
    ) public {
        ManagerLike(manager).transferCDPOwnership(cdp, usr);
    }

    function giveToProxy(
        address proxyRegistry,
        address manager,
        uint cdp,
        address dst
    ) public {
        // Gets actual proxy address
        address proxy = ProxyRegistryLike(proxyRegistry).proxies(dst);
        // Checks if the proxy address already existed and dst address is still the owner
        if (proxy == address(0) || ProxyLike(proxy).owner() != dst) {
            uint csize;
            assembly {
                csize := extcodesize(dst)
            }
            // We want to avoid creating a proxy for a contract address that might not be able to handle proxies, then losing the CDP
            require(csize == 0, "dst-is-a-contract");
            // Creates the proxy for the dst address
            proxy = ProxyRegistryLike(proxyRegistry).build(dst);
        }
        // Transfers CDP to the dst proxy
        transferCDPOwnership(manager, cdp, proxy);
    }

    function allowCDP(
        address manager,
        uint cdp,
        address usr,
        uint ok
    ) public {
        ManagerLike(manager).allowCDP(cdp, usr, ok);
    }

    function allowHandler(
        address manager,
        address usr,
        uint ok
    ) public {
        ManagerLike(manager).allowHandler(usr, ok);
    }

    function transferCollateral(
        address manager,
        uint cdp,
        address dst,
        uint wad
    ) public {
        ManagerLike(manager).transferCollateral(cdp, dst, wad);
    }

    function transferInternalCoins(
        address manager,
        uint cdp,
        address dst,
        uint rad
    ) public {
        ManagerLike(manager).transferInternalCoins(cdp, dst, rad);
    }

    function modifyCDPCollateralization(
        address manager,
        uint cdp,
        int deltaCollateral,
        int deltaDebt
    ) public {
        ManagerLike(manager).modifyCDPCollateralization(cdp, deltaCollateral, deltaDebt);
    }

    function quitSystem(
        address manager,
        uint cdp,
        address dst
    ) public {
        ManagerLike(manager).quitSystem(cdp, dst);
    }

    function enterSystem(
        address manager,
        address src,
        uint cdp
    ) public {
        ManagerLike(manager).enterSystem(src, cdp);
    }

    function moveCDP(
        address manager,
        uint cdpSrc,
        uint cdpDst
    ) public {
        ManagerLike(manager).moveCDP(cdpSrc, cdpDst);
    }

    function makeCollateralBag(
        address collateralJoin
    ) public returns (address bag) {
        bag = GNTJoinLike(collateralJoin).make(address(this));
    }

    function lockETH(
        address manager,
        address ethJoin,
        uint cdp
    ) public payable {
        // Receives ETH amount, converts it to WETH and joins it into the cdpEngine
        ethJoin_join(ethJoin, address(this));
        // Locks WETH amount into the CDP
        CDPEngineLike(ManagerLike(manager).cdpEngine()).modifyCDPCollateralization(
            ManagerLike(manager).collateralTypes(cdp),
            ManagerLike(manager).cdps(cdp),
            address(this),
            address(this),
            toInt(msg.value),
            0
        );
    }

    function safeLockETH(
        address manager,
        address ethJoin,
        uint cdp,
        address owner
    ) public payable {
        require(ManagerLike(manager).ownsCDP(cdp) == owner, "owner-missmatch");
        lockETH(manager, ethJoin, cdp);
    }

    function lockTokenCollateral(
        address manager,
        address collateralJoin,
        uint cdp,
        uint amt,
        bool transferFrom
    ) public {
        // Takes token amount from user's wallet and joins into the cdpEngine
        tokenCollateralJoin_join(collateralJoin, address(this), amt, transferFrom);
        // Locks token amount into the CDP
        CDPEngineLike(ManagerLike(manager).cdpEngine()).modifyCDPCollateralization(
            ManagerLike(manager).collateralTypes(cdp),
            ManagerLike(manager).cdps(cdp),
            address(this),
            address(this),
            toInt(convertTo18(collateralJoin, amt)),
            0
        );
    }

    function safeLockTokenCollateral(
        address manager,
        address collateralJoin,
        uint cdp,
        uint amt,
        bool transferFrom,
        address owner
    ) public {
        require(ManagerLike(manager).ownsCDP(cdp) == owner, "owner-missmatch");
        lockTokenCollateral(manager, collateralJoin, cdp, amt, transferFrom);
    }

    function freeETH(
        address manager,
        address ethJoin,
        uint cdp,
        uint wad
    ) public {
        // Unlocks WETH amount from the CDP
        modifyCDPCollateralization(manager, cdp, -toInt(wad), 0);
        // Moves the amount from the CDP handler to proxy's address
        transferCollateral(manager, cdp, address(this), wad);
        // Exits WETH amount to proxy address as a token
        CollateralJoinLike(ethJoin).exit(address(this), wad);
        // Converts WETH to ETH
        CollateralJoinLike(ethJoin).collateral().withdraw(wad);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(wad);
    }

    function freeTokenCollateral(
        address manager,
        address collateralJoin,
        uint cdp,
        uint amt
    ) public {
        uint wad = convertTo18(collateralJoin, amt);
        // Unlocks token amount from the CDP
        modifyCDPCollateralization(manager, cdp, -toInt(wad), 0);
        // Moves the amount from the CDP urn to proxy's address
        transferCollateral(manager, cdp, address(this), wad);
        // Exits token amount to the user's wallet as a token
        CollateralJoinLike(collateralJoin).exit(msg.sender, amt);
    }

    function exitETH(
        address manager,
        address ethJoin,
        uint cdp,
        uint wad
    ) public {
        // Moves the amount from the CDP urn to proxy's address
        transferCollateral(manager, cdp, address(this), wad);
        // Exits WETH amount to proxy address as a token
        CollateralJoinLike(ethJoin).exit(address(this), wad);
        // Converts WETH to ETH
        CollateralJoinLike(ethJoin).collateral().withdraw(wad);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(wad);
    }

    function exitTokenCollateral(
        address manager,
        address collateralJoin,
        uint cdp,
        uint amt
    ) public {
        // Moves the amount from the CDP urn to proxy's address
        transferCollateral(manager, cdp, address(this), convertTo18(collateralJoin, amt));

        // Exits token amount to the user's wallet as a token
        CollateralJoinLike(collateralJoin).exit(msg.sender, amt);
    }

    function generateDebt(
        address manager,
        address taxCollector,
        address coinJoin,
        uint cdp,
        uint wad
    ) public {
        address cdpHandler = ManagerLike(manager).cdps(cdp);
        address cdpEngine = ManagerLike(manager).cdpEngine();
        bytes32 collateralType = ManagerLike(manager).collateralTypes(cdp);
        // Generates debt in the CDP
        modifyCDPCollateralization(manager, cdp, 0, _getGeneratedDeltaDebt(cdpEngine, taxCollector, cdpHandler, collateralType, wad));
        // Moves the COIN amount (balance in the cdpEngine in rad) to proxy's address
        transferInternalCoins(manager, cdp, address(this), toRad(wad));
        // Allows adapter to access to proxy's COIN balance in the cdpEngine
        if (CDPEngineLike(cdpEngine).canModifyCDP(address(this), address(coinJoin)) == 0) {
            CDPEngineLike(cdpEngine).approveCDPModification(coinJoin);
        }
        // Exits COIN to the user's wallet as a token
        CoinJoinLike(coinJoin).exit(msg.sender, wad);
    }

    function repayDebt(
        address manager,
        address coinJoin,
        uint cdp,
        uint wad
    ) public {
        address cdpEngine = ManagerLike(manager).cdpEngine();
        address cdpHandler = ManagerLike(manager).cdps(cdp);
        bytes32 collateralType = ManagerLike(manager).collateralTypes(cdp);

        address own = ManagerLike(manager).ownsCDP(cdp);
        if (own == address(this) || ManagerLike(manager).cdpCan(own, cdp, address(this)) == 1) {
            // Joins COIN amount into the cdpEngine
            coinJoin_join(coinJoin, cdpHandler, wad);
            // // Paybacks debt to the CDP
            modifyCDPCollateralization(manager, cdp, 0, _getRepaidDeltaDebt(cdpEngine, CDPEngineLike(cdpEngine).coinBalance(cdpHandler), cdpHandler, collateralType));
        } else {
             // Joins COIN amount into the cdpEngine
            coinJoin_join(coinJoin, address(this), wad);
            // Paybacks debt to the CDP
            CDPEngineLike(cdpEngine).modifyCDPCollateralization(
                collateralType,
                cdpHandler,
                address(this),
                address(this),
                0,
                _getRepaidDeltaDebt(cdpEngine, wad * RAY, cdpHandler, collateralType)
            );
        }
    }

    function safeRepayDebt(
        address manager,
        address coinJoin,
        uint cdp,
        uint wad,
        address owner
    ) public {
        require(ManagerLike(manager).ownsCDP(cdp) == owner, "owner-missmatch");
        repayDebt(manager, coinJoin, cdp, wad);
    }

    function repayAllDebt(
        address manager,
        address coinJoin,
        uint cdp
    ) public {
        address cdpEngine = ManagerLike(manager).cdpEngine();
        address cdpHandler = ManagerLike(manager).cdps(cdp);
        bytes32 collateralType = ManagerLike(manager).collateralTypes(cdp);
        (, uint generatedDebt) = CDPEngineLike(cdpEngine).cdps(collateralType, cdpHandler);

        address own = ManagerLike(manager).ownsCDP(cdp);
        if (own == address(this) || ManagerLike(manager).cdpCan(own, cdp, address(this)) == 1) {
            // Joins COIN amount into the cdpEngine
            coinJoin_join(coinJoin, cdpHandler, _getWipeAllDebt(cdpEngine, cdpHandler, cdpHandler, collateralType));
            // Paybacks debt to the CDP
            modifyCDPCollateralization(manager, cdp, 0, -int(generatedDebt));
        } else {
            // Joins COIN amount into the cdpEngine
            coinJoin_join(coinJoin, address(this), _getWipeAllDebt(cdpEngine, address(this), cdpHandler, collateralType));
            // Paybacks debt to the CDP
            CDPEngineLike(cdpEngine).modifyCDPCollateralization(
                collateralType,
                cdpHandler,
                address(this),
                address(this),
                0,
                -int(generatedDebt)
            );
        }
    }

    function safeRepayAllDebt(
        address manager,
        address coinJoin,
        uint cdp,
        address owner
    ) public {
        require(ManagerLike(manager).ownsCDP(cdp) == owner, "owner-missmatch");
        repayAllDebt(manager, coinJoin, cdp);
    }

    function lockETHAndGenerateDebt(
        address manager,
        address taxCollector,
        address ethJoin,
        address coinJoin,
        uint cdp,
        uint deltaWad
    ) public payable {
        address cdpHandler = ManagerLike(manager).cdps(cdp);
        address cdpEngine = ManagerLike(manager).cdpEngine();
        bytes32 collateralType = ManagerLike(manager).collateralTypes(cdp);
        // Receives ETH amount, converts it to WETH and joins it into the cdpEngine
        ethJoin_join(ethJoin, cdpHandler);
        // Locks WETH amount into the CDP and generates debt
        modifyCDPCollateralization(manager, cdp, toInt(msg.value), _getGeneratedDeltaDebt(cdpEngine, taxCollector, cdpHandler, collateralType, deltaWad));
        // Moves the COIN amount (balance in the cdpEngine in rad) to proxy's address
        transferInternalCoins(manager, cdp, address(this), toRad(deltaWad));
        // Allows adapter to access to proxy's COIN balance in the cdpEngine
        if (CDPEngineLike(cdpEngine).canModifyCDP(address(this), address(coinJoin)) == 0) {
            CDPEngineLike(cdpEngine).approveCDPModification(coinJoin);
        }
        // Exits COIN to the user's wallet as a token
        CoinJoinLike(coinJoin).exit(msg.sender, deltaWad);
    }

    function openLockETHAndGenerateDebt(
        address manager,
        address taxCollector,
        address ethJoin,
        address coinJoin,
        bytes32 collateralType,
        uint deltaWad
    ) public payable returns (uint cdp) {
        cdp = openCDP(manager, collateralType, address(this));
        lockETHAndGenerateDebt(manager, taxCollector, ethJoin, coinJoin, cdp, deltaWad);
    }

    function lockTokenCollateralAndGenerateDebt(
        address manager,
        address taxCollector,
        address collateralJoin,
        address coinJoin,
        uint cdp,
        uint collateralAmount,
        uint deltaWad,
        bool transferFrom
    ) public {
        address cdpHandler = ManagerLike(manager).cdps(cdp);
        address cdpEngine = ManagerLike(manager).cdpEngine();
        bytes32 collateralType = ManagerLike(manager).collateralTypes(cdp);
        // Takes token amount from user's wallet and joins into the cdpEngine
        tokenCollateralJoin_join(collateralJoin, cdpHandler, collateralAmount, transferFrom);
        // Locks token amount into the CDP and generates debt
        modifyCDPCollateralization(manager, cdp, toInt(convertTo18(collateralJoin, collateralAmount)), _getGeneratedDeltaDebt(cdpEngine, taxCollector, cdpHandler, collateralType, deltaWad));
        // Moves the COIN amount (balance in the cdpEngine in rad) to proxy's address
        transferInternalCoins(manager, cdp, address(this), toRad(deltaWad));
        // Allows adapter to access to proxy's COIN balance in the cdpEngine
        if (CDPEngineLike(cdpEngine).canModifyCDP(address(this), address(coinJoin)) == 0) {
            CDPEngineLike(cdpEngine).approveCDPModification(coinJoin);
        }
        // Exits COIN to the user's wallet as a token
        CoinJoinLike(coinJoin).exit(msg.sender, deltaWad);
    }

    function openLockTokenCollateralAndGenerateDebt(
        address manager,
        address taxCollector,
        address collateralJoin,
        address coinJoin,
        bytes32 collateralType,
        uint collateralAmount,
        uint deltaWad,
        bool transferFrom
    ) public returns (uint cdp) {
        cdp = openCDP(manager, collateralType, address(this));
        lockTokenCollateralAndGenerateDebt(manager, taxCollector, collateralJoin, coinJoin, cdp, collateralAmount, deltaWad, transferFrom);
    }

    function openLockGNTAndGenerateDebt(
        address manager,
        address taxCollector,
        address gntJoin,
        address coinJoin,
        bytes32 collateralType,
        uint collateralAmount,
        uint deltaWad
    ) public returns (address bag, uint cdp) {
        // Creates bag (if doesn't exist) to hold GNT
        bag = GNTJoinLike(gntJoin).bags(address(this));
        if (bag == address(0)) {
            bag = makeCollateralBag(gntJoin);
        }
        // Transfer funds to the funds which previously were sent to the proxy
        CollateralLike(CollateralJoinLike(gntJoin).collateral()).transfer(bag, collateralAmount);
        cdp = openLockTokenCollateralAndGenerateDebt(manager, taxCollector, gntJoin, coinJoin, collateralType, collateralAmount, deltaWad, false);
    }

    function repayDebtAndFreeETH(
        address manager,
        address ethJoin,
        address coinJoin,
        uint cdp,
        uint collateralWad,
        uint deltaWad
    ) public {
        address cdpHandler = ManagerLike(manager).cdps(cdp);
        // Joins COIN amount into the cdpEngine
        coinJoin_join(coinJoin, cdpHandler, deltaWad);
        // Paybacks debt to the CDP and unlocks WETH amount from it
        modifyCDPCollateralization(
            manager,
            cdp,
            -toInt(collateralWad),
            _getRepaidDeltaDebt(ManagerLike(manager).cdpEngine(), CDPEngineLike(ManagerLike(manager).cdpEngine()).coinBalance(cdpHandler), cdpHandler, ManagerLike(manager).collateralTypes(cdp))
        );
        // Moves the amount from the CDP handler to proxy's address
        transferCollateral(manager, cdp, address(this), collateralWad);
        // Exits WETH amount to proxy address as a token
        CollateralJoinLike(ethJoin).exit(address(this), collateralWad);
        // Converts WETH to ETH
        CollateralJoinLike(ethJoin).collateral().withdraw(collateralWad);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(collateralWad);
    }

    function repayAllDebtAndFreeETH(
        address manager,
        address ethJoin,
        address coinJoin,
        uint cdp,
        uint collateralWad
    ) public {
        address cdpEngine = ManagerLike(manager).cdpEngine();
        address cdpHandler = ManagerLike(manager).cdps(cdp);
        bytes32 collateralType = ManagerLike(manager).collateralTypes(cdp);
        (, uint generatedDebt) = CDPEngineLike(cdpEngine).cdps(collateralType, cdpHandler);

        // Joins COIN amount into the cdpEngine
        coinJoin_join(coinJoin, cdpHandler, _getWipeAllDebt(cdpEngine, cdpHandler, cdpHandler, collateralType));
        // Paybacks debt to the CDP and unlocks WETH amount from it
        modifyCDPCollateralization(
            manager,
            cdp,
            -toInt(collateralWad),
            -int(generatedDebt)
        );
        // Moves the amount from the CDP handler to proxy's address
        transferCollateral(manager, cdp, address(this), collateralWad);
        // Exits WETH amount to proxy address as a token
        CollateralJoinLike(ethJoin).exit(address(this), collateralWad);
        // Converts WETH to ETH
        CollateralJoinLike(ethJoin).collateral().withdraw(collateralWad);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(collateralWad);
    }

    function repayDebtAndFreeTokenCollateral(
        address manager,
        address collateralJoin,
        address coinJoin,
        uint cdp,
        uint collateralAmount,
        uint deltaWad
    ) public {
        address cdpHandler = ManagerLike(manager).cdps(cdp);
        // Joins COIN amount into the cdpEngine
        coinJoin_join(coinJoin, cdpHandler, deltaWad);
        uint collateralWad = convertTo18(collateralJoin, collateralAmount);
        // Paybacks debt to the CDP and unlocks token amount from it
        modifyCDPCollateralization(
            manager,
            cdp,
            -toInt(collateralWad),
            _getRepaidDeltaDebt(ManagerLike(manager).cdpEngine(), CDPEngineLike(ManagerLike(manager).cdpEngine()).coinBalance(cdpHandler), cdpHandler, ManagerLike(manager).collateralTypes(cdp))
        );
        // Moves the amount from the CDP handler to proxy's address
        transferCollateral(manager, cdp, address(this), collateralWad);
        // Exits token amount to the user's wallet as a token
        CollateralJoinLike(collateralJoin).exit(msg.sender, collateralAmount);
    }

    function repayAllDebtAndFreeTokenCollateral(
        address manager,
        address collateralJoin,
        address coinJoin,
        uint cdp,
        uint collateralAmount
    ) public {
        address cdpEngine = ManagerLike(manager).cdpEngine();
        address cdpHandler = ManagerLike(manager).cdps(cdp);
        bytes32 collateralType = ManagerLike(manager).collateralTypes(cdp);
        (, uint generatedDebt) = CDPEngineLike(cdpEngine).cdps(collateralType, cdpHandler);

        // Joins COIN amount into the cdpEngine
        coinJoin_join(coinJoin, cdpHandler, _getWipeAllDebt(cdpEngine, cdpHandler, cdpHandler, collateralType));
        uint collateralWad = convertTo18(collateralJoin, collateralAmount);
        // Paybacks debt to the CDP and unlocks token amount from it
        modifyCDPCollateralization(
            manager,
            cdp,
            -toInt(collateralWad),
            -int(generatedDebt)
        );
        // Moves the amount from the CDP handler to proxy's address
        transferCollateral(manager, cdp, address(this), collateralWad);
        // Exits token amount to the user's wallet as a token
        CollateralJoinLike(collateralJoin).exit(msg.sender, collateralAmount);
    }
}

contract GebProxyActionsGlobalSettlement is Common {
    // Internal functions

    function _freeCollateral(
        address manager,
        address globalSettlement,
        uint cdp
    ) internal returns (uint lockedCollateral) {
        bytes32 collateralType = ManagerLike(manager).collateralTypes(cdp);
        address cdpHandler = ManagerLike(manager).cdps(cdp);
        CDPEngineLike cdpEngine = CDPEngineLike(ManagerLike(manager).cdpEngine());
        uint generatedDebt;
        (lockedCollateral, generatedDebt) = cdpEngine.cdps(collateralType, cdpHandler);

        // If CDP still has debt, it needs to be paid
        if (generatedDebt > 0) {
            GlobalSettlementLike(globalSettlement).processCDP(collateralType, cdpHandler);
            (lockedCollateral,) = cdpEngine.cdps(collateralType, cdpHandler);
        }
        // Approves the manager to transfer the position to proxy's address in the cdpEngine
        if (cdpEngine.canModifyCDP(address(this), address(manager)) == 0) {
            cdpEngine.approveCDPModification(manager);
        }
        // Transfers position from CDP to the proxy address
        ManagerLike(manager).quitSystem(cdp, address(this));
        // Frees the position and recovers the collateral in the cdpEngine registry
        GlobalSettlementLike(globalSettlement).freeCollateral(collateralType);
    }

    // Public functions
    function freeETH(
        address manager,
        address ethJoin,
        address globalSettlement,
        uint cdp
    ) public {
        uint wad = _freeCollateral(manager, globalSettlement, cdp);
        // Exits WETH amount to proxy address as a token
        CollateralJoinLike(ethJoin).exit(address(this), wad);
        // Converts WETH to ETH
        CollateralJoinLike(ethJoin).collateral().withdraw(wad);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(wad);
    }

    function freeTokenCollateral(
        address manager,
        address collateralJoin,
        address globalSettlement,
        uint cdp
    ) public {
        uint amt = _freeCollateral(manager, globalSettlement, cdp) / 10 ** (18 - CollateralJoinLike(collateralJoin).decimals());
        // Exits token amount to the user's wallet as a token
        CollateralJoinLike(collateralJoin).exit(msg.sender, amt);
    }

    function prepareCoinsForRedeeming(
        address coinJoin,
        address globalSettlement,
        uint wad
    ) public {
        coinJoin_join(coinJoin, address(this), wad);
        CDPEngineLike cdpEngine = CoinJoinLike(coinJoin).cdpEngine();
        // Approves the globalSettlement to take out COIN from the proxy's balance in the cdpEngine
        if (cdpEngine.canModifyCDP(address(this), address(globalSettlement)) == 0) {
            cdpEngine.approveCDPModification(globalSettlement);
        }
        GlobalSettlementLike(globalSettlement).prepareCoinsForRedeeming(wad);
    }

    function redeemETH(
        address ethJoin,
        address globalSettlement,
        bytes32 collateralType,
        uint wad
    ) public {
        GlobalSettlementLike(globalSettlement).redeemCollateral(collateralType, wad);
        uint collateralWad = mul(wad, GlobalSettlementLike(globalSettlement).collateralCashPrice(collateralType)) / RAY;
        // Exits WETH amount to proxy address as a token
        CollateralJoinLike(ethJoin).exit(address(this), collateralWad);
        // Converts WETH to ETH
        CollateralJoinLike(ethJoin).collateral().withdraw(collateralWad);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(collateralWad);
    }

    function redeemTokenCollateral(
        address collateralJoin,
        address globalSettlement,
        bytes32 collateralType,
        uint wad
    ) public {
        GlobalSettlementLike(globalSettlement).redeemCollateral(collateralType, wad);
        // Exits token amount to the user's wallet as a token
        uint amt = mul(wad, GlobalSettlementLike(globalSettlement).collateralCashPrice(collateralType)) / RAY / 10 ** (18 - CollateralJoinLike(collateralJoin).decimals());
        CollateralJoinLike(collateralJoin).exit(msg.sender, amt);
    }
}

contract GebProxyActionsCoinSavingsAccount is Common {
    function deposit(
        address coinJoin,
        address coinSavingsAccount,
        uint wad
    ) public {
        CDPEngineLike cdpEngine = CoinJoinLike(coinJoin).cdpEngine();
        // Executes updateAccumulatedRate to get the accumulatedRates updated to latestUpdateTime == now, otherwise join will fail
        uint accumulatedRates = CoinSavingsAccountLike(coinSavingsAccount).updateAccumulatedRate();
        // Joins wad amount to the cdpEngine balance
        coinJoin_join(coinJoin, address(this), wad);
        // Approves the coinSavingsAccount to take out COIN from the proxy's balance in the cdpEngine
        if (cdpEngine.canModifyCDP(address(this), address(coinSavingsAccount)) == 0) {
            cdpEngine.approveCDPModification(coinSavingsAccount);
        }
        // Joins the savings value (equivalent to the COIN wad amount) in the coinSavingsAccount
        CoinSavingsAccountLike(coinSavingsAccount).deposit(mul(wad, RAY) / accumulatedRates);
    }

    function withdraw(
        address coinJoin,
        address coinSavingsAccount,
        uint wad
    ) public {
        CDPEngineLike cdpEngine = CoinJoinLike(coinJoin).cdpEngine();
        // Executes updateAccumulatedRate to count the savings accumulated until this moment
        uint accumulatedRates = CoinSavingsAccountLike(coinSavingsAccount).updateAccumulatedRate();
        // Calculates the savings value in the coinSavingsAccount equivalent to the COIN wad amount
        uint savings = mul(wad, RAY) / accumulatedRates;
        // Exits COIN from the coinSavingsAccount
        CoinSavingsAccountLike(coinSavingsAccount).withdraw(savings);
        // Checks the actual balance of COIN in the cdpEngine after the coinSavingsAccount exit
        uint bal = CoinJoinLike(coinJoin).cdpEngine().coinBalance(address(this));
        // Allows adapter to access to proxy's COIN balance in the cdpEngine
        if (cdpEngine.canModifyCDP(address(this), address(coinJoin)) == 0) {
            cdpEngine.approveCDPModification(coinJoin);
        }
        // It is necessary to check if due rounding the exact wad amount can be exited by the adapter.
        // Otherwise it will do the maximum COIN balance in the cdpEngine
        CoinJoinLike(coinJoin).exit(
            msg.sender,
            bal >= mul(wad, RAY) ? wad : bal / RAY
        );
    }

    function withdrawAll(
        address coinJoin,
        address coinSavingsAccount
    ) public {
        CDPEngineLike cdpEngine = CoinJoinLike(coinJoin).cdpEngine();
        // Executes updateAccumulatedRate to count the savings accumulated until this moment
        uint accumulatedRates = CoinSavingsAccountLike(coinSavingsAccount).updateAccumulatedRate();
        // Gets the total savings belonging to the proxy address
        uint savings = CoinSavingsAccountLike(coinSavingsAccount).savings(address(this));
        // Exits COIN from the coinSavingsAccount
        CoinSavingsAccountLike(coinSavingsAccount).withdraw(savings);
        // Allows adapter to access to proxy's COIN balance in the cdpEngine
        if (cdpEngine.canModifyCDP(address(this), address(coinJoin)) == 0) {
            cdpEngine.approveCDPModification(coinJoin);
        }
        // Exits the COIN amount corresponding to the value of savings
        CoinJoinLike(coinJoin).exit(msg.sender, mul(accumulatedRates, savings) / RAY);
    }
}
