pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "../GebProxyActions.sol";

import {GebDeployTestBase, CollateralAuctionHouse} from "geb-deploy/GebDeploy.t.base.sol";
import {DGD, GNT} from "./tokens.sol";
import {CollateralJoin3, CollateralJoin4} from "geb-deploy/AdvancedTokenAdapters.sol";
import {DSValue} from "ds-value/value.sol";
import {GebCdpManager} from "geb-cdp-manager/GebCdpManager.sol";
import {GetCdps} from "geb-cdp-manager/GetCdps.sol";
import {ProxyRegistry, DSProxyFactory, DSProxy} from "proxy-registry/ProxyRegistry.sol";

contract ProxyCalls {
    DSProxy proxy;
    address gebProxyActions;
    address gebProxyActionsGlobalSettlement;
    address gebProxyActionsCoinSavingsAccount;

    function transfer(address, address, uint256) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function openCDP(address, bytes32, address) public returns (uint cdp) {
        bytes memory response = proxy.execute(gebProxyActions, msg.data);
        assembly {
            cdp := mload(add(response, 0x20))
        }
    }

    function transferCDPOwnership(address, uint, address) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function giveToProxy(address, address, uint, address) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function allowCDP(address, uint, address, uint) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function allowHandler(address, address, uint) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function approveCDPModification(address, address) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function denyCDPModification(address, address) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function transferCollateral(address, uint, address, uint) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function transferInternalCoins(address, uint, address, uint) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function modifyCDPCollateralization(address, uint, int, int) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function modifyCDPCollateralization(address, uint, address, int, int) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function quitSystem(address, uint, address) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function enterSystem(address, address, uint) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function moveCDP(address, uint, uint) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function lockETH(address, address, uint) public payable {
        (bool success,) = address(proxy).call{value: msg.value}(abi.encodeWithSignature("execute(address,bytes)", gebProxyActions, msg.data));
        require(success, "");
    }

    function safeLockETH(address, address, uint, address) public payable {
        (bool success,) = address(proxy).call{value: msg.value}(abi.encodeWithSignature("execute(address,bytes)", gebProxyActions, msg.data));
        require(success, "");
    }

    function lockTokenCollateral(address, address, uint, uint, bool) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function safeLockTokenCollateral(address, address, uint, uint, bool, address) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function makeCollateralBag(address) public returns (address bag) {
        address payable target = address(proxy);
        bytes memory data = abi.encodeWithSignature("execute(address,bytes)", gebProxyActions, msg.data);
        assembly {
            let succeeded := call(sub(gas(), 5000), target, callvalue(), add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize()
            let response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            bag := mload(add(response, 0x60))

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
    }

    function freeETH(address, address, uint, uint) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function freeTokenCollateral(address, address, uint, uint) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function exitETH(address, address, uint, uint) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function exitTokenCollateral(address, address, uint, uint) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function generateDebt(address, address, address, uint, uint) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function repayDebt(address, address, uint, uint) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function repayAllDebt(address, address, uint) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function safeRepayDebt(address, address, uint, uint, address) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function safeRepayAllDebt(address, address, uint, address) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function lockETHAndGenerateDebt(address, address, address, address, uint, uint) public payable {
        (bool success,) = address(proxy).call{value: msg.value}(abi.encodeWithSignature("execute(address,bytes)", gebProxyActions, msg.data));
        require(success, "");
    }

    function openLockETHAndGenerateDebt(address, address, address, address, bytes32, uint) public payable returns (uint cdp) {
        address payable target = address(proxy);
        bytes memory data = abi.encodeWithSignature("execute(address,bytes)", gebProxyActions, msg.data);
        assembly {
            let succeeded := call(sub(gas(), 5000), target, callvalue(), add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize()
            let response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            cdp := mload(add(response, 0x60))

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
    }

    function lockTokenCollateralAndGenerateDebt(address, address, address, address, uint, uint, uint, bool) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function openLockTokenCollateralAndGenerateDebt(address, address, address, address, bytes32, uint, uint, bool) public returns (uint cdp) {
        bytes memory response = proxy.execute(gebProxyActions, msg.data);
        assembly {
            cdp := mload(add(response, 0x20))
        }
    }

    function openLockGNTAndGenerateDebt(address, address, address, address, bytes32, uint, uint) public returns (address bag, uint cdp) {
        bytes memory response = proxy.execute(gebProxyActions, msg.data);
        assembly {
            bag := mload(add(response, 0x20))
            cdp := mload(add(response, 0x40))
        }
    }

    function repayDebtAndFreeETH(address, address, address, uint, uint, uint) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function repayAllDebtAndFreeETH(address, address, address, uint, uint) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function repayDebtAndFreeTokenCollateral(address, address, address, uint, uint, uint) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function repayAllDebtAndFreeTokenCollateral(address, address, address, uint, uint) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function globalSettlement_freeETH(address a, address b, address c, uint d) public {
        proxy.execute(gebProxyActionsGlobalSettlement, abi.encodeWithSignature("freeETH(address,address,address,uint256)", a, b, c, d));
    }

    function globalSettlement_freeTokenCollateral(address a, address b, address c, uint d) public {
        proxy.execute(gebProxyActionsGlobalSettlement, abi.encodeWithSignature("freeTokenCollateral(address,address,address,uint256)", a, b, c, d));
    }

    function globalSettlement_prepareCoinsForRedeeming(address a, address b, uint c) public {
        proxy.execute(gebProxyActionsGlobalSettlement, abi.encodeWithSignature("prepareCoinsForRedeeming(address,address,uint256)", a, b, c));
    }

    function globalSettlement_redeemETH(address a, address b, bytes32 c, uint d) public {
        proxy.execute(gebProxyActionsGlobalSettlement, abi.encodeWithSignature("redeemETH(address,address,bytes32,uint256)", a, b, c, d));
    }

    function globalSettlement_redeemTokenCollateral(address a, address b, bytes32 c, uint d) public {
        proxy.execute(gebProxyActionsGlobalSettlement, abi.encodeWithSignature("redeemTokenCollateral(address,address,bytes32,uint256)", a, b, c, d));
    }

    function coinSavingsAccount_deposit(address a, address b, uint c) public {
        proxy.execute(gebProxyActionsCoinSavingsAccount, abi.encodeWithSignature("deposit(address,address,uint256)", a, b, c));
    }

    function coinSavingsAccount_withdraw(address a, address b, uint c) public {
        proxy.execute(gebProxyActionsCoinSavingsAccount, abi.encodeWithSignature("withdraw(address,address,uint256)", a, b, c));
    }

    function coinSavingsAccount_withdrawAll(address a, address b) public {
        proxy.execute(gebProxyActionsCoinSavingsAccount, abi.encodeWithSignature("withdrawAll(address,address)", a, b));
    }
}

contract FakeUser {
    function doTransferCDPOwnership(
        GebCdpManager manager,
        uint cdp,
        address dst
    ) public {
        manager.transferCDPOwnership(cdp, dst);
    }
}

contract GebProxyActionsTest is GebDeployTestBase, ProxyCalls {
    GebCdpManager manager;

    CollateralJoin3 dgdJoin;
    DGD dgd;
    DSValue orclDGD;
    CollateralAuctionHouse dgdCollateralAuctionHouse;
    CollateralJoin4 gntCollateralAuctionHouse;
    GNT gnt;
    DSValue orclGNT;
    ProxyRegistry registry;

    function setUp() override public {
        super.setUp();
        deployStableKeepAuth();

        // Add a token collateral
        dgd = new DGD(1000 * 10 ** 9);
        dgdJoin = new CollateralJoin3(address(cdpEngine), "DGD", address(dgd), 9);
        orclDGD = new DSValue();
        gebDeploy.deployCollateral("DGD", address(dgdJoin), address(orclDGD), 1);
        (dgdCollateralAuctionHouse, ) = gebDeploy.collateralTypes("DGD");
        orclDGD.updateResult(bytes32(uint(50 ether))); // Price 50 COIN = 1 DGD (in precision 18)
        this.modifyParameters(address(oracleRelayer), "DGD", "liquidationCRatio", uint(1500000000 ether)); // Liquidation ratio 150%
        this.modifyParameters(address(oracleRelayer), "DGD", "safetyCRatio", uint(1500000000 ether)); // Safety ratio 150%
        this.modifyParameters(address(cdpEngine), bytes32("DGD"), bytes32("debtCeiling"), uint(10000 * 10 ** 45));
        oracleRelayer.updateCollateralPrice("DGD");
        (,,uint safetyPrice,,,) = cdpEngine.collateralTypes("DGD");
        assertEq(safetyPrice, 50 * ONE * ONE / 1500000000 ether);

        gnt = new GNT(1000000 ether);
        gntCollateralAuctionHouse = new CollateralJoin4(address(cdpEngine), "GNT", address(gnt));
        orclGNT = new DSValue();
        gebDeploy.deployCollateral("GNT", address(gntCollateralAuctionHouse), address(orclGNT), 0);
        orclGNT.updateResult(bytes32(uint(100 ether))); // Price 100 COIN = 1 GNT
        this.modifyParameters(address(oracleRelayer), "GNT", "liquidationCRatio", uint(1500000000 ether)); // Liquidation ratio 150%
        this.modifyParameters(address(oracleRelayer), "GNT", "safetyCRatio", uint(1500000000 ether)); // Safety ratio 150%
        this.modifyParameters(address(cdpEngine), bytes32("GNT"), bytes32("debtCeiling"), uint(10000 * 10 ** 45));
        oracleRelayer.updateCollateralPrice("GNT");
        (,, safetyPrice,,,) = cdpEngine.collateralTypes("GNT");
        assertEq(safetyPrice, 100 * ONE * ONE / 1500000000 ether);

        manager = new GebCdpManager(address(cdpEngine));
        DSProxyFactory factory = new DSProxyFactory();
        registry = new ProxyRegistry(address(factory));
        gebProxyActions = address(new GebProxyActions());
        gebProxyActionsGlobalSettlement = address(new GebProxyActionsGlobalSettlement());
        gebProxyActionsCoinSavingsAccount = address(new GebProxyActionsCoinSavingsAccount());
        proxy = DSProxy(registry.build());
    }

    function lockedCollateral(bytes32 collateralType, address urn) public view returns (uint lktCollateral) {
        (lktCollateral,) = cdpEngine.cdps(collateralType, urn);
    }

    function generatedDebt(bytes32 collateralType, address urn) public view returns (uint genDebt) {
        (,genDebt) = cdpEngine.cdps(collateralType, urn);
    }

    function testTransfer() public {
        col.mint(10);
        col.transfer(address(proxy), 10);
        assertEq(col.balanceOf(address(proxy)), 10);
        assertEq(col.balanceOf(address(123)), 0);
        this.transfer(address(col), address(123), 4);
        assertEq(col.balanceOf(address(proxy)), 6);
        assertEq(col.balanceOf(address(123)), 4);
    }

    function testCreateCDP() public {
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        assertEq(cdp, 1);
        assertEq(manager.ownsCDP(cdp), address(proxy));
    }

    function testTransferCDPOwnership() public {
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        this.transferCDPOwnership(address(manager), cdp, address(123));
        assertEq(manager.ownsCDP(cdp), address(123));
    }

    function testGiveCDPToProxy() public {
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        address userProxy = registry.build(address(123));
        this.giveToProxy(address(registry), address(manager), cdp, address(123));
        assertEq(manager.ownsCDP(cdp), userProxy);
    }

    function testGiveCDPToNewProxy() public {
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        assertEq(address(registry.proxies(address(123))), address(0));
        this.giveToProxy(address(registry), address(manager), cdp, address(123));
        DSProxy userProxy = registry.proxies(address(123));
        assertTrue(address(userProxy) != address(0));
        assertEq(userProxy.owner(), address(123));
        assertEq(manager.ownsCDP(cdp), address(userProxy));
    }

    function testFailGiveCDPToNewContractProxy() public {
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        FakeUser user = new FakeUser();
        assertEq(address(registry.proxies(address(user))), address(0));
        this.giveToProxy(address(registry), address(manager), cdp, address(user)); // Fails as user is a contract and not a regular address
    }

    function testGiveCDPAllowedUser() public {
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        FakeUser user = new FakeUser();
        this.allowCDP(address(manager), cdp, address(user), 1);
        user.doTransferCDPOwnership(manager, cdp, address(123));
        assertEq(manager.ownsCDP(cdp), address(123));
    }

    function testAllowUrn() public {
        assertEq(manager.handlerCan(address(proxy), address(123)), 0);
        this.allowHandler(address(manager), address(123), 1);
        assertEq(manager.handlerCan(address(proxy), address(123)), 1);
        this.allowHandler(address(manager), address(123), 0);
        assertEq(manager.handlerCan(address(proxy), address(123)), 0);
    }

    function testTransferCollateral() public {
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));

        assertEq(coin.balanceOf(address(this)), 0);
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(manager.cdps(cdp), 1 ether);
        assertEq(cdpEngine.tokenCollateral("ETH", address(this)), 0);
        assertEq(cdpEngine.tokenCollateral("ETH", manager.cdps(cdp)), 1 ether);

        this.transferCollateral(address(manager), cdp, address(this), 0.75 ether);

        assertEq(cdpEngine.tokenCollateral("ETH", address(this)), 0.75 ether);
        assertEq(cdpEngine.tokenCollateral("ETH", manager.cdps(cdp)), 0.25 ether);
    }

    function testModifyCDPCollateralization() public {
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));

        assertEq(coin.balanceOf(address(this)), 0);
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(manager.cdps(cdp), 1 ether);

        this.modifyCDPCollateralization(address(manager), cdp, 0.5 ether, 60 ether);
        assertEq(cdpEngine.tokenCollateral("ETH", manager.cdps(cdp)), 0.5 ether);
        assertEq(cdpEngine.coinBalance(manager.cdps(cdp)), mul(ONE, 60 ether));
        assertEq(cdpEngine.coinBalance(address(this)), 0);

        this.transferInternalCoins(address(manager), cdp, address(this), mul(ONE, 60 ether));
        assertEq(cdpEngine.coinBalance(manager.cdps(cdp)), 0);
        assertEq(cdpEngine.coinBalance(address(this)), mul(ONE, 60 ether));

        cdpEngine.approveCDPModification(address(coinJoin));
        coinJoin.exit(address(this), 60 ether);
        assertEq(coin.balanceOf(address(this)), 60 ether);
    }

    function testLockETH() public {
        uint initialBalance = address(this).balance;
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        assertEq(lockedCollateral("ETH", manager.cdps(cdp)), 0);
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), cdp);
        assertEq(lockedCollateral("ETH", manager.cdps(cdp)), 2 ether);
        assertEq(address(this).balance, initialBalance - 2 ether);
    }

    function testSafeLockETH() public {
        uint initialBalance = address(this).balance;
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        assertEq(lockedCollateral("ETH", manager.cdps(cdp)), 0);
        this.safeLockETH{value: 2 ether}(address(manager), address(ethJoin), cdp, address(proxy));
        assertEq(lockedCollateral("ETH", manager.cdps(cdp)), 2 ether);
        assertEq(address(this).balance, initialBalance - 2 ether);
    }

    function testLockETHOtherCDPOwner() public {
        uint initialBalance = address(this).balance;
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        this.transferCDPOwnership(address(manager), cdp, address(123));
        assertEq(lockedCollateral("ETH", manager.cdps(cdp)), 0);
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), cdp);
        assertEq(lockedCollateral("ETH", manager.cdps(cdp)), 2 ether);
        assertEq(address(this).balance, initialBalance - 2 ether);
    }

    function testFailSafeLockETHOtherCDPOwner() public {
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        this.transferCDPOwnership(address(manager), cdp, address(123));
        this.safeLockETH{value: 2 ether}(address(manager), address(ethJoin), cdp, address(321));
    }

    function testLockTokenCollateral() public {
        col.mint(5 ether);
        uint cdp = this.openCDP(address(manager), "COL", address(proxy));
        col.approve(address(proxy), 2 ether);
        assertEq(lockedCollateral("COL", manager.cdps(cdp)), 0);
        this.lockTokenCollateral(address(manager), address(colJoin), cdp, 2 ether, true);
        assertEq(lockedCollateral("COL", manager.cdps(cdp)), 2 ether);
        assertEq(col.balanceOf(address(this)), 3 ether);
    }

    function testSafeLockTokenCollateral() public {
        col.mint(5 ether);
        uint cdp = this.openCDP(address(manager), "COL", address(proxy));
        col.approve(address(proxy), 2 ether);
        assertEq(lockedCollateral("COL", manager.cdps(cdp)), 0);
        this.safeLockTokenCollateral(address(manager), address(colJoin), cdp, 2 ether, true, address(proxy));
        assertEq(lockedCollateral("COL", manager.cdps(cdp)), 2 ether);
        assertEq(col.balanceOf(address(this)), 3 ether);
    }

    function testLockTokenCollateralDGD() public {
        uint cdp = this.openCDP(address(manager), "DGD", address(proxy));
        dgd.approve(address(proxy), 2 * 10 ** 9);
        assertEq(lockedCollateral("DGD", manager.cdps(cdp)), 0);
        uint prevBalance = dgd.balanceOf(address(this));
        this.lockTokenCollateral(address(manager), address(dgdJoin), cdp, 2 * 10 ** 9, true);
        assertEq(lockedCollateral("DGD", manager.cdps(cdp)),  2 ether);
        assertEq(dgd.balanceOf(address(this)), prevBalance - 2 * 10 ** 9);
    }

    function testLockTokenCollateralGNT() public {
        uint cdp = this.openCDP(address(manager), "GNT", address(proxy));
        assertEq(lockedCollateral("GNT", manager.cdps(cdp)), 0);
        uint prevBalance = gnt.balanceOf(address(this));
        address bag = this.makeCollateralBag(address(gntCollateralAuctionHouse));
        assertEq(gnt.balanceOf(bag), 0);
        gnt.transfer(bag, 2 ether);
        assertEq(gnt.balanceOf(address(this)), prevBalance - 2 ether);
        assertEq(gnt.balanceOf(bag), 2 ether);
        this.lockTokenCollateral(address(manager), address(gntCollateralAuctionHouse), cdp, 2 ether, false);
        assertEq(lockedCollateral("GNT", manager.cdps(cdp)),  2 ether);
        assertEq(gnt.balanceOf(bag), 0);
    }

    function testLockTokenCollateralOtherCDPOwner() public {
        col.mint(5 ether);
        uint cdp = this.openCDP(address(manager), "COL", address(proxy));
        this.transferCDPOwnership(address(manager), cdp, address(123));
        col.approve(address(proxy), 2 ether);
        assertEq(lockedCollateral("COL", manager.cdps(cdp)), 0);
        this.lockTokenCollateral(address(manager), address(colJoin), cdp, 2 ether, true);
        assertEq(lockedCollateral("COL", manager.cdps(cdp)), 2 ether);
        assertEq(col.balanceOf(address(this)), 3 ether);
    }

    function testFailSafeLockTokenCollateralOtherCDPOwner() public {
        col.mint(5 ether);
        uint cdp = this.openCDP(address(manager), "COL", address(proxy));
        this.transferCDPOwnership(address(manager), cdp, address(123));
        col.approve(address(proxy), 2 ether);
        this.safeLockTokenCollateral(address(manager), address(colJoin), cdp, 2 ether, true, address(321));
    }

    function testFreeETH() public {
        uint initialBalance = address(this).balance;
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), cdp);
        this.freeETH(address(manager), address(ethJoin), cdp, 1 ether);
        assertEq(lockedCollateral("ETH", manager.cdps(cdp)), 1 ether);
        assertEq(address(this).balance, initialBalance - 1 ether);
    }

    function testFreeTokenCollateral() public {
        col.mint(5 ether);
        uint cdp = this.openCDP(address(manager), "COL", address(proxy));
        col.approve(address(proxy), 2 ether);
        this.lockTokenCollateral(address(manager), address(colJoin), cdp, 2 ether, true);
        this.freeTokenCollateral(address(manager), address(colJoin), cdp, 1 ether);
        assertEq(lockedCollateral("COL", manager.cdps(cdp)), 1 ether);
        assertEq(col.balanceOf(address(this)), 4 ether);
    }

    function testFreeTokenCollateralDGD() public {
        uint cdp = this.openCDP(address(manager), "DGD", address(proxy));
        dgd.approve(address(proxy), 2 * 10 ** 9);
        assertEq(lockedCollateral("DGD", manager.cdps(cdp)), 0);
        uint prevBalance = dgd.balanceOf(address(this));
        this.lockTokenCollateral(address(manager), address(dgdJoin), cdp, 2 * 10 ** 9, true);
        this.freeTokenCollateral(address(manager), address(dgdJoin), cdp, 1 * 10 ** 9);
        assertEq(lockedCollateral("DGD", manager.cdps(cdp)),  1 ether);
        assertEq(dgd.balanceOf(address(this)), prevBalance - 1 * 10 ** 9);
    }

    function testFreeTokenCollateralGNT() public {
        uint cdp = this.openCDP(address(manager), "GNT", address(proxy));
        assertEq(lockedCollateral("GNT", manager.cdps(cdp)), 0);
        uint prevBalance = gnt.balanceOf(address(this));
        address bag = this.makeCollateralBag(address(gntCollateralAuctionHouse));
        gnt.transfer(bag, 2 ether);
        this.lockTokenCollateral(address(manager), address(gntCollateralAuctionHouse), cdp, 2 ether, false);
        this.freeTokenCollateral(address(manager), address(gntCollateralAuctionHouse), cdp, 1 ether);
        assertEq(lockedCollateral("GNT", manager.cdps(cdp)),  1 ether);
        assertEq(gnt.balanceOf(address(this)), prevBalance - 1 ether);
    }

    function testGenerateDebt() public {
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), cdp);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), cdp, 300 ether);
        assertEq(coin.balanceOf(address(this)), 300 ether);
        assertEq(generatedDebt("ETH", manager.cdps(cdp)), 300 ether);
    }

    function testGenerateDebtAfterCollectingTax() public {
        this.modifyParameters(address(taxCollector), bytes32("ETH"), bytes32("stabilityFee"), uint(1.05 * 10 ** 27));
        hevm.warp(now + 1);
        taxCollector.taxSingle("ETH"); // This is actually not necessary as `generateDebt` will also call taxSingle
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), cdp);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), cdp, 300 ether);
        assertEq(coin.balanceOf(address(this)), 300 ether);
        assertEq(generatedDebt("ETH", manager.cdps(cdp)), mul(300 ether, ONE) / (1.05 * 10 ** 27) + 1); // Extra wei due rounding
    }

    function testRepayDebt() public {
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), cdp);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), cdp, 300 ether);
        coin.approve(address(proxy), 100 ether);
        this.repayDebt(address(manager), address(coinJoin), cdp, 100 ether);
        assertEq(coin.balanceOf(address(this)), 200 ether);
        assertEq(generatedDebt("ETH", manager.cdps(cdp)), 200 ether);
    }

    function testRepayDebtAll() public {
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), cdp);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), cdp, 300 ether);
        coin.approve(address(proxy), 300 ether);
        this.repayAllDebt(address(manager), address(coinJoin), cdp);
        assertEq(coin.balanceOf(address(this)), 0);
        assertEq(generatedDebt("ETH", manager.cdps(cdp)), 0);
    }

    function testSafeRepayDebt() public {
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), cdp);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), cdp, 300 ether);
        coin.approve(address(proxy), 100 ether);
        this.safeRepayDebt(address(manager), address(coinJoin), cdp, 100 ether, address(proxy));
        assertEq(coin.balanceOf(address(this)), 200 ether);
        assertEq(generatedDebt("ETH", manager.cdps(cdp)), 200 ether);
    }

    function testSafeRepayAllDebt() public {
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), cdp);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), cdp, 300 ether);
        coin.approve(address(proxy), 300 ether);
        this.safeRepayAllDebt(address(manager), address(coinJoin), cdp, address(proxy));
        assertEq(coin.balanceOf(address(this)), 0);
        assertEq(generatedDebt("ETH", manager.cdps(cdp)), 0);
    }

    function testRepayDebtOtherCDPOwner() public {
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), cdp);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), cdp, 300 ether);
        coin.approve(address(proxy), 100 ether);
        this.transferCDPOwnership(address(manager), cdp, address(123));
        this.repayDebt(address(manager), address(coinJoin), cdp, 100 ether);
        assertEq(coin.balanceOf(address(this)), 200 ether);
        assertEq(generatedDebt("ETH", manager.cdps(cdp)), 200 ether);
    }

    function testFailSafeRepayDebtOtherCDPOwner() public {
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), cdp);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), cdp, 300 ether);
        coin.approve(address(proxy), 100 ether);
        this.transferCDPOwnership(address(manager), cdp, address(123));
        this.safeRepayDebt(address(manager), address(coinJoin), cdp, 100 ether, address(321));
    }

    function testFailSafeRepayDebtAllOtherCDPOwner() public {
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), cdp);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), cdp, 300 ether);
        coin.approve(address(proxy), 300 ether);
        this.transferCDPOwnership(address(manager), cdp, address(123));
        this.safeRepayAllDebt(address(manager), address(coinJoin), cdp, address(321));
    }

    function testRepayDebtAfterTaxation() public {
        this.modifyParameters(address(taxCollector), bytes32("ETH"), bytes32("stabilityFee"), uint(1.05 * 10 ** 27));
        hevm.warp(now + 1);
        taxCollector.taxSingle("ETH");
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), cdp);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), cdp, 300 ether);
        coin.approve(address(proxy), 100 ether);
        this.repayDebt(address(manager), address(coinJoin), cdp, 100 ether);
        assertEq(coin.balanceOf(address(this)), 200 ether);
        assertEq(generatedDebt("ETH", manager.cdps(cdp)), mul(200 ether, ONE) / (1.05 * 10 ** 27) + 1);
    }

    function testRepayAllDebtAfterTaxation() public {
        taxCollector.taxSingle("ETH");
        this.modifyParameters(address(taxCollector), bytes32("ETH"), bytes32("stabilityFee"), uint(1.05 * 10 ** 27));
        hevm.warp(now + 1);
        taxCollector.taxSingle("ETH");
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), cdp);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), cdp, 300 ether);
        coin.approve(address(proxy), 300 ether);
        this.repayDebt(address(manager), address(coinJoin), cdp, 300 ether);
        assertEq(generatedDebt("ETH", manager.cdps(cdp)), 0);
    }

    function testRepayAllDebtAfterTaxation2() public {
        taxCollector.taxSingle("ETH");
        this.modifyParameters(address(taxCollector), bytes32("ETH"), bytes32("stabilityFee"), uint(1.05 * 10 ** 27));
        hevm.warp(now + 1);
        taxCollector.taxSingle("ETH"); // This is actually not necessary as `draw` will also call taxSingle
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        uint times = 30;
        this.lockETH{value: 2 ether * times}(address(manager), address(ethJoin), cdp);
        for (uint i = 0; i < times; i++) {
            this.generateDebt(address(manager), address(taxCollector), address(coinJoin), cdp, 300 ether);
        }
        coin.approve(address(proxy), 300 ether * times);
        this.repayDebt(address(manager), address(coinJoin), cdp, 300 ether * times);
        assertEq(generatedDebt("ETH", manager.cdps(cdp)), 0);
    }

    function testLockETHAndGenerateDebt() public {
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        uint initialBalance = address(this).balance;
        assertEq(lockedCollateral("ETH", manager.cdps(cdp)), 0);
        assertEq(coin.balanceOf(address(this)), 0);
        this.lockETHAndGenerateDebt{value: 2 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), cdp, 300 ether);
        assertEq(lockedCollateral("ETH", manager.cdps(cdp)), 2 ether);
        assertEq(coin.balanceOf(address(this)), 300 ether);
        assertEq(address(this).balance, initialBalance - 2 ether);
    }

    function testOpenLockETHAndGenerateDebt() public {
        uint initialBalance = address(this).balance;
        assertEq(coin.balanceOf(address(this)), 0);
        uint cdp = this.openLockETHAndGenerateDebt{value: 2 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), "ETH", 300 ether);
        assertEq(lockedCollateral("ETH", manager.cdps(cdp)), 2 ether);
        assertEq(coin.balanceOf(address(this)), 300 ether);
        assertEq(address(this).balance, initialBalance - 2 ether);
    }

    function testLockTokenCollateralAndGenerateDebt() public {
        col.mint(5 ether);
        uint cdp = this.openCDP(address(manager), "COL", address(proxy));
        col.approve(address(proxy), 2 ether);
        assertEq(lockedCollateral("COL", manager.cdps(cdp)), 0);
        assertEq(coin.balanceOf(address(this)), 0);
        this.lockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(colJoin), address(coinJoin), cdp, 2 ether, 10 ether, true);
        assertEq(lockedCollateral("COL", manager.cdps(cdp)), 2 ether);
        assertEq(coin.balanceOf(address(this)), 10 ether);
        assertEq(col.balanceOf(address(this)), 3 ether);
    }

    function testLockTokenCollateralDGDAndGenerateDebt() public {
        uint cdp = this.openCDP(address(manager), "DGD", address(proxy));
        dgd.approve(address(proxy), 3 * 10 ** 9);
        assertEq(lockedCollateral("DGD", manager.cdps(cdp)), 0);
        uint prevBalance = dgd.balanceOf(address(this));
        this.lockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(dgdJoin), address(coinJoin), cdp, 3 * 10 ** 9, 50 ether, true);
        assertEq(lockedCollateral("DGD", manager.cdps(cdp)), 3 ether);
        assertEq(coin.balanceOf(address(this)), 50 ether);
        assertEq(dgd.balanceOf(address(this)), prevBalance - 3 * 10 ** 9);
    }

    function testLockTokenCollateralGNTAndGenerateDebt() public {
        uint cdp = this.openCDP(address(manager), "GNT", address(proxy));
        assertEq(lockedCollateral("GNT", manager.cdps(cdp)), 0);
        uint prevBalance = gnt.balanceOf(address(this));
        address bag = this.makeCollateralBag(address(gntCollateralAuctionHouse));
        gnt.transfer(bag, 3 ether);
        this.lockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(gntCollateralAuctionHouse), address(coinJoin), cdp, 3 ether, 50 ether, false);
        assertEq(lockedCollateral("GNT", manager.cdps(cdp)), 3 ether);
        assertEq(coin.balanceOf(address(this)), 50 ether);
        assertEq(gnt.balanceOf(address(this)), prevBalance - 3 ether);
    }

    function testOpenLockTokenCollateralAndGenerateDebt() public {
        col.mint(5 ether);
        col.approve(address(proxy), 2 ether);
        assertEq(coin.balanceOf(address(this)), 0);
        uint cdp = this.openLockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(colJoin), address(coinJoin), "COL", 2 ether, 10 ether, true);
        assertEq(lockedCollateral("COL", manager.cdps(cdp)), 2 ether);
        assertEq(coin.balanceOf(address(this)), 10 ether);
        assertEq(col.balanceOf(address(this)), 3 ether);
    }

    function testOpenLockTokenCollateralGNTAndGenerateDebt() public {
        assertEq(coin.balanceOf(address(this)), 0);
        address bag = this.makeCollateralBag(address(gntCollateralAuctionHouse));
        assertEq(address(bag), gntCollateralAuctionHouse.bags(address(proxy)));
        gnt.transfer(bag, 2 ether);
        uint cdp = this.openLockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(gntCollateralAuctionHouse), address(coinJoin), "GNT", 2 ether, 10 ether, false);
        assertEq(lockedCollateral("GNT", manager.cdps(cdp)), 2 ether);
        assertEq(coin.balanceOf(address(this)), 10 ether);
    }

    function testOpenLockTokenCollateralGNTAndGenerateDebtSafe() public {
        assertEq(coin.balanceOf(address(this)), 0);
        gnt.transfer(address(proxy), 2 ether);
        (address bag, uint cdp) = this.openLockGNTAndGenerateDebt(address(manager), address(taxCollector), address(gntCollateralAuctionHouse), address(coinJoin), "GNT", 2 ether, 10 ether);
        assertEq(address(bag), gntCollateralAuctionHouse.bags(address(proxy)));
        assertEq(lockedCollateral("GNT", manager.cdps(cdp)), 2 ether);
        assertEq(coin.balanceOf(address(this)), 10 ether);
    }

    function testOpenLockTokenCollateralGNTAndGenerateDebtSafeTwice() public {
        assertEq(coin.balanceOf(address(this)), 0);
        gnt.transfer(address(proxy), 4 ether);
        (address bag, uint cdp) = this.openLockGNTAndGenerateDebt(address(manager), address(taxCollector), address(gntCollateralAuctionHouse), address(coinJoin), "GNT", 2 ether, 10 ether);
        (address bag2, uint cdp2) = this.openLockGNTAndGenerateDebt(address(manager), address(taxCollector), address(gntCollateralAuctionHouse), address(coinJoin), "GNT", 2 ether, 10 ether);
        assertEq(address(bag), gntCollateralAuctionHouse.bags(address(proxy)));
        assertEq(address(bag), address(bag2));
        assertEq(lockedCollateral("GNT", manager.cdps(cdp)), 2 ether);
        assertEq(lockedCollateral("GNT", manager.cdps(cdp2)), 2 ether);
        assertEq(coin.balanceOf(address(this)), 20 ether);
    }

    function testRepayDebtAndFreeETH() public {
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        uint initialBalance = address(this).balance;
        this.lockETHAndGenerateDebt{value: 2 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), cdp, 300 ether);
        coin.approve(address(proxy), 250 ether);
        this.repayDebtAndFreeETH(address(manager), address(ethJoin), address(coinJoin), cdp, 1.5 ether, 250 ether);
        assertEq(lockedCollateral("ETH", manager.cdps(cdp)), 0.5 ether);
        assertEq(generatedDebt("ETH", manager.cdps(cdp)), 50 ether);
        assertEq(coin.balanceOf(address(this)), 50 ether);
        assertEq(address(this).balance, initialBalance - 0.5 ether);
    }

    function testRepayAllDebtAndFreeETH() public {
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        uint initialBalance = address(this).balance;
        this.lockETHAndGenerateDebt{value: 2 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), cdp, 300 ether);
        coin.approve(address(proxy), 300 ether);
        this.repayAllDebtAndFreeETH(address(manager), address(ethJoin), address(coinJoin), cdp, 1.5 ether);
        assertEq(lockedCollateral("ETH", manager.cdps(cdp)), 0.5 ether);
        assertEq(generatedDebt("ETH", manager.cdps(cdp)), 0);
        assertEq(coin.balanceOf(address(this)), 0);
        assertEq(address(this).balance, initialBalance - 0.5 ether);
    }

    function testRepayDebtAndFreeTokenCollateral() public {
        col.mint(5 ether);
        uint cdp = this.openCDP(address(manager), "COL", address(proxy));
        col.approve(address(proxy), 2 ether);
        this.lockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(colJoin), address(coinJoin), cdp, 2 ether, 10 ether, true);
        coin.approve(address(proxy), 8 ether);
        this.repayDebtAndFreeTokenCollateral(address(manager), address(colJoin), address(coinJoin), cdp, 1.5 ether, 8 ether);
        assertEq(lockedCollateral("COL", manager.cdps(cdp)), 0.5 ether);
        assertEq(generatedDebt("COL", manager.cdps(cdp)), 2 ether);
        assertEq(coin.balanceOf(address(this)), 2 ether);
        assertEq(col.balanceOf(address(this)), 4.5 ether);
    }

    function testRepayAllDebtAndFreeTokenCollateral() public {
        col.mint(5 ether);
        uint cdp = this.openCDP(address(manager), "COL", address(proxy));
        col.approve(address(proxy), 2 ether);
        this.lockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(colJoin), address(coinJoin), cdp, 2 ether, 10 ether, true);
        coin.approve(address(proxy), 10 ether);
        this.repayAllDebtAndFreeTokenCollateral(address(manager), address(colJoin), address(coinJoin), cdp, 1.5 ether);
        assertEq(lockedCollateral("COL", manager.cdps(cdp)), 0.5 ether);
        assertEq(generatedDebt("COL", manager.cdps(cdp)), 0);
        assertEq(coin.balanceOf(address(this)), 0);
        assertEq(col.balanceOf(address(this)), 4.5 ether);
    }

    function testWipeAndFreeTokenCollateralDGDAndGenerateDebt() public {
        uint cdp = this.openCDP(address(manager), "DGD", address(proxy));
        dgd.approve(address(proxy), 3 * 10 ** 9);
        assertEq(lockedCollateral("DGD", manager.cdps(cdp)), 0);
        uint prevBalance = dgd.balanceOf(address(this));
        this.lockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(dgdJoin), address(coinJoin), cdp, 3 * 10 ** 9, 50 ether, true);
        coin.approve(address(proxy), 25 ether);
        this.repayDebtAndFreeTokenCollateral(address(manager), address(dgdJoin), address(coinJoin), cdp, 1 * 10 ** 9, 25 ether);
        assertEq(lockedCollateral("DGD", manager.cdps(cdp)), 2 ether);
        assertEq(coin.balanceOf(address(this)), 25 ether);
        assertEq(dgd.balanceOf(address(this)), prevBalance - 2 * 10 ** 9);
    }

    function testPreventHigherCoinOnRepayDebt() public {
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        this.lockETHAndGenerateDebt{value: 2 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), cdp, 300 ether);

        weth.deposit{value: 2 ether}();
        weth.approve(address(ethJoin), 2 ether);
        ethJoin.join(address(this), 2 ether);
        cdpEngine.modifyCDPCollateralization("ETH", address(this), address(this), address(this), 1 ether, 150 ether);
        cdpEngine.transferInternalCoins(address(this), manager.cdps(cdp), 150 ether);

        coin.approve(address(proxy), 300 ether);
        this.repayDebt(address(manager), address(coinJoin), cdp, 300 ether);
    }

    function testApproveDenyCDPModification() public {
        assertEq(cdpEngine.cdpRights(address(proxy), address(123)), 0);
        this.approveCDPModification(address(cdpEngine), address(123));
        assertEq(cdpEngine.cdpRights(address(proxy), address(123)), 1);
        this.denyCDPModification(address(cdpEngine), address(123));
        assertEq(cdpEngine.cdpRights(address(proxy), address(123)), 0);
    }

    function testQuitSystem() public {
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        this.lockETHAndGenerateDebt{value: 1 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), cdp, 50 ether);

        assertEq(lockedCollateral("ETH", manager.cdps(cdp)), 1 ether);
        assertEq(generatedDebt("ETH", manager.cdps(cdp)), 50 ether);
        assertEq(lockedCollateral("ETH", address(proxy)), 0);
        assertEq(generatedDebt("ETH", address(proxy)), 0);

        this.approveCDPModification(address(cdpEngine), address(manager));
        this.quitSystem(address(manager), cdp, address(proxy));

        assertEq(lockedCollateral("ETH", manager.cdps(cdp)), 0);
        assertEq(generatedDebt("ETH", manager.cdps(cdp)), 0);
        assertEq(lockedCollateral("ETH", address(proxy)), 1 ether);
        assertEq(generatedDebt("ETH", address(proxy)), 50 ether);
    }

    function testEnterSystem() public {
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), 1 ether);
        ethJoin.join(address(this), 1 ether);
        cdpEngine.modifyCDPCollateralization("ETH", address(this), address(this), address(this), 1 ether, 50 ether);
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));

        assertEq(lockedCollateral("ETH", manager.cdps(cdp)), 0);
        assertEq(generatedDebt("ETH", manager.cdps(cdp)), 0);
        assertEq(lockedCollateral("ETH", address(this)), 1 ether);
        assertEq(generatedDebt("ETH", address(this)), 50 ether);

        cdpEngine.approveCDPModification(address(manager));
        manager.allowHandler(address(proxy), 1);
        this.enterSystem(address(manager), address(this), cdp);

        assertEq(lockedCollateral("ETH", manager.cdps(cdp)), 1 ether);
        assertEq(generatedDebt("ETH", manager.cdps(cdp)), 50 ether);
        assertEq(lockedCollateral("ETH", address(this)), 0);
        assertEq(generatedDebt("ETH", address(this)), 0);
    }

    function testMoveCDP() public {
        uint cdpSrc = this.openCDP(address(manager), "ETH", address(proxy));
        this.lockETHAndGenerateDebt{value: 1 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), cdpSrc, 50 ether);

        uint cdpDst = this.openCDP(address(manager), "ETH", address(proxy));

        assertEq(lockedCollateral("ETH", manager.cdps(cdpSrc)), 1 ether);
        assertEq(generatedDebt("ETH", manager.cdps(cdpSrc)), 50 ether);
        assertEq(lockedCollateral("ETH", manager.cdps(cdpDst)), 0);
        assertEq(generatedDebt("ETH", manager.cdps(cdpDst)), 0);

        this.moveCDP(address(manager), cdpSrc, cdpDst);

        assertEq(lockedCollateral("ETH", manager.cdps(cdpSrc)), 0);
        assertEq(generatedDebt("ETH", manager.cdps(cdpSrc)), 0);
        assertEq(lockedCollateral("ETH", manager.cdps(cdpDst)), 1 ether);
        assertEq(generatedDebt("ETH", manager.cdps(cdpDst)), 50 ether);
    }

    function _collateralAuctionETH() internal returns (uint cdp) {
        this.modifyParameters(address(liquidationEngine), "ETH", "collateralToSell", 1 ether); // 1 unit of collateral per batch
        this.modifyParameters(address(liquidationEngine), "ETH", "liquidationPenalty", ONE);

        cdp = this.openCDP(address(manager), "ETH", address(proxy));
        this.lockETHAndGenerateDebt{value: 1 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), cdp, 200 ether); // Maximun COIN generated
        orclETH.updateResult(bytes32(uint(300 * 10 ** 18 - 1))); // Force liquidation
        oracleRelayer.updateCollateralPrice("ETH");
        uint batchId = liquidationEngine.liquidateCDP("ETH", manager.cdps(cdp));

        address(user1).transfer(10 ether);
        user1.doEthJoin(address(weth), address(ethJoin), address(user1), 10 ether);
        user1.doModifyCDPCollateralization(address(cdpEngine), "ETH", address(user1), address(user1), address(user1), 10 ether, 1000 ether);

        address(user2).transfer(10 ether);
        user2.doEthJoin(address(weth), address(ethJoin), address(user2), 10 ether);
        user2.doModifyCDPCollateralization(address(cdpEngine), "ETH", address(user2), address(user2), address(user2), 10 ether, 1000 ether);

        user1.doCDPApprove(address(cdpEngine), address(ethCollateralAuctionHouse));
        user2.doCDPApprove(address(cdpEngine), address(ethCollateralAuctionHouse));

        user1.doIncreaseBidSize(address(ethCollateralAuctionHouse), batchId, 1 ether, rad(200 ether));
        user2.doDecreaseSoldAmount(address(ethCollateralAuctionHouse), batchId, 0.7 ether, rad(200 ether));
    }

    function testExitETHAfterCollateralAuction() public {
        uint cdp = _collateralAuctionETH();
        assertEq(cdpEngine.tokenCollateral("ETH", manager.cdps(cdp)), 0.3 ether);
        uint prevBalance = address(this).balance;
        this.exitETH(address(manager), address(ethJoin), cdp, 0.3 ether);
        assertEq(cdpEngine.tokenCollateral("ETH", manager.cdps(cdp)), 0);
        assertEq(address(this).balance, prevBalance + 0.3 ether);
    }

    function testExitTokenCollateralAfterAuction() public {
        this.modifyParameters(address(liquidationEngine), "COL", "collateralToSell", 1 ether); // 1 unit of collateral per batch
        this.modifyParameters(address(liquidationEngine), "COL", "liquidationPenalty", ONE);

        col.mint(1 ether);
        uint cdp = this.openCDP(address(manager), "COL", address(proxy));
        col.approve(address(proxy), 1 ether);
        this.lockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(colJoin), address(coinJoin), cdp, 1 ether, 40 ether, true);

        orclCOL.updateResult(bytes32(uint(40 * 10 ** 18))); // Force liquidation
        oracleRelayer.updateCollateralPrice("COL");
        uint batchId = liquidationEngine.liquidateCDP("COL", manager.cdps(cdp));

        address(user1).transfer(10 ether);
        user1.doEthJoin(address(weth), address(ethJoin), address(user1), 10 ether);
        user1.doModifyCDPCollateralization(address(cdpEngine), "ETH", address(user1), address(user1), address(user1), 10 ether, 1000 ether);

        address(user2).transfer(10 ether);
        user2.doEthJoin(address(weth), address(ethJoin), address(user2), 10 ether);
        user2.doModifyCDPCollateralization(address(cdpEngine), "ETH", address(user2), address(user2), address(user2), 10 ether, 1000 ether);

        user1.doCDPApprove(address(cdpEngine), address(colAuctionHouse));
        user2.doCDPApprove(address(cdpEngine), address(colAuctionHouse));

        user1.doIncreaseBidSize(address(colAuctionHouse), batchId, 1 ether, rad(40 ether));

        user2.doDecreaseSoldAmount(address(colAuctionHouse), batchId, 0.7 ether, rad(40 ether));
        assertEq(cdpEngine.tokenCollateral("COL", manager.cdps(cdp)), 0.3 ether);
        assertEq(col.balanceOf(address(this)), 0);
        this.exitTokenCollateral(address(manager), address(colJoin), cdp, 0.3 ether);
        assertEq(cdpEngine.tokenCollateral("COL", manager.cdps(cdp)), 0);
        assertEq(col.balanceOf(address(this)), 0.3 ether);
    }

    function testExitDGDAfterAuction() public {
        this.modifyParameters(address(liquidationEngine), "DGD", "collateralToSell", 1 ether); // 1 unit of collateral per batch
        this.modifyParameters(address(liquidationEngine), "DGD", "liquidationPenalty", ONE);

        uint cdp = this.openCDP(address(manager), "DGD", address(proxy));
        dgd.approve(address(proxy), 1 * 10 ** 9);
        this.lockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(dgdJoin), address(coinJoin), cdp, 1 * 10 ** 9, 30 ether, true);

        orclDGD.updateResult(bytes32(uint(40 * 10 ** 18))); // Force liquidation
        oracleRelayer.updateCollateralPrice("DGD");
        uint batchId = liquidationEngine.liquidateCDP("DGD", manager.cdps(cdp));

        address(user1).transfer(10 ether);
        user1.doEthJoin(address(weth), address(ethJoin), address(user1), 10 ether);
        user1.doModifyCDPCollateralization(address(cdpEngine), "ETH", address(user1), address(user1), address(user1), 10 ether, 1000 ether);

        address(user2).transfer(10 ether);
        user2.doEthJoin(address(weth), address(ethJoin), address(user2), 10 ether);
        user2.doModifyCDPCollateralization(address(cdpEngine), "ETH", address(user2), address(user2), address(user2), 10 ether, 1000 ether);

        user1.doCDPApprove(address(cdpEngine), address(dgdCollateralAuctionHouse));
        user2.doCDPApprove(address(cdpEngine), address(dgdCollateralAuctionHouse));

        user1.doIncreaseBidSize(address(dgdCollateralAuctionHouse), batchId, 1 ether, rad(30 ether));

        user2.doDecreaseSoldAmount(address(dgdCollateralAuctionHouse), batchId, 0.7 ether, rad(30 ether));
        assertEq(cdpEngine.tokenCollateral("DGD", manager.cdps(cdp)), 0.3 ether);
        uint prevBalance = dgd.balanceOf(address(this));
        this.exitTokenCollateral(address(manager), address(dgdJoin), cdp, 0.3 * 10 ** 9);
        assertEq(cdpEngine.tokenCollateral("DGD", manager.cdps(cdp)), 0);
        assertEq(dgd.balanceOf(address(this)), prevBalance + 0.3 * 10 ** 9);
    }

    function testLockBackAfterCollateralAuction() public {
        uint cdp = _collateralAuctionETH();
        (uint lockedCollateral,) = cdpEngine.cdps("ETH", manager.cdps(cdp));
        assertEq(lockedCollateral, 0);
        assertEq(cdpEngine.tokenCollateral("ETH", manager.cdps(cdp)), 0.3 ether);
        this.modifyCDPCollateralization(address(manager), cdp, 0.3 ether, 0);
        (lockedCollateral,) = cdpEngine.cdps("ETH", manager.cdps(cdp));
        assertEq(lockedCollateral, 0.3 ether);
        assertEq(cdpEngine.tokenCollateral("ETH", manager.cdps(cdp)), 0);
    }

    function testGlobalSettlement() public {
        this.modifyParameters(address(liquidationEngine), "ETH", "collateralToSell", 1 ether); // 1 unit of collateral per batch
        this.modifyParameters(address(liquidationEngine), "ETH", "liquidationPenalty", ONE);

        uint cdp = this.openLockETHAndGenerateDebt{value: 2 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), "ETH", 300 ether);
        col.mint(1 ether);
        col.approve(address(proxy), 1 ether);
        uint cdp2 = this.openLockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(colJoin), address(coinJoin), "COL", 1 ether, 5 ether, true);
        dgd.approve(address(proxy), 1 * 10 ** 9);
        uint cdp3 = this.openLockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(dgdJoin), address(coinJoin), "DGD", 1 * 10 ** 9, 5 ether, true);

        this.shutdownSystem(address(globalSettlement));
        globalSettlement.freezeCollateralType("ETH");
        globalSettlement.freezeCollateralType("COL");
        globalSettlement.freezeCollateralType("DGD");

        (uint lockedCollateral, uint generatedDebt) = cdpEngine.cdps("ETH", manager.cdps(cdp));
        assertEq(lockedCollateral, 2 ether);
        assertEq(generatedDebt, 300 ether);

        (lockedCollateral, generatedDebt) = cdpEngine.cdps("COL", manager.cdps(cdp2));
        assertEq(lockedCollateral, 1 ether);
        assertEq(generatedDebt, 5 ether);

        (lockedCollateral, generatedDebt) = cdpEngine.cdps("DGD", manager.cdps(cdp3));
        assertEq(lockedCollateral, 1 ether);
        assertEq(generatedDebt, 5 ether);

        uint prevBalanceETH = address(this).balance;
        this.globalSettlement_freeETH(address(manager), address(ethJoin), address(globalSettlement), cdp);
        (lockedCollateral, generatedDebt) = cdpEngine.cdps("ETH", manager.cdps(cdp));
        assertEq(lockedCollateral, 0);
        assertEq(generatedDebt, 0);
        uint remainingCollateralValue = 2 ether - 300 * globalSettlement.finalCoinPerCollateralPrice("ETH") / 10 ** 9; // 2 ETH (deposited) - 300 COIN debt * ETH cage price
        assertEq(address(this).balance, prevBalanceETH + remainingCollateralValue);

        uint prevBalanceCol = col.balanceOf(address(this));
        this.globalSettlement_freeTokenCollateral(address(manager), address(colJoin), address(globalSettlement), cdp2);
        (lockedCollateral, generatedDebt) = cdpEngine.cdps("COL", manager.cdps(cdp2));
        assertEq(lockedCollateral, 0);
        assertEq(generatedDebt, 0);
        remainingCollateralValue = 1 ether - 5 * globalSettlement.finalCoinPerCollateralPrice("COL") / 10 ** 9; // 1 COL (deposited) - 5 COIN debt * COL cage price
        assertEq(col.balanceOf(address(this)), prevBalanceCol + remainingCollateralValue);

        uint prevBalanceDGD = dgd.balanceOf(address(this));
        this.globalSettlement_freeTokenCollateral(address(manager), address(dgdJoin), address(globalSettlement), cdp3);
        (lockedCollateral, generatedDebt) = cdpEngine.cdps("DGD", manager.cdps(cdp3));
        assertEq(lockedCollateral, 0);
        assertEq(generatedDebt, 0);
        remainingCollateralValue = (1 ether - 5 * globalSettlement.finalCoinPerCollateralPrice("DGD") / 10 ** 9) / 10 ** 9; // 1 DGD (deposited) - 5 COIN debt * DGD cage price
        assertEq(dgd.balanceOf(address(this)), prevBalanceDGD + remainingCollateralValue);

        globalSettlement.setOutstandingCoinSupply();

        globalSettlement.calculateCashPrice("ETH");
        globalSettlement.calculateCashPrice("COL");
        globalSettlement.calculateCashPrice("DGD");

        coin.approve(address(proxy), 310 ether);
        this.globalSettlement_prepareCoinsForRedeeming(address(coinJoin), address(globalSettlement), 310 ether);

        this.globalSettlement_redeemETH(address(ethJoin), address(globalSettlement), "ETH", 310 ether);
        this.globalSettlement_redeemTokenCollateral(address(colJoin), address(globalSettlement), "COL", 310 ether);
        this.globalSettlement_redeemTokenCollateral(address(dgdJoin), address(globalSettlement), "DGD", 310 ether);

        assertEq(address(this).balance, prevBalanceETH + 2 ether - 1); // (-1 rounding)
        assertEq(col.balanceOf(address(this)), prevBalanceCol + 1 ether - 1); // (-1 rounding)
        assertEq(dgd.balanceOf(address(this)), prevBalanceDGD + 1 * 10 ** 9 - 1); // (-1 rounding)
    }

    function testCoinSavingsAccountSimpleCase() public {
        this.modifyParameters(address(coinSavingsAccount), "savingsRate", uint(1.05 * 10 ** 27)); // 5% per second
        uint initialTime = 0; // Initial time set to 0 to avoid any intial rounding
        hevm.warp(initialTime);
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        this.lockETHAndGenerateDebt{value: 1 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), cdp, 50 ether);
        coin.approve(address(proxy), 50 ether);
        assertEq(coin.balanceOf(address(this)), 50 ether);
        assertEq(coinSavingsAccount.savings(address(this)), 0 ether);
        this.denyCDPModification(address(cdpEngine), address(coinJoin)); // Remove cdpEngine permission for coinJoin to test it is correctly re-acticdpEnginee in exit
        this.coinSavingsAccount_deposit(address(coinJoin), address(coinSavingsAccount), 50 ether);
        assertEq(coin.balanceOf(address(this)), 0 ether);
        assertEq(coinSavingsAccount.savings(address(proxy)) * coinSavingsAccount.accumulatedRates(), 50 ether * ONE);
        hevm.warp(initialTime + 1); // Moved 1 second
        coinSavingsAccount.updateAccumulatedRate();
        assertEq(coinSavingsAccount.savings(address(proxy)) * coinSavingsAccount.accumulatedRates(), 52.5 ether * ONE); // Now the equivalent COIN amount is 2.5 COIN extra
        this.coinSavingsAccount_withdraw(address(coinJoin), address(coinSavingsAccount), 52.5 ether);
        assertEq(coin.balanceOf(address(this)), 52.5 ether);
        assertEq(coinSavingsAccount.savings(address(proxy)), 0);
    }

    function testCoinSavingsAccountRounding() public {
        this.modifyParameters(address(coinSavingsAccount), "savingsRate", uint(1.05 * 10 ** 27));
        uint initialTime = 1; // Initial time set to 1 this way some the pie will not be the same than the initial COIN wad amount
        hevm.warp(initialTime);
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        this.lockETHAndGenerateDebt{value: 1 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), cdp, 50 ether);
        coin.approve(address(proxy), 50 ether);
        assertEq(coin.balanceOf(address(this)), 50 ether);
        assertEq(coinSavingsAccount.savings(address(this)), 0 ether);
        this.denyCDPModification(address(cdpEngine), address(coinJoin)); // Remove cdpEngine permission for coinJoin to test it is correctly re-acticdpEnginee in exit
        this.coinSavingsAccount_deposit(address(coinJoin), address(coinSavingsAccount), 50 ether);
        assertEq(coin.balanceOf(address(this)), 0 ether);
        // Due rounding the COIN equivalent is not the same than initial wad amount
        assertEq(coinSavingsAccount.savings(address(proxy)) * coinSavingsAccount.accumulatedRates(), 49999999999999999999350000000000000000000000000);
        hevm.warp(initialTime + 1);
        coinSavingsAccount.updateAccumulatedRate(); // Just necessary to check in this test the updated value of chi
        assertEq(coinSavingsAccount.savings(address(proxy)) * coinSavingsAccount.accumulatedRates(), 52499999999999999999317500000000000000000000000);
        this.coinSavingsAccount_withdraw(address(coinJoin), address(coinSavingsAccount), 52.5 ether);
        assertEq(coin.balanceOf(address(this)), 52499999999999999999);
        assertEq(coinSavingsAccount.savings(address(proxy)), 0);
    }

    function testCoinSavingsAccountRounding2() public {
        this.modifyParameters(address(coinSavingsAccount), "savingsRate", uint(1.03434234324 * 10 ** 27));
        uint initialTime = 1;
        hevm.warp(initialTime);
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        this.lockETHAndGenerateDebt{value: 1 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), cdp, 50 ether);
        coin.approve(address(proxy), 50 ether);
        assertEq(coin.balanceOf(address(this)), 50 ether);
        assertEq(coinSavingsAccount.savings(address(this)), 0 ether);
        this.denyCDPModification(address(cdpEngine), address(coinJoin)); // Remove cdpEngine permission for coinJoin to test it is correctly re-acticdpEnginee in exit
        this.coinSavingsAccount_deposit(address(coinJoin), address(coinSavingsAccount), 50 ether);
        assertEq(coinSavingsAccount.savings(address(proxy)) * coinSavingsAccount.accumulatedRates(), 49999999999999999999993075745400000000000000000);
        assertEq(cdpEngine.coinBalance(address(proxy)), mul(50 ether, ONE) - 49999999999999999999993075745400000000000000000);
        this.coinSavingsAccount_withdraw(address(coinJoin), address(coinSavingsAccount), 50 ether);
        // In this case we get the full 50 COIN back as we also use (for the exit) the dust that remained in the proxy COIN balance in the cdpEngine
        // The proxy function tries to return the wad amount if there is enough balance to do it
        assertEq(coin.balanceOf(address(this)), 50 ether);
    }

    function testCoinSavingsAccountWithdrawAll() public {
        this.modifyParameters(address(coinSavingsAccount), "savingsRate", uint(1.03434234324 * 10 ** 27));
        uint initialTime = 1;
        hevm.warp(initialTime);
        uint cdp = this.openCDP(address(manager), "ETH", address(proxy));
        this.lockETHAndGenerateDebt{value: 1 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), cdp, 50 ether);
        this.denyCDPModification(address(cdpEngine), address(coinJoin)); // Remove cdpEngine permission for coinJoin to test it is correctly re-acticdpEnginee in exitAll
        coin.approve(address(proxy), 50 ether);
        this.coinSavingsAccount_deposit(address(coinJoin), address(coinSavingsAccount), 50 ether);
        this.coinSavingsAccount_withdrawAll(address(coinJoin), address(coinSavingsAccount));
        // In this case we get 49.999 COIN back as the returned amount is based purely in the pie amount
        assertEq(coin.balanceOf(address(this)), 49999999999999999999);
    }
}
