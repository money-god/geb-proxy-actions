
pragma solidity 0.6.7;

import "ds-test/test.sol";
import "ds-weth/weth9.sol";
import "ds-token/token.sol";

import {GebProxyDebtAuctionActions, GebProxySurplusAuctionActions} from "../GebProxyAuctionActions.sol";

import {Feed, GebDeployTestBase, EnglishCollateralAuctionHouse} from "geb-deploy/test/GebDeploy.t.base.sol";
import {DGD, GNT} from "./tokens.sol";
import {CollateralJoin3, CollateralJoin4} from "geb-deploy/AdvancedTokenAdapters.sol";
import {DSValue} from "ds-value/value.sol";
import {GebSafeManager} from "geb-safe-manager/GebSafeManager.sol";
import {GetSafes} from "geb-safe-manager/GetSafes.sol";
import {GebProxyRegistry, DSProxyFactory, DSProxy} from "geb-proxy-registry/GebProxyRegistry.sol";

contract DebtProxyCalls {
    DSProxy proxy;
    address gebProxyAuctionActions;

    function startAndDecreaseSoldAmount(address, address, uint) public {
        proxy.execute(gebProxyAuctionActions, msg.data);
    }

    function decreaseSoldAmount(address, address, uint, uint) public {
        proxy.execute(gebProxyAuctionActions, msg.data);
    }

    function settleAuction(address, address, uint) public {
        proxy.execute(gebProxyAuctionActions, msg.data);
    }

    function claimProxyFunds(address) public {
        proxy.execute(gebProxyAuctionActions, msg.data);
    }

    function claimProxyFunds(address[] memory) public {
        proxy.execute(gebProxyAuctionActions, msg.data);
    }
}

contract SurplusProxyCalls {
    DSProxy proxy;
    address gebProxyAuctionActions;

    function startAndIncreaseBidSize(address, uint) public {
        proxy.execute(gebProxyAuctionActions, msg.data);
    }

    function increaseBidSize(address, uint, uint) public {
        proxy.execute(gebProxyAuctionActions, msg.data);
    }

    function settleAuction(address, address, uint) public {
        proxy.execute(gebProxyAuctionActions, msg.data);
    }
}

