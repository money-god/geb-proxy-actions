
pragma solidity 0.6.7;

import "ds-test/test.sol";
import "ds-weth/weth9.sol";
import "ds-token/token.sol";

import {GebProxyDebtAuctionActions, GebProxySurplusAuctionActions} from "../gebProxyAuctionActions.sol";

import {Feed, GebDeployTestBase, EnglishCollateralAuctionHouse} from "geb-deploy/test/GebDeploy.t.base.sol";
import {DGD, GNT} from "./tokens.sol";
import {CollateralJoin3, CollateralJoin4} from "geb-deploy/AdvancedTokenAdapters.sol";
import {DSValue} from "ds-value/value.sol";
import {GebSafeManager} from "geb-safe-manager/GebSafeManager.sol";
import {GetSafes} from "geb-safe-manager/GetSafes.sol";
import {GebProxyRegistry, DSProxyFactory, DSProxy} from "geb-proxy-registry/GebProxyRegistry.sol";

contract ProxyCalls {
    DSProxy proxy;
    address gebProxyAuctionActions;
}

contract GebProxyLeverageActionsTest is GebDeployTestBase, ProxyCalls {
    GebSafeManager manager;

    GebProxyRegistry registry;

    bytes32 collateralAuctionType = bytes32("ENGLISH");

    function setUp() override public {
        super.setUp();
        deployStableKeepAuth(collateralAuctionType);

        manager = new GebSafeManager(address(safeEngine));
        DSProxyFactory factory = new DSProxyFactory();
        registry = new GebProxyRegistry(address(factory));
        gebProxyAuctionActions = address(new GebProxyDebtAuctionActions());
        proxy = DSProxy(registry.build());

        this.modifyParameters(address(accountingEngine), "debtAuctionBidSize", uint(1 ether));


    }

    function test_sanity() public {
        assertTrue(true);
    }


}