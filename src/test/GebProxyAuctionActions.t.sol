
pragma solidity 0.6.7;

import "ds-test/test.sol";
import "ds-weth/weth9.sol";
import "ds-token/token.sol";

import {GebProxySurplusAuctionActions, GebProxyDebtAuctionActions} from "../GebProxyAuctionActions.sol";
import {GebProxyRegistry, DSProxyFactory, DSProxy} from "geb-proxy-registry/GebProxyRegistry.sol";
import {GebSafeManager} from "geb-safe-manager/GebSafeManager.sol";

import {Feed, GebDeployTestBase} from "geb-deploy/test/GebDeploy.t.base.sol";

import "../uni/UniswapV2Factory.sol";
import "../uni/UniswapV2Pair.sol";
import "../uni/UniswapV2Router02.sol";

contract ProxyCalls {
    DSProxy proxy;
    address GebProxyAuctionActions;

}

contract GebProxyDebtAuctionActionsTest is GebDeployTestBase, ProxyCalls {
    GebSafeManager manager;

    GebProxyRegistry registry;
    bytes32 collateralAuctionType = bytes32("ENGLISH");

    function setUp() override public {
        super.setUp();
        deployStableKeepAuth(collateralAuctionType);

        manager = new GebSafeManager(address(safeEngine));
        DSProxyFactory factory = new DSProxyFactory();
        registry = new GebProxyRegistry(address(factory));
        GebProxyAuctionActions = address(new GebProxyDebtAuctionActions());
        proxy = DSProxy(registry.build());
    }
}

contract GebProxySurplusAuctionActionsTest is GebDeployTestBase, ProxyCalls {
    GebSafeManager manager;

    GebProxyRegistry registry;
    bytes32 collateralAuctionType = bytes32("ENGLISH");

    function setUp() override public {
        super.setUp();
        deployStableKeepAuth(collateralAuctionType);

        manager = new GebSafeManager(address(safeEngine));
        DSProxyFactory factory = new DSProxyFactory();
        registry = new GebProxyRegistry(address(factory));
        GebProxyAuctionActions = address(new GebProxySurplusAuctionActions());
        proxy = DSProxy(registry.build());
    }
}