contract GebProxyDebtAuctionActionsTest is GebDeployTestBase, DebtProxyCalls {
    GebSafeManager manager;
    GebProxyRegistry registry;
    uint debtAuctionBidSize = uint(10 ether);

    bytes32 collateralAuctionType = bytes32("ENGLISH");

    function setUp() override public {
        super.setUp();
        deployStableWithCreatorPermissions(collateralAuctionType);

        manager = new GebSafeManager(address(safeEngine));
        DSProxyFactory factory = new DSProxyFactory();
        registry = new GebProxyRegistry(address(factory));
        gebProxyAuctionActions = address(new GebProxyDebtAuctionActions());
        proxy = DSProxy(registry.build());

        // forcing unbacked debt into the system, to allow for an auction to be triggered.
        // this address receives the newly created debt (to be used for bidding)
        this.modifyParameters(address(accountingEngine), "debtAuctionBidSize", debtAuctionBidSize);
        this.modifyParameters(address(accountingEngine), "initialDebtAuctionMintedTokens", uint(10 ether));
        safeEngine.createUnbackedDebt(address(accountingEngine), address(this), 100 * 10**45);

        safeEngine.approveSAFEModification(address(coinJoin));

        coinJoin.exit(address(this), 100 ether);
    }

    function testStartAndDecreaseSoldAmount() public {
        coin.approve(address(proxy), debtAuctionBidSize);
        this.startAndDecreaseSoldAmount(address(coinJoin), address(accountingEngine), 8 ether);

        (uint bidAmount, uint amountToBuy, address highBidder,,)
            = debtAuctionHouse.bids(1);

        assertEq(debtAuctionHouse.activeDebtAuctions(), 1);
        assertEq(highBidder, address(proxy));
        assertEq(bidAmount, debtAuctionBidSize);
        assertEq(amountToBuy, 8 ether);
    }

    function testDecreaseSoldAmountOngoingAuction() public {
        uint auctionId = accountingEngine.auctionDebt();

        coin.approve(address(proxy), debtAuctionBidSize);
        this.decreaseSoldAmount(address(coinJoin), address(debtAuctionHouse), auctionId, 8 ether);

        (uint bidAmount, uint amountToBuy, address highBidder,,)
            = debtAuctionHouse.bids(auctionId);

        assertEq(debtAuctionHouse.activeDebtAuctions(), 1);
        assertEq(highBidder, address(proxy));
        assertEq(bidAmount, debtAuctionBidSize);
        assertEq(amountToBuy, 8 ether);
    }

    function testDecreaseSoldAmountExpiredAuction() public {
        uint auctionId = accountingEngine.auctionDebt();
        (,,,, uint48 auctionDeadline) = debtAuctionHouse.bids(auctionId);

        hevm.warp(auctionDeadline + 1);
        coin.approve(address(proxy), debtAuctionBidSize);
        this.decreaseSoldAmount(address(coinJoin), address(debtAuctionHouse), auctionId, 8 ether);

        (uint bidAmount, uint amountToBuy, address highBidder,,)
            = debtAuctionHouse.bids(auctionId);

        assertEq(debtAuctionHouse.activeDebtAuctions(), 1);
        assertEq(highBidder, address(proxy));
        assertEq(bidAmount, debtAuctionBidSize);
        assertEq(amountToBuy, 8 ether);
    }

    function testSettleAuction() public {
        coin.approve(address(proxy), debtAuctionBidSize);
        this.startAndDecreaseSoldAmount(address(coinJoin), address(accountingEngine), 8 ether);

        (,,,,uint48 auctionDeadline)
            = debtAuctionHouse.bids(1);

        hevm.warp(auctionDeadline + 1);

        uint previousBalance = prot.balanceOf(address(this));

        this.settleAuction(address(coinJoin), address(debtAuctionHouse), 1);

        assertEq(debtAuctionHouse.activeDebtAuctions(), 0);
        assertEq(prot.balanceOf(address(this)), previousBalance + 8 ether);
        assertEq(prot.balanceOf(address(proxy)), 0);
        assertEq(coin.balanceOf(address(proxy)), 0);
    }

    function testClaimProxyFunds() public {
        uint balance = prot.balanceOf(address(this));

        prot.transfer(address(proxy), balance);

        assertEq(prot.balanceOf(address(this)), 0);
        assertEq(prot.balanceOf(address(proxy)), balance);

        this.claimProxyFunds(address(prot));

        assertEq(prot.balanceOf(address(this)), balance);
        assertEq(prot.balanceOf(address(proxy)), 0);
    }

    address[] public tokenAddresses;
    function testClaimProxyFundsMultiple() public {
        uint protBalance = prot.balanceOf(address(this));
        uint coinBalance = coin.balanceOf(address(this));

        prot.transfer(address(proxy), protBalance);
        coin.transfer(address(proxy), coinBalance);

        assertEq(prot.balanceOf(address(proxy)), protBalance);
        assertEq(coin.balanceOf(address(proxy)), coinBalance);

        tokenAddresses.push(address(prot));
        tokenAddresses.push(address(coin));

        this.claimProxyFunds(tokenAddresses);

        assertEq(prot.balanceOf(address(this)), protBalance);
        assertEq(coin.balanceOf(address(this)), coinBalance);
    }
}

contract GebProxySurplusAuctionActionsTest is GebDeployTestBase, SurplusProxyCalls {
    GebSafeManager manager;
    GebProxyRegistry registry;
    uint surplusAuctionAmountToSell = rad(100 ether);

    bytes32 collateralAuctionType = bytes32("ENGLISH");

    function generateDebt(bytes32 collateralType, uint coin) internal {
        safeEngine.modifyParameters("globalDebtCeiling", rad(coin));
        safeEngine.modifyParameters(collateralType, "debtCeiling", rad(coin));
        safeEngine.modifyParameters(collateralType, "safetyPrice", 10 ** 27 * 10000 ether);
        address self = address(this);
        safeEngine.modifyCollateralBalance(collateralType, self,  10 ** 27 * 1 ether);
        safeEngine.modifySAFECollateralization(collateralType, self, self, self, 1 ether, int(coin));
    }

    function setUp() override public {
        super.setUp();
        deployStableWithCreatorPermissions(collateralAuctionType);

        manager = new GebSafeManager(address(safeEngine));
        DSProxyFactory factory = new DSProxyFactory();
        registry = new GebProxyRegistry(address(factory));
        gebProxyAuctionActions = address(new GebProxySurplusAuctionActions());
        proxy = DSProxy(registry.build());

        // forcing surplus into the system, to allow for an auction to be triggered.
        generateDebt("ETH", 1000 ether);
        this.modifyParameters(address(accountingEngine), "surplusAuctionAmountToSell", surplusAuctionAmountToSell);
        this.modifyParameters(address(accountingEngine), "surplusBuffer", uint(1));
        safeEngine.updateAccumulatedRate("ETH", address(accountingEngine), int(ray(100 ether)));
    }

    function testStartAndIncreaseBidSize() public {
        prot.approve(address(proxy), surplusAuctionAmountToSell);
        this.startAndIncreaseBidSize(address(accountingEngine), 8 ether);

        (uint bidAmount, uint amountToSell, address highBidder,,)
            = recyclingSurplusAuctionHouse.bids(1);

        assertEq(recyclingSurplusAuctionHouse.auctionsStarted(), 1);
        assertEq(highBidder, address(proxy));
        assertEq(bidAmount, 8 ether);
        assertEq(amountToSell, surplusAuctionAmountToSell);
    }

    function testIncreaseBidSizeOngoingAuction() public {
        uint auctionId = accountingEngine.auctionSurplus();

        prot.approve(address(proxy), surplusAuctionAmountToSell);
        this.increaseBidSize(address(recyclingSurplusAuctionHouse), auctionId, 8 ether);

        (uint bidAmount, uint amountToSell, address highBidder,,)
            = recyclingSurplusAuctionHouse.bids(auctionId);

        assertEq(recyclingSurplusAuctionHouse.auctionsStarted(), 1);
        assertEq(highBidder, address(proxy));
        assertEq(bidAmount, 8 ether);
        assertEq(amountToSell, surplusAuctionAmountToSell);
    }

    function testIncreaseBidSizeExpiredAuction() public {
        uint auctionId = accountingEngine.auctionSurplus();
        (,,,, uint48 auctionDeadline) = recyclingSurplusAuctionHouse.bids(auctionId);

        hevm.warp(auctionDeadline + 1);

        prot.approve(address(proxy), surplusAuctionAmountToSell);
        this.increaseBidSize(address(recyclingSurplusAuctionHouse), auctionId, 8 ether);

        (uint bidAmount, uint amountToSell, address highBidder,,)
            = recyclingSurplusAuctionHouse.bids(auctionId);

        assertEq(recyclingSurplusAuctionHouse.auctionsStarted(), 1);
        assertEq(highBidder, address(proxy));
        assertEq(bidAmount, 8 ether);
        assertEq(amountToSell, surplusAuctionAmountToSell);
    }

    function testSettleAuction() public {
        prot.approve(address(proxy), surplusAuctionAmountToSell);
        this.startAndIncreaseBidSize(address(accountingEngine), 8 ether);

        (,,,,uint48 auctionDeadline)
            = recyclingSurplusAuctionHouse.bids(1);

        hevm.warp(auctionDeadline + 1);

        this.settleAuction(address(coinJoin), address(recyclingSurplusAuctionHouse), 1);

        assertEq(coin.balanceOf(address(this)), surplusAuctionAmountToSell / 10**27);
        assertEq(coin.balanceOf(address(proxy)), 0);
        assertEq(prot.balanceOf(address(proxy)), 0);
    }
}
