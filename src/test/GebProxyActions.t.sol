pragma solidity 0.6.7;

import "ds-test/test.sol";
import "ds-weth/weth9.sol";
import "ds-token/token.sol";

import {GebProxyActions, GebProxyActionsGlobalSettlement, GebProxyActionsCoinSavingsAccount, GebProxyIncentivesActions, GebProxyLeverageActions} from "../GebProxyActions.sol";

import {GebDeployTestBase, EnglishCollateralAuctionHouse} from "geb-deploy/test/GebDeploy.t.base.sol";
import {DGD, GNT} from "./tokens.sol";
import {CollateralJoin3, CollateralJoin4} from "geb-deploy/AdvancedTokenAdapters.sol";
import {DSValue} from "ds-value/value.sol";
import {GebSafeManager} from "geb-safe-manager/GebSafeManager.sol";
import {GetSafes} from "geb-safe-manager/GetSafes.sol";
import {GebProxyRegistry, DSProxyFactory, DSProxy} from "geb-proxy-registry/GebProxyRegistry.sol";
import {RollingDistributionIncentives} from "geb-incentives/uniswap/RollingDistributionIncentives.sol";

import "../uni/UniswapV2Factory.sol";
import "../uni/UniswapV2Pair.sol";
import "../uni/UniswapV2Router02.sol";

contract ProxyCalls {
    DSProxy proxy;
    address gebProxyActions;
    address gebProxyActionsGlobalSettlement;
    address gebProxyActionsCoinSavingsAccount;
    address gebProxyIncentivesActions;
    address gebProxyLeverageActions;

    function transfer(address, address, uint256) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function openSAFE(address, bytes32, address) public returns (uint safe) {
        bytes memory response = proxy.execute(gebProxyActions, msg.data);
        assembly {
            safe := mload(add(response, 0x20))
        }
    }

    function transferSAFEOwnership(address, uint, address) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function transferSAFEOwnershipToProxy(address, address, uint, address) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function allowSAFE(address, uint, address, uint) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function allowHandler(address, address, uint) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function approveSAFEModification(address, address) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function denySAFEModification(address, address) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function transferCollateral(address, uint, address, uint) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function transferInternalCoins(address, uint, address, uint) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function modifySAFECollateralization(address, uint, int, int) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function modifySAFECollateralization(address, uint, address, int, int) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function quitSystem(address, uint, address) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function enterSystem(address, address, uint) public {
        proxy.execute(gebProxyActions, msg.data);
    }

    function moveSAFE(address, uint, uint) public {
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

    function openLockETHAndGenerateDebt(address, address, address, address, bytes32, uint) public payable returns (uint safe) {
        address payable target = address(proxy);
        bytes memory data = abi.encodeWithSignature("execute(address,bytes)", gebProxyActions, msg.data);
        assembly {
            let succeeded := call(sub(gas(), 5000), target, callvalue(), add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize()
            let response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            safe := mload(add(response, 0x60))

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

    function openLockTokenCollateralAndGenerateDebt(address, address, address, address, bytes32, uint, uint, bool) public returns (uint safe) {
        bytes memory response = proxy.execute(gebProxyActions, msg.data);
        assembly {
            safe := mload(add(response, 0x20))
        }
    }

    function openLockGNTAndGenerateDebt(address, address, address, address, bytes32, uint, uint) public returns (address bag, uint safe) {
        bytes memory response = proxy.execute(gebProxyActions, msg.data);
        assembly {
            bag := mload(add(response, 0x20))
            safe := mload(add(response, 0x40))
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

    function lockETHAndGenerateDebtProvideLiquidityUniswap(address, address, address, address, address, uint, uint, uint, uint[2] memory) public payable {
        (bool success,) = address(proxy).call{value: msg.value}(abi.encodeWithSignature("execute(address,bytes)", gebProxyIncentivesActions, msg.data));
        require(success, "");
    }

    function generateDebtAndProvideLiquidityUniswap(address, address, address, address, uint, uint, uint[2] memory) public payable {
        (bool success,) = address(proxy).call{value: msg.value}(abi.encodeWithSignature("execute(address,bytes)", gebProxyIncentivesActions, msg.data));
        require(success, "");
    }

    function generateDebtAndProvideLiquidityStake(address, address, address, address, address, uint, uint, uint[2] memory) public payable {
        (bool success,) = address(proxy).call{value: msg.value}(abi.encodeWithSignature("execute(address,bytes)", gebProxyIncentivesActions, msg.data));
        require(success, "");
    }

    function harvestReward(address pool, uint campaign) public {
        proxy.execute(gebProxyIncentivesActions, abi.encodeWithSignature("harvestReward(address,uint256)", pool, campaign));
    }

    function getRewards(address pool, uint campaign) public {
        proxy.execute(gebProxyIncentivesActions, abi.encodeWithSignature("getRewards(address,uint256)", pool, campaign));
    }

    function getLockedReward(address pool, uint campaign) public {
        proxy.execute(gebProxyIncentivesActions, abi.encodeWithSignature("getLockedReward(address,uint256)", pool, campaign));
    }

    function exitMine(address pool) public {
        proxy.execute(gebProxyIncentivesActions, msg.data);
    }

    function withdrawFromMine(address pool, uint value) public {
        proxy.execute(gebProxyIncentivesActions, msg.data);
    }

    function withdrawAndHarvest(address pool, uint value, uint campaignId) public {
        proxy.execute(gebProxyIncentivesActions, msg.data);
    }


    function removeLiquidityUniswap(address uniswapRouter, address systemCoin, uint value, uint[2] memory) public returns (uint amountA, uint amountB) {
        bytes memory response = proxy.execute(gebProxyIncentivesActions, msg.data);
        assembly {
            amountA := mload(add(response, 0x20))
            amountB := mload(add(response, 0x40))
        }
    }

    function withdrawHarvestRemoveLiquidity(address incentives, address uniswapRouter, address systemCoin, uint value, uint campaignId, uint[2] memory) public returns (uint amountA, uint amountB) {
        bytes memory response = proxy.execute(gebProxyIncentivesActions, msg.data);
        assembly {
            amountA := mload(add(response, 0x20))
            amountB := mload(add(response, 0x40))
        }
    }

    function stakeInMine(address incentives, uint wad) public {
        proxy.execute(gebProxyIncentivesActions, msg.data);
    }

    function withdrawAndRemoveLiquidity(address join, address pool, uint value, address uniswapRouter, uint[2] memory) public returns (uint amountA, uint amountB) {
        bytes memory response = proxy.execute(gebProxyIncentivesActions, msg.data);
        assembly {
            amountA := mload(add(response, 0x20))
            amountB := mload(add(response, 0x40))
        }
    }

    function exitAndRemoveLiquidity(address join, address pool, address uniswapRouter, uint[2] memory) public returns (uint amountA, uint amountB) {
        bytes memory response = proxy.execute(gebProxyIncentivesActions, msg.data);
        assembly {
            amountA := mload(add(response, 0x20))
            amountB := mload(add(response, 0x40))
        }
    }

    function exitRemoveLiquidityRepayDebt(address manager, address coinJoin, uint safe, address pool, address uniswapRouter, uint[2] memory) public {
        proxy.execute(gebProxyIncentivesActions, msg.data);
    }

    function exitRemoveLiquidityRepayDebtFreeETH(address manager, address ethJoin, address coinJoin, uint safe, address incentives, uint ethToFree, address uniswapRouter, uint[2] memory) public {
        proxy.execute(gebProxyIncentivesActions, msg.data);
    }

    function withdrawRemoveLiquidityRepayDebt(address manager, address coinJoin, uint safe, address pool, uint value, address uniswapRouter, uint[2] memory) public {
        proxy.execute(gebProxyIncentivesActions, msg.data);
    }

    function withdrawRemoveLiquidityRepayDebtFreeETH(address manager, address ethJoin, address coinJoin, uint safe, address incentives, uint valueToWithdraw, uint ethToFree, address uniswapRouter, uint[2] memory) public {
        proxy.execute(gebProxyIncentivesActions, msg.data);
    }

    function openLockETHGenerateDebtProvideLiquidityUniswap(address, address, address, address, address, bytes32, uint, uint, uint[2] memory) public payable returns (uint safe) {
        address payable target = address(proxy);
        bytes memory data = abi.encodeWithSignature("execute(address,bytes)", gebProxyIncentivesActions, msg.data);
        assembly {
            let succeeded := call(sub(gas(), 5000), target, callvalue(), add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize()
            let response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            safe := mload(add(response, 0x60))

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
    }

    function openLockETHGenerateDebtProvideLiquidityStake(address, address, address, address, address, address, bytes32, uint256, uint256, uint256[2] memory) public payable returns (uint safe) {
        address payable target = address(proxy);
        bytes memory data = abi.encodeWithSignature("execute(address,bytes)", gebProxyIncentivesActions, msg.data);
        assembly {
            let succeeded := call(sub(gas(), 5000), target, callvalue(), add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize()
            let response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            safe := mload(add(response, 0x60))

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
    }

    function lockETHGenerateDebtProvideLiquidityStake(address, address, address, address, address, address, uint, uint, uint, uint[2] memory) public payable {
        (bool success,) = address(proxy).call{value: msg.value}(abi.encodeWithSignature("execute(address,bytes)", gebProxyIncentivesActions, msg.data));
        require(success, "");
    }

    function lockETHGenerateDebtProvideLiquidityUniswap(address, address, address, address, address, uint, uint, uint, uint[2] memory) public payable {
        (bool success,) = address(proxy).call{value: msg.value}(abi.encodeWithSignature("execute(address,bytes)", gebProxyIncentivesActions, msg.data));
        require(success, "");
    }

    function provideLiquidityUniswap(address coinJoin, address uniswapRouter, uint wad, uint[2] memory) public payable {
        (bool success,) = address(proxy).call{value: msg.value}(abi.encodeWithSignature("execute(address,bytes)", gebProxyIncentivesActions, msg.data));
        require(success, "");
    }

    function provideLiquidityStake(address, address, address, uint, uint[2] memory) public payable {
        (bool success,) = address(proxy).call{value: msg.value}(abi.encodeWithSignature("execute(address,bytes)", gebProxyIncentivesActions, msg.data));
        require(success, "");
    }

    function openLockETHLeverage(
        address uniswapV2Pair,
        address manager,
        address ethJoin,
        address taxCollector,
        address coinJoin,
        address weth,
        address callbackProxy,
        bytes32 collateralType,
        uint leverage // 3 decimal places, 2.5 == 2500
    ) public payable returns (uint safe) {
        address payable target = address(proxy);
        bytes memory data = abi.encodeWithSignature("execute(address,bytes)", gebProxyLeverageActions, msg.data);
        assembly {
            let succeeded := call(sub(gas(), 5000), target, callvalue(), add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize()
            let response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            safe := mload(add(response, 0x60))

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
    }

    function lockETHLeverage(
        address uniswapV2Pair,
        address manager,
        address ethJoin,
        address taxCollector,
        address coinJoin,
        address weth,
        address callbackProxy,
        bytes32 collateralType,
        uint safe,
        uint leverage // 3 decimal places, 2.5 == 2500
    ) public payable {
        (bool success,) = address(proxy).call{value: msg.value}(abi.encodeWithSignature("execute(address,bytes)", gebProxyLeverageActions, msg.data));
        require(success, "");
    }

    function flashLeverage(
        address uniswapV2Pair,
        address manager,
        address ethJoin,
        address taxCollector,
        address coinJoin,
        address weth,
        address callbackProxy,
        bytes32 collateralType,
        uint safe,
        uint leverage // 3 decimal places, 2.5 == 2500
    ) public {
        (bool success,) = address(proxy).call(abi.encodeWithSignature("execute(address,bytes)", gebProxyLeverageActions, msg.data));
        require(success, "");
    }

    function flashDeleverage(
        address uniswapV2Pair,
        address manager,
        address ethJoin,
        address taxCollector,
        address coinJoin,
        address weth,
        address callbackProxy,
        bytes32 collateralType,
        uint safe
    ) public {
        (bool success,) = address(proxy).call(abi.encodeWithSignature("execute(address,bytes)", gebProxyLeverageActions, msg.data));
        require(success, "");
    }

    function flashDeleverageFreeETH(
        address uniswapV2Pair,
        address manager,
        address ethJoin,
        address taxCollector,
        address coinJoin,
        address weth,
        address callbackProxy,
        bytes32 collateralType,
        uint safe,
        uint amountToFree
    ) public {
        (bool success,) = address(proxy).call(abi.encodeWithSignature("execute(address,bytes)", gebProxyLeverageActions, msg.data));
        require(success, "");
    }
}

contract FakeUser {
    function doTransferSAFEOwnership(
        GebSafeManager manager,
        uint safe,
        address dst
    ) public {
        manager.transferSAFEOwnership(safe, dst);
    }
}

contract GebProxyActionsTest is GebDeployTestBase, ProxyCalls {
    GebSafeManager manager;

    CollateralJoin3 dgdJoin;
    DGD dgd;
    DSValue orclDGD;
    EnglishCollateralAuctionHouse dgdEnglishCollateralAuctionHouse;
    CollateralJoin4 gntCollateralJoin;
    GNT gnt;
    DSValue orclGNT;
    GebProxyRegistry registry;

    bytes32 collateralAuctionType = bytes32("ENGLISH");

    function setUp() override public {
        super.setUp();
        deployStableKeepAuth(collateralAuctionType);

        // Add a token collateral
        dgd = new DGD(1000 * 10 ** 9);
        dgdJoin = new CollateralJoin3(address(safeEngine), "DGD", address(dgd), 9);
        orclDGD = new DSValue();
        gebDeploy.deployCollateral(bytes32("ENGLISH"), "DGD", address(dgdJoin), address(orclDGD), address(orclDGD), address(0));
        (dgdEnglishCollateralAuctionHouse, ,) = gebDeploy.collateralTypes("DGD");
        orclDGD.updateResult(uint(50 ether)); // Price 50 COIN = 1 DGD (in precision 18)
        this.modifyParameters(address(oracleRelayer), "DGD", "safetyCRatio", uint(1500000000 ether)); // Safety ratio 150%
        this.modifyParameters(address(oracleRelayer), "DGD", "liquidationCRatio", uint(1500000000 ether)); // Liquidation ratio 150%

        this.modifyParameters(address(safeEngine), bytes32("DGD"), bytes32("debtCeiling"), uint(10000 * 10 ** 45));
        oracleRelayer.updateCollateralPrice("DGD");
        (,,uint safetyPrice,,,) = safeEngine.collateralTypes("DGD");
        assertEq(safetyPrice, 50 * ONE * ONE / 1500000000 ether);

        gnt = new GNT(1000000 ether);
        gntCollateralJoin = new CollateralJoin4(address(safeEngine), "GNT", address(gnt));
        orclGNT = new DSValue();
        gebDeploy.deployCollateral(bytes32("ENGLISH"), "GNT", address(gntCollateralJoin), address(orclGNT), address(orclGNT), address(0));
        orclGNT.updateResult(uint(100 ether)); // Price 100 COIN = 1 GNT
        this.modifyParameters(address(oracleRelayer), "GNT", "safetyCRatio", uint(1500000000 ether)); // Safety ratio 150%
        this.modifyParameters(address(oracleRelayer), "GNT", "liquidationCRatio", uint(1500000000 ether)); // Liquidation ratio 150%

        this.modifyParameters(address(safeEngine), bytes32("GNT"), bytes32("debtCeiling"), uint(10000 * 10 ** 45));
        oracleRelayer.updateCollateralPrice("GNT");
        (,, safetyPrice,,,) = safeEngine.collateralTypes("GNT");
        assertEq(safetyPrice, 100 * ONE * ONE / 1500000000 ether);

        manager = new GebSafeManager(address(safeEngine));
        DSProxyFactory factory = new DSProxyFactory();
        registry = new GebProxyRegistry(address(factory));
        gebProxyActions = address(new GebProxyActions());
        gebProxyActionsGlobalSettlement = address(new GebProxyActionsGlobalSettlement());
        gebProxyActionsCoinSavingsAccount = address(new GebProxyActionsCoinSavingsAccount());
        gebProxyIncentivesActions = address(new GebProxyIncentivesActions());
        proxy = DSProxy(registry.build());
    }

    function lockedCollateral(bytes32 collateralType, address urn) public view returns (uint lktCollateral) {
        (lktCollateral,) = safeEngine.safes(collateralType, urn);
    }

    function generatedDebt(bytes32 collateralType, address urn) public view returns (uint genDebt) {
        (,genDebt) = safeEngine.safes(collateralType, urn);
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

    function testCreateSAFE() public {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        assertEq(safe, 1);
        assertEq(manager.ownsSAFE(safe), address(proxy));
    }

    function testTransferSAFEOwnership() public {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.transferSAFEOwnership(address(manager), safe, address(123));
        assertEq(manager.ownsSAFE(safe), address(123));
    }

    function testGiveSAFEToProxy() public {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        address userProxy = registry.build(address(123));
        this.transferSAFEOwnershipToProxy(address(registry), address(manager), safe, address(123));
        assertEq(manager.ownsSAFE(safe), userProxy);
    }

    function testGiveSAFEToNewProxy() public {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        assertEq(address(registry.proxies(address(123))), address(0));
        this.transferSAFEOwnershipToProxy(address(registry), address(manager), safe, address(123));
        DSProxy userProxy = registry.proxies(address(123));
        assertTrue(address(userProxy) != address(0));
        assertEq(userProxy.owner(), address(123));
        assertEq(manager.ownsSAFE(safe), address(userProxy));
    }

    function testFailGiveSAFEToNewContractProxy() public {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        FakeUser user = new FakeUser();
        assertEq(address(registry.proxies(address(user))), address(0));
        this.transferSAFEOwnershipToProxy(address(registry), address(manager), safe, address(user)); // Fails as user is a contract and not a regular address
    }

    function testGiveSAFEAllowedUser() public {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        FakeUser user = new FakeUser();
        this.allowSAFE(address(manager), safe, address(user), 1);
        user.doTransferSAFEOwnership(manager, safe, address(123));
        assertEq(manager.ownsSAFE(safe), address(123));
    }

    function testAllowUrn() public {
        assertEq(manager.handlerCan(address(proxy), address(123)), 0);
        this.allowHandler(address(manager), address(123), 1);
        assertEq(manager.handlerCan(address(proxy), address(123)), 1);
        this.allowHandler(address(manager), address(123), 0);
        assertEq(manager.handlerCan(address(proxy), address(123)), 0);
    }

    function testTransferCollateral() public {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));

        assertEq(coin.balanceOf(address(this)), 0);
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(manager.safes(safe), 1 ether);
        assertEq(safeEngine.tokenCollateral("ETH", address(this)), 0);
        assertEq(safeEngine.tokenCollateral("ETH", manager.safes(safe)), 1 ether);

        this.transferCollateral(address(manager), safe, address(this), 0.75 ether);

        assertEq(safeEngine.tokenCollateral("ETH", address(this)), 0.75 ether);
        assertEq(safeEngine.tokenCollateral("ETH", manager.safes(safe)), 0.25 ether);
    }

    function testModifySAFECollateralization() public {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));

        assertEq(coin.balanceOf(address(this)), 0);
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(manager.safes(safe), 1 ether);

        this.modifySAFECollateralization(address(manager), safe, 0.5 ether, 60 ether);
        assertEq(safeEngine.tokenCollateral("ETH", manager.safes(safe)), 0.5 ether);
        assertEq(safeEngine.coinBalance(manager.safes(safe)), mul(ONE, 60 ether));
        assertEq(safeEngine.coinBalance(address(this)), 0);

        this.transferInternalCoins(address(manager), safe, address(this), mul(ONE, 60 ether));
        assertEq(safeEngine.coinBalance(manager.safes(safe)), 0);
        assertEq(safeEngine.coinBalance(address(this)), mul(ONE, 60 ether));

        safeEngine.approveSAFEModification(address(coinJoin));
        coinJoin.exit(address(this), 60 ether);
        assertEq(coin.balanceOf(address(this)), 60 ether);
    }

    function testLockETH() public {
        uint initialBalance = address(this).balance;
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 0);
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 2 ether);
        assertEq(address(this).balance, initialBalance - 2 ether);
    }

    function testSafeLockETH() public {
        uint initialBalance = address(this).balance;
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 0);
        this.safeLockETH{value: 2 ether}(address(manager), address(ethJoin), safe, address(proxy));
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 2 ether);
        assertEq(address(this).balance, initialBalance - 2 ether);
    }

    function testLockETHOtherSAFEOwner() public {
        uint initialBalance = address(this).balance;
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.transferSAFEOwnership(address(manager), safe, address(123));
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 0);
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 2 ether);
        assertEq(address(this).balance, initialBalance - 2 ether);
    }

    function testFailSafeLockETHOtherSAFEOwner() public {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.transferSAFEOwnership(address(manager), safe, address(123));
        this.safeLockETH{value: 2 ether}(address(manager), address(ethJoin), safe, address(321));
    }

    function testLockTokenCollateral() public {
        col.mint(5 ether);
        uint safe = this.openSAFE(address(manager), "COL", address(proxy));
        col.approve(address(proxy), 2 ether);
        assertEq(lockedCollateral("COL", manager.safes(safe)), 0);
        this.lockTokenCollateral(address(manager), address(colJoin), safe, 2 ether, true);
        assertEq(lockedCollateral("COL", manager.safes(safe)), 2 ether);
        assertEq(col.balanceOf(address(this)), 3 ether);
    }

    function testSafeLockTokenCollateral() public {
        col.mint(5 ether);
        uint safe = this.openSAFE(address(manager), "COL", address(proxy));
        col.approve(address(proxy), 2 ether);
        assertEq(lockedCollateral("COL", manager.safes(safe)), 0);
        this.safeLockTokenCollateral(address(manager), address(colJoin), safe, 2 ether, true, address(proxy));
        assertEq(lockedCollateral("COL", manager.safes(safe)), 2 ether);
        assertEq(col.balanceOf(address(this)), 3 ether);
    }

    function testLockTokenCollateralDGD() public {
        uint safe = this.openSAFE(address(manager), "DGD", address(proxy));
        dgd.approve(address(proxy), 2 * 10 ** 9);
        assertEq(lockedCollateral("DGD", manager.safes(safe)), 0);
        uint prevBalance = dgd.balanceOf(address(this));
        this.lockTokenCollateral(address(manager), address(dgdJoin), safe, 2 * 10 ** 9, true);
        assertEq(lockedCollateral("DGD", manager.safes(safe)),  2 ether);
        assertEq(dgd.balanceOf(address(this)), prevBalance - 2 * 10 ** 9);
    }

    function testLockTokenCollateralGNT() public {
        uint safe = this.openSAFE(address(manager), "GNT", address(proxy));
        assertEq(lockedCollateral("GNT", manager.safes(safe)), 0);
        uint prevBalance = gnt.balanceOf(address(this));
        address bag = this.makeCollateralBag(address(gntCollateralJoin));
        assertEq(gnt.balanceOf(bag), 0);
        gnt.transfer(bag, 2 ether);
        assertEq(gnt.balanceOf(address(this)), prevBalance - 2 ether);
        assertEq(gnt.balanceOf(bag), 2 ether);
        this.lockTokenCollateral(address(manager), address(gntCollateralJoin), safe, 2 ether, false);
        assertEq(lockedCollateral("GNT", manager.safes(safe)),  2 ether);
        assertEq(gnt.balanceOf(bag), 0);
    }

    function testLockTokenCollateralOtherSAFEOwner() public {
        col.mint(5 ether);
        uint safe = this.openSAFE(address(manager), "COL", address(proxy));
        this.transferSAFEOwnership(address(manager), safe, address(123));
        col.approve(address(proxy), 2 ether);
        assertEq(lockedCollateral("COL", manager.safes(safe)), 0);
        this.lockTokenCollateral(address(manager), address(colJoin), safe, 2 ether, true);
        assertEq(lockedCollateral("COL", manager.safes(safe)), 2 ether);
        assertEq(col.balanceOf(address(this)), 3 ether);
    }

    function testFailSafeLockTokenCollateralOtherSAFEOwner() public {
        col.mint(5 ether);
        uint safe = this.openSAFE(address(manager), "COL", address(proxy));
        this.transferSAFEOwnership(address(manager), safe, address(123));
        col.approve(address(proxy), 2 ether);
        this.safeLockTokenCollateral(address(manager), address(colJoin), safe, 2 ether, true, address(321));
    }

    function testFreeETH() public {
        uint initialBalance = address(this).balance;
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        this.freeETH(address(manager), address(ethJoin), safe, 1 ether);
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 1 ether);
        assertEq(address(this).balance, initialBalance - 1 ether);
    }

    function testFreeTokenCollateral() public {
        col.mint(5 ether);
        uint safe = this.openSAFE(address(manager), "COL", address(proxy));
        col.approve(address(proxy), 2 ether);
        this.lockTokenCollateral(address(manager), address(colJoin), safe, 2 ether, true);
        this.freeTokenCollateral(address(manager), address(colJoin), safe, 1 ether);
        assertEq(lockedCollateral("COL", manager.safes(safe)), 1 ether);
        assertEq(col.balanceOf(address(this)), 4 ether);
    }

    function testFreeTokenCollateralDGD() public {
        uint safe = this.openSAFE(address(manager), "DGD", address(proxy));
        dgd.approve(address(proxy), 2 * 10 ** 9);
        assertEq(lockedCollateral("DGD", manager.safes(safe)), 0);
        uint prevBalance = dgd.balanceOf(address(this));
        this.lockTokenCollateral(address(manager), address(dgdJoin), safe, 2 * 10 ** 9, true);
        this.freeTokenCollateral(address(manager), address(dgdJoin), safe, 1 * 10 ** 9);
        assertEq(lockedCollateral("DGD", manager.safes(safe)),  1 ether);
        assertEq(dgd.balanceOf(address(this)), prevBalance - 1 * 10 ** 9);
    }

    function testFreeTokenCollateralGNT() public {
        uint safe = this.openSAFE(address(manager), "GNT", address(proxy));
        assertEq(lockedCollateral("GNT", manager.safes(safe)), 0);
        uint prevBalance = gnt.balanceOf(address(this));
        address bag = this.makeCollateralBag(address(gntCollateralJoin));
        gnt.transfer(bag, 2 ether);
        this.lockTokenCollateral(address(manager), address(gntCollateralJoin), safe, 2 ether, false);
        this.freeTokenCollateral(address(manager), address(gntCollateralJoin), safe, 1 ether);
        assertEq(lockedCollateral("GNT", manager.safes(safe)),  1 ether);
        assertEq(gnt.balanceOf(address(this)), prevBalance - 1 ether);
    }

    function testGenerateDebt() public {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), safe, 300 ether);
        assertEq(coin.balanceOf(address(this)), 300 ether);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 300 ether);
    }

    function testGenerateDebtAfterCollectingTax() public {
        this.modifyParameters(address(taxCollector), bytes32("ETH"), bytes32("stabilityFee"), uint(1.05 * 10 ** 27));
        hevm.warp(now + 1);
        taxCollector.taxSingle("ETH"); // This is actually not necessary as `generateDebt` will also call taxSingle
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), safe, 300 ether);
        assertEq(coin.balanceOf(address(this)), 300 ether);
        assertEq(generatedDebt("ETH", manager.safes(safe)), mul(300 ether, ONE) / (1.05 * 10 ** 27) + 1); // Extra wei due rounding
    }

    function testRepayDebt() public {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), safe, 300 ether);
        coin.approve(address(proxy), 100 ether);
        this.repayDebt(address(manager), address(coinJoin), safe, 100 ether);
        assertEq(coin.balanceOf(address(this)), 200 ether);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 200 ether);
    }

    function testRepayDebtAll() public {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), safe, 300 ether);
        coin.approve(address(proxy), 300 ether);
        this.repayAllDebt(address(manager), address(coinJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 0);
    }

    function testSafeRepayDebt() public {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), safe, 300 ether);
        coin.approve(address(proxy), 100 ether);
        this.safeRepayDebt(address(manager), address(coinJoin), safe, 100 ether, address(proxy));
        assertEq(coin.balanceOf(address(this)), 200 ether);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 200 ether);
    }

    function testSafeRepayAllDebt() public {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), safe, 300 ether);
        coin.approve(address(proxy), 300 ether);
        this.safeRepayAllDebt(address(manager), address(coinJoin), safe, address(proxy));
        assertEq(coin.balanceOf(address(this)), 0);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 0);
    }

    function testRepayDebtOtherSAFEOwner() public {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), safe, 300 ether);
        coin.approve(address(proxy), 100 ether);
        this.transferSAFEOwnership(address(manager), safe, address(123));
        this.repayDebt(address(manager), address(coinJoin), safe, 100 ether);
        assertEq(coin.balanceOf(address(this)), 200 ether);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 200 ether);
    }

    function testFailSafeRepayDebtOtherSAFEOwner() public {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), safe, 300 ether);
        coin.approve(address(proxy), 100 ether);
        this.transferSAFEOwnership(address(manager), safe, address(123));
        this.safeRepayDebt(address(manager), address(coinJoin), safe, 100 ether, address(321));
    }

    function testFailSafeRepayDebtAllOtherSAFEOwner() public {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), safe, 300 ether);
        coin.approve(address(proxy), 300 ether);
        this.transferSAFEOwnership(address(manager), safe, address(123));
        this.safeRepayAllDebt(address(manager), address(coinJoin), safe, address(321));
    }

    function testRepayDebtAfterTaxation() public {
        this.modifyParameters(address(taxCollector), bytes32("ETH"), bytes32("stabilityFee"), uint(1.05 * 10 ** 27));
        hevm.warp(now + 1);
        taxCollector.taxSingle("ETH");
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), safe, 300 ether);
        coin.approve(address(proxy), 100 ether);
        this.repayDebt(address(manager), address(coinJoin), safe, 100 ether);
        assertEq(coin.balanceOf(address(this)), 200 ether);
        assertEq(generatedDebt("ETH", manager.safes(safe)), mul(200 ether, ONE) / (1.05 * 10 ** 27) + 1);
    }

    function testRepayAllDebtAfterTaxation() public {
        taxCollector.taxSingle("ETH");
        this.modifyParameters(address(taxCollector), bytes32("ETH"), bytes32("stabilityFee"), uint(1.05 * 10 ** 27));
        hevm.warp(now + 1);
        taxCollector.taxSingle("ETH");
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), safe, 300 ether);
        coin.approve(address(proxy), 300 ether);
        this.repayDebt(address(manager), address(coinJoin), safe, 300 ether);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 0);
    }

    function testRepayAllDebtAfterTaxation2() public {
        taxCollector.taxSingle("ETH");
        this.modifyParameters(address(taxCollector), bytes32("ETH"), bytes32("stabilityFee"), uint(1.05 * 10 ** 27));
        hevm.warp(now + 1);
        taxCollector.taxSingle("ETH"); // This is actually not necessary as `draw` will also call taxSingle
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        uint times = 30;
        this.lockETH{value: 2 ether * times}(address(manager), address(ethJoin), safe);
        for (uint i = 0; i < times; i++) {
            this.generateDebt(address(manager), address(taxCollector), address(coinJoin), safe, 300 ether);
        }
        coin.approve(address(proxy), 300 ether * times);
        this.repayDebt(address(manager), address(coinJoin), safe, 300 ether * times);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 0);
    }

    function testLockETHAndGenerateDebt() public {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        uint initialBalance = address(this).balance;
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 0);
        assertEq(coin.balanceOf(address(this)), 0);
        this.lockETHAndGenerateDebt{value: 2 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), safe, 300 ether);
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 2 ether);
        assertEq(coin.balanceOf(address(this)), 300 ether);
        assertEq(address(this).balance, initialBalance - 2 ether);
    }

    function testOpenLockETHAndGenerateDebt() public {
        uint initialBalance = address(this).balance;
        assertEq(coin.balanceOf(address(this)), 0);
        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), "ETH", 300 ether);
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 2 ether);
        assertEq(coin.balanceOf(address(this)), 300 ether);
        assertEq(address(this).balance, initialBalance - 2 ether);
    }

    function testLockTokenCollateralAndGenerateDebt() public {
        col.mint(5 ether);
        uint safe = this.openSAFE(address(manager), "COL", address(proxy));
        col.approve(address(proxy), 2 ether);
        assertEq(lockedCollateral("COL", manager.safes(safe)), 0);
        assertEq(coin.balanceOf(address(this)), 0);
        this.lockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(colJoin), address(coinJoin), safe, 2 ether, 10 ether, true);
        assertEq(lockedCollateral("COL", manager.safes(safe)), 2 ether);
        assertEq(coin.balanceOf(address(this)), 10 ether);
        assertEq(col.balanceOf(address(this)), 3 ether);
    }

    function testLockTokenCollateralDGDAndGenerateDebt() public {
        uint safe = this.openSAFE(address(manager), "DGD", address(proxy));
        dgd.approve(address(proxy), 3 * 10 ** 9);
        assertEq(lockedCollateral("DGD", manager.safes(safe)), 0);
        uint prevBalance = dgd.balanceOf(address(this));
        this.lockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(dgdJoin), address(coinJoin), safe, 3 * 10 ** 9, 50 ether, true);
        assertEq(lockedCollateral("DGD", manager.safes(safe)), 3 ether);
        assertEq(coin.balanceOf(address(this)), 50 ether);
        assertEq(dgd.balanceOf(address(this)), prevBalance - 3 * 10 ** 9);
    }

    function testLockTokenCollateralGNTAndGenerateDebt() public {
        uint safe = this.openSAFE(address(manager), "GNT", address(proxy));
        assertEq(lockedCollateral("GNT", manager.safes(safe)), 0);
        uint prevBalance = gnt.balanceOf(address(this));
        address bag = this.makeCollateralBag(address(gntCollateralJoin));
        gnt.transfer(bag, 3 ether);
        this.lockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(gntCollateralJoin), address(coinJoin), safe, 3 ether, 50 ether, false);
        assertEq(lockedCollateral("GNT", manager.safes(safe)), 3 ether);
        assertEq(coin.balanceOf(address(this)), 50 ether);
        assertEq(gnt.balanceOf(address(this)), prevBalance - 3 ether);
    }

    function testOpenLockTokenCollateralAndGenerateDebt() public {
        col.mint(5 ether);
        col.approve(address(proxy), 2 ether);
        assertEq(coin.balanceOf(address(this)), 0);
        uint safe = this.openLockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(colJoin), address(coinJoin), "COL", 2 ether, 10 ether, true);
        assertEq(lockedCollateral("COL", manager.safes(safe)), 2 ether);
        assertEq(coin.balanceOf(address(this)), 10 ether);
        assertEq(col.balanceOf(address(this)), 3 ether);
    }

    function testOpenLockTokenCollateralGNTAndGenerateDebt() public {
        assertEq(coin.balanceOf(address(this)), 0);
        address bag = this.makeCollateralBag(address(gntCollateralJoin));
        assertEq(address(bag), gntCollateralJoin.bags(address(proxy)));
        gnt.transfer(bag, 2 ether);
        uint safe = this.openLockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(gntCollateralJoin), address(coinJoin), "GNT", 2 ether, 10 ether, false);
        assertEq(lockedCollateral("GNT", manager.safes(safe)), 2 ether);
        assertEq(coin.balanceOf(address(this)), 10 ether);
    }

    function testOpenLockTokenCollateralGNTAndGenerateDebtSafe() public {
        assertEq(coin.balanceOf(address(this)), 0);
        gnt.transfer(address(proxy), 2 ether);
        (address bag, uint safe) = this.openLockGNTAndGenerateDebt(address(manager), address(taxCollector), address(gntCollateralJoin), address(coinJoin), "GNT", 2 ether, 10 ether);
        assertEq(address(bag), gntCollateralJoin.bags(address(proxy)));
        assertEq(lockedCollateral("GNT", manager.safes(safe)), 2 ether);
        assertEq(coin.balanceOf(address(this)), 10 ether);
    }

    function testOpenLockTokenCollateralGNTAndGenerateDebtSafeTwice() public {
        assertEq(coin.balanceOf(address(this)), 0);
        gnt.transfer(address(proxy), 4 ether);
        (address bag, uint safe) = this.openLockGNTAndGenerateDebt(address(manager), address(taxCollector), address(gntCollateralJoin), address(coinJoin), "GNT", 2 ether, 10 ether);
        (address bag2, uint safe2) = this.openLockGNTAndGenerateDebt(address(manager), address(taxCollector), address(gntCollateralJoin), address(coinJoin), "GNT", 2 ether, 10 ether);
        assertEq(address(bag), gntCollateralJoin.bags(address(proxy)));
        assertEq(address(bag), address(bag2));
        assertEq(lockedCollateral("GNT", manager.safes(safe)), 2 ether);
        assertEq(lockedCollateral("GNT", manager.safes(safe2)), 2 ether);
        assertEq(coin.balanceOf(address(this)), 20 ether);
    }

    function testRepayDebtAndFreeETH() public {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        uint initialBalance = address(this).balance;
        this.lockETHAndGenerateDebt{value: 2 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), safe, 300 ether);
        coin.approve(address(proxy), 250 ether);
        this.repayDebtAndFreeETH(address(manager), address(ethJoin), address(coinJoin), safe, 1.5 ether, 250 ether);
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 0.5 ether);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 50 ether);
        assertEq(coin.balanceOf(address(this)), 50 ether);
        assertEq(address(this).balance, initialBalance - 0.5 ether);
    }

    function testRepayAllDebtAndFreeETH() public {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        uint initialBalance = address(this).balance;
        this.lockETHAndGenerateDebt{value: 2 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), safe, 300 ether);
        coin.approve(address(proxy), 300 ether);
        this.repayAllDebtAndFreeETH(address(manager), address(ethJoin), address(coinJoin), safe, 1.5 ether);
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 0.5 ether);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 0);
        assertEq(coin.balanceOf(address(this)), 0);
        assertEq(address(this).balance, initialBalance - 0.5 ether);
    }

    function testRepayDebtAndFreeTokenCollateral() public {
        col.mint(5 ether);
        uint safe = this.openSAFE(address(manager), "COL", address(proxy));
        col.approve(address(proxy), 2 ether);
        this.lockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(colJoin), address(coinJoin), safe, 2 ether, 10 ether, true);
        coin.approve(address(proxy), 8 ether);
        this.repayDebtAndFreeTokenCollateral(address(manager), address(colJoin), address(coinJoin), safe, 1.5 ether, 8 ether);
        assertEq(lockedCollateral("COL", manager.safes(safe)), 0.5 ether);
        assertEq(generatedDebt("COL", manager.safes(safe)), 2 ether);
        assertEq(coin.balanceOf(address(this)), 2 ether);
        assertEq(col.balanceOf(address(this)), 4.5 ether);
    }

    function testRepayAllDebtAndFreeTokenCollateral() public {
        col.mint(5 ether);
        uint safe = this.openSAFE(address(manager), "COL", address(proxy));
        col.approve(address(proxy), 2 ether);
        this.lockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(colJoin), address(coinJoin), safe, 2 ether, 10 ether, true);
        coin.approve(address(proxy), 10 ether);
        this.repayAllDebtAndFreeTokenCollateral(address(manager), address(colJoin), address(coinJoin), safe, 1.5 ether);
        assertEq(lockedCollateral("COL", manager.safes(safe)), 0.5 ether);
        assertEq(generatedDebt("COL", manager.safes(safe)), 0);
        assertEq(coin.balanceOf(address(this)), 0);
        assertEq(col.balanceOf(address(this)), 4.5 ether);
    }

    function testWipeAndFreeTokenCollateralDGDAndGenerateDebt() public {
        uint safe = this.openSAFE(address(manager), "DGD", address(proxy));
        dgd.approve(address(proxy), 3 * 10 ** 9);
        assertEq(lockedCollateral("DGD", manager.safes(safe)), 0);
        uint prevBalance = dgd.balanceOf(address(this));
        this.lockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(dgdJoin), address(coinJoin), safe, 3 * 10 ** 9, 50 ether, true);
        coin.approve(address(proxy), 25 ether);
        this.repayDebtAndFreeTokenCollateral(address(manager), address(dgdJoin), address(coinJoin), safe, 1 * 10 ** 9, 25 ether);
        assertEq(lockedCollateral("DGD", manager.safes(safe)), 2 ether);
        assertEq(coin.balanceOf(address(this)), 25 ether);
        assertEq(dgd.balanceOf(address(this)), prevBalance - 2 * 10 ** 9);
    }

    function testPreventHigherCoinOnRepayDebt() public {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETHAndGenerateDebt{value: 2 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), safe, 300 ether);

        weth.deposit{value: 2 ether}();
        weth.approve(address(ethJoin), 2 ether);
        ethJoin.join(address(this), 2 ether);
        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 1 ether, 150 ether);
        safeEngine.transferInternalCoins(address(this), manager.safes(safe), 150 ether);

        coin.approve(address(proxy), 300 ether);
        this.repayDebt(address(manager), address(coinJoin), safe, 300 ether);
    }

    function testApproveDenySAFEModification() public {
        assertEq(safeEngine.safeRights(address(proxy), address(123)), 0);
        this.approveSAFEModification(address(safeEngine), address(123));
        assertEq(safeEngine.safeRights(address(proxy), address(123)), 1);
        this.denySAFEModification(address(safeEngine), address(123));
        assertEq(safeEngine.safeRights(address(proxy), address(123)), 0);
    }

    function testQuitSystem() public {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETHAndGenerateDebt{value: 1 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), safe, 50 ether);

        assertEq(lockedCollateral("ETH", manager.safes(safe)), 1 ether);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 50 ether);
        assertEq(lockedCollateral("ETH", address(proxy)), 0);
        assertEq(generatedDebt("ETH", address(proxy)), 0);

        this.approveSAFEModification(address(safeEngine), address(manager));
        this.quitSystem(address(manager), safe, address(proxy));

        assertEq(lockedCollateral("ETH", manager.safes(safe)), 0);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 0);
        assertEq(lockedCollateral("ETH", address(proxy)), 1 ether);
        assertEq(generatedDebt("ETH", address(proxy)), 50 ether);
    }

    function testEnterSystem() public {
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), 1 ether);
        ethJoin.join(address(this), 1 ether);
        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 1 ether, 50 ether);
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));

        assertEq(lockedCollateral("ETH", manager.safes(safe)), 0);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 0);
        assertEq(lockedCollateral("ETH", address(this)), 1 ether);
        assertEq(generatedDebt("ETH", address(this)), 50 ether);

        safeEngine.approveSAFEModification(address(manager));
        manager.allowHandler(address(proxy), 1);
        this.enterSystem(address(manager), address(this), safe);

        assertEq(lockedCollateral("ETH", manager.safes(safe)), 1 ether);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 50 ether);
        assertEq(lockedCollateral("ETH", address(this)), 0);
        assertEq(generatedDebt("ETH", address(this)), 0);
    }

    function testMoveSAFE() public {
        uint safeSrc = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETHAndGenerateDebt{value: 1 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), safeSrc, 50 ether);

        uint safeDst = this.openSAFE(address(manager), "ETH", address(proxy));

        assertEq(lockedCollateral("ETH", manager.safes(safeSrc)), 1 ether);
        assertEq(generatedDebt("ETH", manager.safes(safeSrc)), 50 ether);
        assertEq(lockedCollateral("ETH", manager.safes(safeDst)), 0);
        assertEq(generatedDebt("ETH", manager.safes(safeDst)), 0);

        this.moveSAFE(address(manager), safeSrc, safeDst);

        assertEq(lockedCollateral("ETH", manager.safes(safeSrc)), 0);
        assertEq(generatedDebt("ETH", manager.safes(safeSrc)), 0);
        assertEq(lockedCollateral("ETH", manager.safes(safeDst)), 1 ether);
        assertEq(generatedDebt("ETH", manager.safes(safeDst)), 50 ether);
    }

    function _collateralAuctionETH() internal returns (uint safe) {
        this.modifyParameters(address(liquidationEngine), "ETH", "liquidationQuantity", rad(1000 ether));
        this.modifyParameters(address(liquidationEngine), "ETH", "liquidationPenalty", WAD);

        safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETHAndGenerateDebt{value: 1 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), safe, 200 ether); // Maximun COIN generated
        orclETH.updateResult(uint(300 * 10 ** 18 - 1)); // Force liquidation
        oracleRelayer.updateCollateralPrice("ETH");
        uint batchId = liquidationEngine.liquidateSAFE("ETH", manager.safes(safe));

        address(user1).transfer(10 ether);
        user1.doEthJoin(address(weth), address(ethJoin), address(user1), 10 ether);
        user1.doModifySAFECollateralization(address(safeEngine), "ETH", address(user1), address(user1), address(user1), 10 ether, 1000 ether);

        address(user2).transfer(10 ether);
        user2.doEthJoin(address(weth), address(ethJoin), address(user2), 10 ether);
        user2.doModifySAFECollateralization(address(safeEngine), "ETH", address(user2), address(user2), address(user2), 10 ether, 1000 ether);

        user1.doSAFEApprove(address(safeEngine), address(ethEnglishCollateralAuctionHouse));
        user2.doSAFEApprove(address(safeEngine), address(ethEnglishCollateralAuctionHouse));

        user1.doIncreaseBidSize(address(ethEnglishCollateralAuctionHouse), batchId, 1 ether, rad(200 ether));
        user2.doDecreaseSoldAmount(address(ethEnglishCollateralAuctionHouse), batchId, 0.7 ether, rad(200 ether));
    }

    function testExitETHAfterCollateralAuction() public {
        uint safe = _collateralAuctionETH();
        assertEq(safeEngine.tokenCollateral("ETH", manager.safes(safe)), 0.3 ether);
        uint prevBalance = address(this).balance;
        this.exitETH(address(manager), address(ethJoin), safe, 0.3 ether);
        assertEq(safeEngine.tokenCollateral("ETH", manager.safes(safe)), 0);
        assertEq(address(this).balance, prevBalance + 0.3 ether);
    }

    function testExitTokenCollateralAfterAuction() public {
        this.modifyParameters(address(liquidationEngine), "COL", "liquidationQuantity", rad(100 ether));
        this.modifyParameters(address(liquidationEngine), "COL", "liquidationPenalty", WAD);

        col.mint(1 ether);
        uint safe = this.openSAFE(address(manager), "COL", address(proxy));
        col.approve(address(proxy), 1 ether);
        this.lockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(colJoin), address(coinJoin), safe, 1 ether, 40 ether, true);

        orclCOL.updateResult(uint(40 * 10 ** 18)); // Force liquidation
        oracleRelayer.updateCollateralPrice("COL");
        uint batchId = liquidationEngine.liquidateSAFE("COL", manager.safes(safe));

        address(user1).transfer(10 ether);
        user1.doEthJoin(address(weth), address(ethJoin), address(user1), 10 ether);
        user1.doModifySAFECollateralization(address(safeEngine), "ETH", address(user1), address(user1), address(user1), 10 ether, 1000 ether);

        address(user2).transfer(10 ether);
        user2.doEthJoin(address(weth), address(ethJoin), address(user2), 10 ether);
        user2.doModifySAFECollateralization(address(safeEngine), "ETH", address(user2), address(user2), address(user2), 10 ether, 1000 ether);

        user1.doSAFEApprove(address(safeEngine), address(colEnglishCollateralAuctionHouse));
        user2.doSAFEApprove(address(safeEngine), address(colEnglishCollateralAuctionHouse));

        user1.doIncreaseBidSize(address(colEnglishCollateralAuctionHouse), batchId, 1 ether, rad(40 ether));

        user2.doDecreaseSoldAmount(address(colEnglishCollateralAuctionHouse), batchId, 0.7 ether, rad(40 ether));
        assertEq(safeEngine.tokenCollateral("COL", manager.safes(safe)), 0.3 ether);
        assertEq(col.balanceOf(address(this)), 0);
        this.exitTokenCollateral(address(manager), address(colJoin), safe, 0.3 ether);
        assertEq(safeEngine.tokenCollateral("COL", manager.safes(safe)), 0);
        assertEq(col.balanceOf(address(this)), 0.3 ether);
    }

    function testExitDGDAfterAuction() public {
        this.modifyParameters(address(liquidationEngine), "DGD", "liquidationQuantity", rad(100 ether));
        this.modifyParameters(address(liquidationEngine), "DGD", "liquidationPenalty", WAD);

        uint safe = this.openSAFE(address(manager), "DGD", address(proxy));
        dgd.approve(address(proxy), 1 * 10 ** 9);
        this.lockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(dgdJoin), address(coinJoin), safe, 1 * 10 ** 9, 30 ether, true);

        orclDGD.updateResult(uint(40 * 10 ** 18)); // Force liquidation
        oracleRelayer.updateCollateralPrice("DGD");
        uint batchId = liquidationEngine.liquidateSAFE("DGD", manager.safes(safe));

        address(user1).transfer(10 ether);
        user1.doEthJoin(address(weth), address(ethJoin), address(user1), 10 ether);
        user1.doModifySAFECollateralization(address(safeEngine), "ETH", address(user1), address(user1), address(user1), 10 ether, 1000 ether);

        address(user2).transfer(10 ether);
        user2.doEthJoin(address(weth), address(ethJoin), address(user2), 10 ether);
        user2.doModifySAFECollateralization(address(safeEngine), "ETH", address(user2), address(user2), address(user2), 10 ether, 1000 ether);

        user1.doSAFEApprove(address(safeEngine), address(dgdEnglishCollateralAuctionHouse));
        user2.doSAFEApprove(address(safeEngine), address(dgdEnglishCollateralAuctionHouse));

        user1.doIncreaseBidSize(address(dgdEnglishCollateralAuctionHouse), batchId, 1 ether, rad(30 ether));

        user2.doDecreaseSoldAmount(address(dgdEnglishCollateralAuctionHouse), batchId, 0.7 ether, rad(30 ether));
        assertEq(safeEngine.tokenCollateral("DGD", manager.safes(safe)), 0.3 ether);
        uint prevBalance = dgd.balanceOf(address(this));
        this.exitTokenCollateral(address(manager), address(dgdJoin), safe, 0.3 * 10 ** 9);
        assertEq(safeEngine.tokenCollateral("DGD", manager.safes(safe)), 0);
        assertEq(dgd.balanceOf(address(this)), prevBalance + 0.3 * 10 ** 9);
    }

    function testLockBackAfterCollateralAuction() public {
        uint safe = _collateralAuctionETH();
        (uint lockedCollateral,) = safeEngine.safes("ETH", manager.safes(safe));
        assertEq(lockedCollateral, 0);
        assertEq(safeEngine.tokenCollateral("ETH", manager.safes(safe)), 0.3 ether);
        this.modifySAFECollateralization(address(manager), safe, 0.3 ether, 0);
        (lockedCollateral,) = safeEngine.safes("ETH", manager.safes(safe));
        assertEq(lockedCollateral, 0.3 ether);
        assertEq(safeEngine.tokenCollateral("ETH", manager.safes(safe)), 0);
    }

    function testGlobalSettlement() public {
        this.modifyParameters(address(liquidationEngine), "ETH", "liquidationQuantity", rad(100 ether));
        this.modifyParameters(address(liquidationEngine), "ETH", "liquidationPenalty", WAD);

        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), "ETH", 300 ether);
        col.mint(1 ether);
        col.approve(address(proxy), 1 ether);
        uint safe2 = this.openLockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(colJoin), address(coinJoin), "COL", 1 ether, 5 ether, true);
        dgd.approve(address(proxy), 1 * 10 ** 9);
        uint safe3 = this.openLockTokenCollateralAndGenerateDebt(address(manager), address(taxCollector), address(dgdJoin), address(coinJoin), "DGD", 1 * 10 ** 9, 5 ether, true);

        this.shutdownSystem(address(globalSettlement));
        globalSettlement.freezeCollateralType("ETH");
        globalSettlement.freezeCollateralType("COL");
        globalSettlement.freezeCollateralType("DGD");

        (uint lockedCollateral, uint generatedDebt) = safeEngine.safes("ETH", manager.safes(safe));
        assertEq(lockedCollateral, 2 ether);
        assertEq(generatedDebt, 300 ether);

        (lockedCollateral, generatedDebt) = safeEngine.safes("COL", manager.safes(safe2));
        assertEq(lockedCollateral, 1 ether);
        assertEq(generatedDebt, 5 ether);

        (lockedCollateral, generatedDebt) = safeEngine.safes("DGD", manager.safes(safe3));
        assertEq(lockedCollateral, 1 ether);
        assertEq(generatedDebt, 5 ether);

        uint prevBalanceETH = address(this).balance;
        this.globalSettlement_freeETH(address(manager), address(ethJoin), address(globalSettlement), safe);
        (lockedCollateral, generatedDebt) = safeEngine.safes("ETH", manager.safes(safe));
        assertEq(lockedCollateral, 0);
        assertEq(generatedDebt, 0);
        uint remainingCollateralValue = 2 ether - 300 * globalSettlement.finalCoinPerCollateralPrice("ETH") / 10 ** 9; // 2 ETH (deposited) - 300 COIN debt * ETH cage price
        assertEq(address(this).balance, prevBalanceETH + remainingCollateralValue);

        uint prevBalanceCol = col.balanceOf(address(this));
        this.globalSettlement_freeTokenCollateral(address(manager), address(colJoin), address(globalSettlement), safe2);
        (lockedCollateral, generatedDebt) = safeEngine.safes("COL", manager.safes(safe2));
        assertEq(lockedCollateral, 0);
        assertEq(generatedDebt, 0);
        remainingCollateralValue = 1 ether - 5 * globalSettlement.finalCoinPerCollateralPrice("COL") / 10 ** 9; // 1 COL (deposited) - 5 COIN debt * COL cage price
        assertEq(col.balanceOf(address(this)), prevBalanceCol + remainingCollateralValue);

        uint prevBalanceDGD = dgd.balanceOf(address(this));
        this.globalSettlement_freeTokenCollateral(address(manager), address(dgdJoin), address(globalSettlement), safe3);
        (lockedCollateral, generatedDebt) = safeEngine.safes("DGD", manager.safes(safe3));
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
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETHAndGenerateDebt{value: 1 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), safe, 50 ether);
        coin.approve(address(proxy), 50 ether);
        assertEq(coin.balanceOf(address(this)), 50 ether);
        assertEq(coinSavingsAccount.savings(address(this)), 0 ether);
        this.denySAFEModification(address(safeEngine), address(coinJoin)); // Remove safeEngine permission for coinJoin to test it is correctly re-actisafeEnginee in exit
        this.coinSavingsAccount_deposit(address(coinJoin), address(coinSavingsAccount), 50 ether);
        assertEq(coin.balanceOf(address(this)), 0 ether);
        assertEq(coinSavingsAccount.savings(address(proxy)) * coinSavingsAccount.accumulatedRate(), 50 ether * ONE);
        hevm.warp(initialTime + 1); // Moved 1 second
        coinSavingsAccount.updateAccumulatedRate();
        assertEq(coinSavingsAccount.savings(address(proxy)) * coinSavingsAccount.accumulatedRate(), 52.5 ether * ONE); // Now the equivalent COIN amount is 2.5 COIN extra
        this.coinSavingsAccount_withdraw(address(coinJoin), address(coinSavingsAccount), 52.5 ether);
        assertEq(coin.balanceOf(address(this)), 52.5 ether);
        assertEq(coinSavingsAccount.savings(address(proxy)), 0);
    }

    function testCoinSavingsAccountRounding() public {
        this.modifyParameters(address(coinSavingsAccount), "savingsRate", uint(1.05 * 10 ** 27));
        uint initialTime = 1; // Initial time set to 1 this way some the pie will not be the same than the initial COIN wad amount
        hevm.warp(initialTime);
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETHAndGenerateDebt{value: 1 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), safe, 50 ether);
        coin.approve(address(proxy), 50 ether);
        assertEq(coin.balanceOf(address(this)), 50 ether);
        assertEq(coinSavingsAccount.savings(address(this)), 0 ether);
        this.denySAFEModification(address(safeEngine), address(coinJoin)); // Remove safeEngine permission for coinJoin to test it is correctly re-actisafeEnginee in exit
        this.coinSavingsAccount_deposit(address(coinJoin), address(coinSavingsAccount), 50 ether);
        assertEq(coin.balanceOf(address(this)), 0 ether);
        // Due rounding the COIN equivalent is not the same than initial wad amount
        assertEq(coinSavingsAccount.savings(address(proxy)) * coinSavingsAccount.accumulatedRate(), 49999999999999999999350000000000000000000000000);
        hevm.warp(initialTime + 1);
        coinSavingsAccount.updateAccumulatedRate(); // Just necessary to check in this test the updated value of chi
        assertEq(coinSavingsAccount.savings(address(proxy)) * coinSavingsAccount.accumulatedRate(), 52499999999999999999317500000000000000000000000);
        this.coinSavingsAccount_withdraw(address(coinJoin), address(coinSavingsAccount), 52.5 ether);
        assertEq(coin.balanceOf(address(this)), 52499999999999999999);
        assertEq(coinSavingsAccount.savings(address(proxy)), 0);
    }

    function testCoinSavingsAccountRounding2() public {
        this.modifyParameters(address(coinSavingsAccount), "savingsRate", uint(1.03434234324 * 10 ** 27));
        uint initialTime = 1;
        hevm.warp(initialTime);
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETHAndGenerateDebt{value: 1 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), safe, 50 ether);
        coin.approve(address(proxy), 50 ether);
        assertEq(coin.balanceOf(address(this)), 50 ether);
        assertEq(coinSavingsAccount.savings(address(this)), 0 ether);
        this.denySAFEModification(address(safeEngine), address(coinJoin)); // Remove safeEngine permission for coinJoin to test it is correctly re-actisafeEnginee in exit
        this.coinSavingsAccount_deposit(address(coinJoin), address(coinSavingsAccount), 50 ether);
        assertEq(coinSavingsAccount.savings(address(proxy)) * coinSavingsAccount.accumulatedRate(), 49999999999999999999993075745400000000000000000);
        assertEq(safeEngine.coinBalance(address(proxy)), mul(50 ether, ONE) - 49999999999999999999993075745400000000000000000);
        this.coinSavingsAccount_withdraw(address(coinJoin), address(coinSavingsAccount), 50 ether);
        // In this case we get the full 50 COIN back as we also use (for the exit) the dust that remained in the proxy COIN balance in the safeEngine
        // The proxy function tries to return the wad amount if there is enough balance to do it
        assertEq(coin.balanceOf(address(this)), 50 ether);
    }

    function testCoinSavingsAccountWithdrawAll() public {
        this.modifyParameters(address(coinSavingsAccount), "savingsRate", uint(1.03434234324 * 10 ** 27));
        uint initialTime = 1;
        hevm.warp(initialTime);
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETHAndGenerateDebt{value: 1 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), safe, 50 ether);
        this.denySAFEModification(address(safeEngine), address(coinJoin)); // Remove safeEngine permission for coinJoin to test it is correctly re-actisafeEnginee in exitAll
        coin.approve(address(proxy), 50 ether);
        this.coinSavingsAccount_deposit(address(coinJoin), address(coinSavingsAccount), 50 ether);
        this.coinSavingsAccount_withdrawAll(address(coinJoin), address(coinSavingsAccount));
        // In this case we get 49.999 COIN back as the returned amount is based purely in the pie amount
        assertEq(coin.balanceOf(address(this)), 49999999999999999999);
    }
}


contract GebIncentivesProxyActionsTest is GebDeployTestBase, ProxyCalls {
    GebSafeManager manager;

    GebProxyRegistry registry;
    RollingDistributionIncentives incentives;
    DSToken rewardToken;

    UniswapV2Factory uniswapFactory;
    UniswapV2Router02 uniswapRouter;
    UniswapV2Pair raiETHPair;
    uint256 initETHRAIPairLiquidity = 5 ether;               // 1250 USD
    uint256 initRAIETHPairLiquidity = 294.672324375E18;      // 1 RAI = 4.242 USD

    bytes32 collateralAuctionType = bytes32("ENGLISH");

    function setUp() override public {
        super.setUp();
        deployStableKeepAuth(collateralAuctionType);

        manager = new GebSafeManager(address(safeEngine));
        DSProxyFactory factory = new DSProxyFactory();
        registry = new GebProxyRegistry(address(factory));
        gebProxyActions = address(new GebProxyActions());
        gebProxyActionsGlobalSettlement = address(new GebProxyActionsGlobalSettlement());
        gebProxyActionsCoinSavingsAccount = address(new GebProxyActionsCoinSavingsAccount());
        gebProxyIncentivesActions = address(new GebProxyIncentivesActions());
        proxy = DSProxy(registry.build());

        // Setup Uniswap
        uniswapFactory = new UniswapV2Factory(address(this));
        raiETHPair = UniswapV2Pair(uniswapFactory.createPair(address(weth), address(coin)));
        uniswapRouter = new UniswapV2Router02(address(uniswapFactory), address(weth));

        // Add pair liquidity
        weth.approve(address(uniswapRouter), uint(-1));
        weth.deposit{value: initETHRAIPairLiquidity}();
        coin.approve(address(uniswapRouter), uint(-1));
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), safe, 100 ether);
        uniswapRouter.addLiquidity(address(weth), address(coin), initETHRAIPairLiquidity, 100 ether, 1 ether, initRAIETHPairLiquidity, address(this), now);

        // zeroing balances
        coin.transfer(address(0), coin.balanceOf(address(this)));
        raiETHPair.transfer(address(0), raiETHPair.balanceOf(address(this)));

        // Setup Incentives
        incentives = new RollingDistributionIncentives(address(raiETHPair), address(col));
        col.mint(address(incentives), 20 ether);
        incentives.newCampaign(10 ether, now + 1, 12 days, 90 days, 500);
        hevm.warp(now + 1);
    }

    function lockedCollateral(bytes32 collateralType, address urn) public view returns (uint lktCollateral) {
        (lktCollateral,) = safeEngine.safes(collateralType, urn);
    }

    function generatedDebt(bytes32 collateralType, address urn) public view returns (uint genDebt) {
        (,genDebt) = safeEngine.safes(collateralType, urn);
    }

    // proxy should retain no balances, except for liquidity mining ownership
    modifier assertProxyEndsWithNoBalance() {
        _;
        assertEq(address(proxy).balance, 0);
        assertEq(coin.balanceOf(address(proxy)), 0);
        assertEq(raiETHPair.balanceOf(address(proxy)), 0);
        assertEq(incentives.rewardToken().balanceOf(address(proxy)), 0);
    }

    function testOpenLockETHGenerateDebtProvideLiquidityUniswap() public assertProxyEndsWithNoBalance {
        assertEq(raiETHPair.balanceOf(address(this)), 0);
        uint initialPairTotalSupply = raiETHPair.totalSupply();

        uint safe = this.openLockETHGenerateDebtProvideLiquidityUniswap{value: 2.5 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), address(uniswapRouter), "ETH", 300 ether, 0.5 ether, [uint(1),1]);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 300 ether);
        assertEq(raiETHPair.balanceOf(address(this)), raiETHPair.totalSupply() - initialPairTotalSupply);
    }

    function testLockETHGenerateDebtProvideLiquidityUniswap() public assertProxyEndsWithNoBalance {
        assertEq(raiETHPair.balanceOf(address(this)), 0);
        uint initialPairTotalSupply = raiETHPair.totalSupply();
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETHGenerateDebtProvideLiquidityUniswap{value: 2.5 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), address(uniswapRouter), safe, 300 ether, 0.5 ether, [uint(1),1]);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 300 ether);
        assertEq(raiETHPair.balanceOf(address(this)), raiETHPair.totalSupply() - initialPairTotalSupply);
    }

    function testProvideLiquidityUniswap() public assertProxyEndsWithNoBalance {
        assertEq(raiETHPair.balanceOf(address(this)), 0);
        uint initialPairTotalSupply = raiETHPair.totalSupply();

        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), safe, 300 ether);
        coin.approve(address(proxy), 300 ether);
        this.provideLiquidityUniswap{value: 2 ether}(address(coinJoin), address(uniswapRouter), 300 ether, [uint(1),1]);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 300 ether);
        assertEq(raiETHPair.balanceOf(address(this)), raiETHPair.totalSupply() - initialPairTotalSupply);
    }

    function testProvideLiquidityStake() public assertProxyEndsWithNoBalance {
        assertEq(raiETHPair.balanceOf(address(this)), 0);
        uint initialPairTotalSupply = raiETHPair.totalSupply();

        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), safe, 300 ether);
        coin.approve(address(proxy), 300 ether);
        this.provideLiquidityStake{value: 2 ether}(address(coinJoin), address(uniswapRouter), address(incentives), 300 ether, [uint(1),1]);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 300 ether);
        assertEq(raiETHPair.balanceOf(address(this)), 0);
        assertEq(raiETHPair.balanceOf(address(incentives)), raiETHPair.totalSupply() - initialPairTotalSupply);
        assertEq(incentives.balanceOf(address(proxy)), raiETHPair.totalSupply() - initialPairTotalSupply);
    }

    function testGenerateDebtAndProvideLiquidityUniswap() public assertProxyEndsWithNoBalance {
        assertEq(raiETHPair.balanceOf(address(this)), 0);
        uint initialPairTotalSupply = raiETHPair.totalSupply();

        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebtAndProvideLiquidityUniswap{value: 2 ether}(address(manager), address(taxCollector), address(coinJoin), address(uniswapRouter), safe, 300 ether, [uint(1),1]);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 300 ether);
        assertEq(raiETHPair.balanceOf(address(this)), raiETHPair.totalSupply() - initialPairTotalSupply);
    }

    function testlockETHGenerateDebtProvideLiquidityStake() public assertProxyEndsWithNoBalance {
        assertEq(raiETHPair.balanceOf(address(this)), 0);
        uint initialPairTotalSupply = raiETHPair.totalSupply();
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        coin.approve(address(proxy), 300 ether);
        this.lockETHGenerateDebtProvideLiquidityStake{value: 2.5 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), address(uniswapRouter), address(incentives), safe, 300 ether, 0.5 ether, [uint(1),1]);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 300 ether);
        assertEq(raiETHPair.balanceOf(address(incentives)), raiETHPair.totalSupply() - initialPairTotalSupply);
        assertEq(incentives.balanceOf(address(proxy)), raiETHPair.totalSupply() - initialPairTotalSupply);
    }

    function testOpenLockETHGenerateDebtProvideLiquidityStake() public assertProxyEndsWithNoBalance {
        assertEq(raiETHPair.balanceOf(address(this)), 0);
        uint initialPairTotalSupply = raiETHPair.totalSupply();
        uint safe = this.openLockETHGenerateDebtProvideLiquidityStake{value: 2.5 ether}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), address(uniswapRouter), address(incentives), "ETH", 300 ether, 0.5 ether, [uint(1),1]);

        assertEq(generatedDebt("ETH", manager.safes(safe)), 300 ether);
        assertEq(raiETHPair.balanceOf(address(incentives)), raiETHPair.totalSupply() - initialPairTotalSupply);
        assertEq(incentives.balanceOf(address(proxy)), raiETHPair.totalSupply() - initialPairTotalSupply);
    }

    function testGenerateDebtAndProvideLiquidityStake() public assertProxyEndsWithNoBalance {
        uint initialPairTotalSupply = raiETHPair.totalSupply();
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        this.generateDebtAndProvideLiquidityStake{value: 2 ether}(address(manager), address(taxCollector), address(coinJoin), address(uniswapRouter), address(incentives), safe, 300 ether, [uint(1),1]);

        assertEq(generatedDebt("ETH", manager.safes(safe)), 300 ether);
        assertEq(incentives.balanceOf(address(proxy)), raiETHPair.totalSupply() - initialPairTotalSupply);
    }

    function testHarvest() public assertProxyEndsWithNoBalance {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebtAndProvideLiquidityStake{value: 2 ether}(address(manager), address(taxCollector), address(coinJoin), address(uniswapRouter), address(incentives), safe, 300 ether, [uint(1),1]);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 300 ether);

        assertTrue(incentives.balanceOf(address(proxy)) > 0);
        hevm.warp(now + 12 days); // campaign over
        this.harvestReward(address(incentives), 1);
        assertTrue(incentives.rewardToken().balanceOf(address(this)) > 4.9999 ether); // 50% remains locked
    }

    function testGetLockedReward() public assertProxyEndsWithNoBalance {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebtAndProvideLiquidityStake{value: 2 ether}(address(manager), address(taxCollector), address(coinJoin), address(uniswapRouter), address(incentives), safe, 300 ether, [uint(1),1]);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 300 ether);

        assertTrue(incentives.balanceOf(address(proxy)) > 0);
        hevm.warp(now + 12 days); // campaign over
        this.harvestReward(address(incentives), 1);
        assertEq(incentives.rewardToken().balanceOf(address(proxy)), 0);

        hevm.warp(now + 90 days);
        this.getLockedReward(address(incentives), 1);

        assertTrue(incentives.rewardToken().balanceOf(address(this)) > 9.9999 ether);
    }

    function testGetRewards() public assertProxyEndsWithNoBalance {

        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebtAndProvideLiquidityStake{value: 2 ether}(address(manager), address(taxCollector), address(coinJoin), address(uniswapRouter), address(incentives), safe, 300 ether, [uint(1),1]);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 300 ether);

        assertTrue(incentives.balanceOf(address(proxy)) > 0);
        hevm.warp(now + 12 days); // campaign over
        this.getRewards(address(incentives), 1);
        assertEq(incentives.rewardToken().balanceOf(address(proxy)), 0);
        assertTrue(incentives.rewardToken().balanceOf(address(this)) > 4.9999 ether); // 50% remains locked

        hevm.warp(now + 90 days); // vesting over
        this.getRewards(address(incentives), 1);

        assertTrue(incentives.rewardToken().balanceOf(address(this)) > 9.9999 ether); // 100%
    }

    function testExitMine() public assertProxyEndsWithNoBalance {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebtAndProvideLiquidityStake{value: 2 ether}(address(manager), address(taxCollector), address(coinJoin), address(uniswapRouter), address(incentives), safe, 300 ether, [uint(1),1]);

        uint balanceLocked = raiETHPair.balanceOf(address(incentives));

        assertTrue(incentives.balanceOf(address(proxy)) > 0);
        hevm.warp(now + 12 days); // campaign over
        this.exitMine(address(incentives));
        assertEq(incentives.rewardToken().balanceOf(address(proxy)), 0);
        assertTrue(incentives.rewardToken().balanceOf(address(this)) > 4.9999 ether); // 50% remains locked
        assertEq(raiETHPair.balanceOf(address(this)), balanceLocked);
    }

    function testWithdrawFromMine() public assertProxyEndsWithNoBalance {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebtAndProvideLiquidityStake{value: 2 ether}(address(manager), address(taxCollector), address(coinJoin), address(uniswapRouter), address(incentives), safe, 300 ether, [uint(1),1]);

        uint lpTokenBalanceBeforeWithdraw = raiETHPair.balanceOf(address(this));
        this.withdrawFromMine(address(incentives), 1 ether);
        assertEq(raiETHPair.balanceOf(address(this)), lpTokenBalanceBeforeWithdraw + 1 ether);
    }

    function testWithdrawAndHarvest() public assertProxyEndsWithNoBalance {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebtAndProvideLiquidityStake{value: 2 ether}(address(manager), address(taxCollector), address(coinJoin), address(uniswapRouter), address(incentives), safe, 300 ether, [uint(1),1]);

        uint lpTokenBalanceBeforeWithdraw = raiETHPair.balanceOf(address(this));
        hevm.warp(now + 12 days); // campaign over
        this.withdrawAndHarvest(address(incentives), 1 ether, 1);
        assertEq(raiETHPair.balanceOf(address(this)), lpTokenBalanceBeforeWithdraw + 1 ether);
        assertEq(incentives.rewardToken().balanceOf(address(proxy)), 0);
        assertTrue(incentives.rewardToken().balanceOf(address(this)) > 4.9999 ether); // 50% remains locked
    }

    function testWithdrawHarvestRemoveLiquidity() public assertProxyEndsWithNoBalance {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebtAndProvideLiquidityStake{value: 2 ether}(address(manager), address(taxCollector), address(coinJoin), address(uniswapRouter), address(incentives), safe, 300 ether, [uint(1),1]);

        uint lpTokenBalanceBeforeWithdraw = raiETHPair.balanceOf(address(this));
        uint ethBalanceBeforeWithdraw = address(this).balance;
        uint coinBalanceBeforeWithdraw = coin.balanceOf(address(this));
        hevm.warp(now + 12 days); // campaign over
        (uint raiAmount, uint ethAmount) = this.withdrawHarvestRemoveLiquidity(address(incentives), address(uniswapRouter), address(coin), 1 ether, 1, [uint(1),1]);
        assertEq(raiETHPair.balanceOf(address(this)), lpTokenBalanceBeforeWithdraw);
        assertEq(incentives.rewardToken().balanceOf(address(proxy)), 0);
        assertTrue(incentives.rewardToken().balanceOf(address(this)) > 4.9999 ether); // 50% remains locked
        assertEq(address(this).balance, ethBalanceBeforeWithdraw + ethAmount);
        assertEq(coin.balanceOf(address(this)), coinBalanceBeforeWithdraw + raiAmount);
    }

    function testStakeInMine() public assertProxyEndsWithNoBalance {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebtAndProvideLiquidityUniswap{value: 2 ether}(address(manager), address(taxCollector), address(coinJoin), address(uniswapRouter), safe, 300 ether, [uint(1),1]);

        raiETHPair.approve(address(proxy), 1 ether);
        this.stakeInMine(address(incentives), 1 ether);
        assertEq(incentives.balanceOf(address(proxy)), 1 ether);
    }

    function testRemoveLiquidityUniswap() public assertProxyEndsWithNoBalance {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebtAndProvideLiquidityUniswap{value: 2 ether}(address(manager), address(taxCollector), address(coinJoin), address(uniswapRouter), safe, 300 ether, [uint(1),1]);

        uint lpTokenBalanceBeforeWithdraw = raiETHPair.balanceOf(address(this));
        uint ethBalanceBeforeWithdraw = address(this).balance;
        uint coinBalanceBeforeWithdraw = coin.balanceOf(address(this));
        raiETHPair.approve(address(proxy), 1 ether);
        (uint raiAmount, uint ethAmount) = this.removeLiquidityUniswap(address(uniswapRouter), address(coin), 1 ether, [uint(1),1]);
        assertEq(raiETHPair.balanceOf(address(this)), lpTokenBalanceBeforeWithdraw - 1 ether);
        assertEq(address(this).balance, ethBalanceBeforeWithdraw + ethAmount);
        assertEq(coin.balanceOf(address(this)), coinBalanceBeforeWithdraw + raiAmount);
    }

    function testWithdrawAndRemoveLiquidity() public assertProxyEndsWithNoBalance {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebtAndProvideLiquidityStake{value: 2 ether}(address(manager), address(taxCollector), address(coinJoin), address(uniswapRouter), address(incentives), safe, 300 ether, [uint(1),1]);

        uint ethBalanceBeforeWithdraw = address(this).balance;
        uint coinBalanceBeforeWithdraw = coin.balanceOf(address(this));
        (uint raiAmount, uint ethAmount) = this.withdrawAndRemoveLiquidity(address(coinJoin), address(incentives), 1 ether, address(uniswapRouter), [uint(1),1]);
        assertEq(address(this).balance, ethBalanceBeforeWithdraw + ethAmount);
        assertEq(coin.balanceOf(address(this)), coinBalanceBeforeWithdraw + raiAmount);
    }

    function testWithdrawRemoveLiquidityRepayDebt() public assertProxyEndsWithNoBalance {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebtAndProvideLiquidityStake{value: 2 ether}(address(manager), address(taxCollector), address(coinJoin), address(uniswapRouter), address(incentives), safe, 300 ether, [uint(1),1]);
        hevm.warp(12 days);
        uint lpTokenBalanceBeforeWithdraw = raiETHPair.balanceOf(address(this));
        uint ethBalanceBeforeWithdraw = address(this).balance;
        uint coinBalanceBeforeWithdraw = coin.balanceOf(address(this));
        this.withdrawRemoveLiquidityRepayDebt(address(manager), address(coinJoin), safe, address(incentives), raiETHPair.balanceOf(address(incentives)), address(uniswapRouter), [uint(1),1]);
        assertEq(raiETHPair.balanceOf(address(this)), lpTokenBalanceBeforeWithdraw);
        assertEq(coinBalanceBeforeWithdraw, coin.balanceOf(address(this)));
        assertTrue(ethBalanceBeforeWithdraw < address(this).balance);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 260000000000000000002);
    }

    function testWithdrawRemoveLiquidityRepayDebtFreeETH() public assertProxyEndsWithNoBalance {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebtAndProvideLiquidityStake{value: 2 ether}(address(manager), address(taxCollector), address(coinJoin), address(uniswapRouter), address(incentives), safe, 300 ether, [uint(1),1]);
        hevm.warp(12 days);
        uint lpTokenBalanceBeforeWithdraw = raiETHPair.balanceOf(address(this));
        uint ethBalanceBeforeWithdraw = address(this).balance;
        uint coinBalanceBeforeWithdraw = coin.balanceOf(address(this));
        this.withdrawRemoveLiquidityRepayDebtFreeETH(address(manager), address(ethJoin), address(coinJoin), safe, address(incentives), raiETHPair.balanceOf(address(incentives)), 0.2 ether, address(uniswapRouter), [uint(1),1]);
        assertEq(raiETHPair.balanceOf(address(this)), lpTokenBalanceBeforeWithdraw);
        assertEq(coinBalanceBeforeWithdraw, coin.balanceOf(address(this)));
        assertTrue(ethBalanceBeforeWithdraw < address(this).balance);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 260000000000000000002);
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 1.8 ether);
    }

    function testExitAndRemoveLiquidity() public assertProxyEndsWithNoBalance {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebtAndProvideLiquidityStake{value: 2 ether}(address(manager), address(taxCollector), address(coinJoin), address(uniswapRouter), address(incentives), safe, 300 ether, [uint(1),1]);
        hevm.warp(12 days);
        uint lpTokenBalanceBeforeWithdraw = raiETHPair.balanceOf(address(this));
        uint ethBalanceBeforeWithdraw = address(this).balance;
        uint coinBalanceBeforeWithdraw = coin.balanceOf(address(this));
        (uint raiAmount, uint ethAmount) = this.exitAndRemoveLiquidity(address(coinJoin), address(incentives), address(uniswapRouter), [uint(1),1]);
        assertEq(raiETHPair.balanceOf(address(this)), lpTokenBalanceBeforeWithdraw);
        assertTrue(incentives.rewardToken().balanceOf(address(this)) > 4.9999 ether); // 50% remains locked
        assertEq(address(this).balance, ethBalanceBeforeWithdraw + ethAmount);
        assertEq(coin.balanceOf(address(this)), coinBalanceBeforeWithdraw + raiAmount);
    }

    function testExitRemoveLiquidityRepayDebt() public assertProxyEndsWithNoBalance {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebtAndProvideLiquidityStake{value: 2 ether}(address(manager), address(taxCollector), address(coinJoin), address(uniswapRouter), address(incentives), safe, 300 ether, [uint(1),1]);
        hevm.warp(12 days);
        uint lpTokenBalanceBeforeWithdraw = raiETHPair.balanceOf(address(this));
        uint ethBalanceBeforeWithdraw = address(this).balance;
        uint coinBalanceBeforeWithdraw = coin.balanceOf(address(this));
        this.exitRemoveLiquidityRepayDebt(address(manager), address(coinJoin), safe, address(incentives), address(uniswapRouter), [uint(1),1]);
        assertEq(raiETHPair.balanceOf(address(this)), lpTokenBalanceBeforeWithdraw);
        assertEq(coinBalanceBeforeWithdraw, coin.balanceOf(address(this)));
        assertTrue(incentives.rewardToken().balanceOf(address(this)) > 4.9999 ether); // 50% remains locked
        assertTrue(ethBalanceBeforeWithdraw < address(this).balance);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 260000000000000000002);
    }

    function testExitRemoveLiquidityRepayDebtFreeETH() public assertProxyEndsWithNoBalance {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebtAndProvideLiquidityStake{value: 2 ether}(address(manager), address(taxCollector), address(coinJoin), address(uniswapRouter), address(incentives), safe, 300 ether, [uint(1),1]);
        hevm.warp(12 days);
        uint lpTokenBalanceBeforeWithdraw = raiETHPair.balanceOf(address(this));
        uint ethBalanceBeforeWithdraw = address(this).balance;
        uint coinBalanceBeforeWithdraw = coin.balanceOf(address(this));
        this.exitRemoveLiquidityRepayDebtFreeETH(address(manager), address(ethJoin), address(coinJoin), safe, address(incentives), 0.2 ether, address(uniswapRouter), [uint(1),1]);
        assertEq(raiETHPair.balanceOf(address(this)), lpTokenBalanceBeforeWithdraw);
        assertEq(coinBalanceBeforeWithdraw, coin.balanceOf(address(this)));
        assertTrue(ethBalanceBeforeWithdraw < address(this).balance);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 260000000000000000002);
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 1.8 ether);
    }
}

contract GebProxyLeverageActionsTest is GebDeployTestBase, ProxyCalls {
    GebSafeManager manager;

    GebProxyRegistry registry;
    RollingDistributionIncentives incentives;
    DSToken rewardToken;

    UniswapV2Factory uniswapFactory;
    UniswapV2Router02 uniswapRouter;
    UniswapV2Pair raiETHPair;
    uint256 initETHRAIPairLiquidity = 5 ether;               // 1250 USD
    uint256 initRAIETHPairLiquidity = 294.672324375E18;      // 1 RAI = 4.242 USD

    bytes32 collateralAuctionType = bytes32("ENGLISH");

    function setUp() override public {
        super.setUp();
        deployStableKeepAuth(collateralAuctionType);

        manager = new GebSafeManager(address(safeEngine));
        DSProxyFactory factory = new DSProxyFactory();
        registry = new GebProxyRegistry(address(factory));
        gebProxyActions = address(new GebProxyActions());
        gebProxyActionsGlobalSettlement = address(new GebProxyActionsGlobalSettlement());
        gebProxyActionsCoinSavingsAccount = address(new GebProxyActionsCoinSavingsAccount());
        gebProxyIncentivesActions = address(new GebProxyIncentivesActions());
        gebProxyLeverageActions = address(new GebProxyLeverageActions());
        proxy = DSProxy(registry.build());

        // Setup Uniswap
        uniswapFactory = new UniswapV2Factory(address(this));
        raiETHPair = UniswapV2Pair(uniswapFactory.createPair(address(weth), address(coin)));
        uniswapRouter = new UniswapV2Router02(address(uniswapFactory), address(weth));

        // Add pair liquidity
        weth.approve(address(uniswapRouter), uint(-1));
        weth.deposit{value: initETHRAIPairLiquidity}();
        coin.approve(address(uniswapRouter), uint(-1));
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        this.generateDebt(address(manager), address(taxCollector), address(coinJoin), safe, 100 ether);
        uniswapRouter.addLiquidity(address(weth), address(coin), initETHRAIPairLiquidity, 100 ether, 1 ether, initRAIETHPairLiquidity, address(this), now);

        // zeroing balances
        coin.transfer(address(0), coin.balanceOf(address(this)));
        raiETHPair.transfer(address(0), raiETHPair.balanceOf(address(this)));

        // Setup Incentives
        incentives = new RollingDistributionIncentives(address(raiETHPair), address(col));
        col.mint(address(incentives), 20 ether);
        incentives.newCampaign(10 ether, now + 1, 12 days, 90 days, 500);
        hevm.warp(now + 1);
    }

    function lockedCollateral(bytes32 collateralType, address urn) public view returns (uint lktCollateral) {
        (lktCollateral,) = safeEngine.safes(collateralType, urn);
    }

    function generatedDebt(bytes32 collateralType, address urn) public view returns (uint genDebt) {
        (,genDebt) = safeEngine.safes(collateralType, urn);
    }

    // proxy should retain no balances, except for liquidity mining ownership
    modifier assertProxyEndsWithNoBalance() {
        _;
        assertEq(address(proxy).balance, 0);
        assertEq(coin.balanceOf(address(proxy)), 0);
        assertEq(raiETHPair.balanceOf(address(proxy)), 0);
        assertEq(incentives.rewardToken().balanceOf(address(proxy)), 0);
    }

    function testOpenLockETHLeverage() public assertProxyEndsWithNoBalance {
        uint256 safe = this.openLockETHLeverage{value: 1 ether}(address(raiETHPair), address(manager), address(ethJoin), address(taxCollector), address(coinJoin), address(weth), gebProxyLeverageActions, "ETH", 2200); // 2.2x leverage
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 2.2 ether);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 31673969276249802038);
    }

    function testLockETHLeverage() public assertProxyEndsWithNoBalance {
        uint256 safe = this.openSAFE(address(manager), "ETH", address(proxy));

        this.lockETHLeverage{value: 1 ether}(address(raiETHPair), address(manager), address(ethJoin), address(taxCollector), address(coinJoin), address(weth), gebProxyLeverageActions, "ETH", safe, 2200); // 2.2x leverage
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 2.2 ether);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 31673969276249802038);
    }

    function testFlashLeverage() public assertProxyEndsWithNoBalance {
        uint256 safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 1 ether}(address(manager), address(ethJoin), safe);
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 1 ether);


        this.flashLeverage(address(raiETHPair), address(manager), address(ethJoin), address(taxCollector), address(coinJoin), address(weth), gebProxyLeverageActions, "ETH", safe, 2200); // 2.2x leverage
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 2.2 ether);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 31673969276249802038);
    }

    function testFlashDeleverage() public assertProxyEndsWithNoBalance {
        uint256 safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 1 ether}(address(manager), address(ethJoin), safe);
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 1 ether);

        this.flashLeverage(address(raiETHPair), address(manager), address(ethJoin), address(taxCollector), address(coinJoin), address(weth), gebProxyLeverageActions, "ETH", safe, 2200); // 2.2x leverage
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 2.2 ether);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 31673969276249802038);

        this.flashDeleverage(address(raiETHPair), address(manager), address(ethJoin), address(taxCollector), address(coinJoin), address(weth), gebProxyLeverageActions, "ETH", safe);
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 992767469912244255); // almost 1 eth (flashswap fees)
        assertEq(generatedDebt("ETH", manager.safes(safe)), 0);
    }

    function testFlashDeleverageFreeETH() public assertProxyEndsWithNoBalance {
        uint256 safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 1 ether}(address(manager), address(ethJoin), safe);
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 1 ether);

        this.flashLeverage(address(raiETHPair), address(manager), address(ethJoin), address(taxCollector), address(coinJoin), address(weth), gebProxyLeverageActions, "ETH", safe, 2200); // 2.2x leverage
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 2.2 ether);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 31673969276249802038);

        this.flashDeleverageFreeETH(address(raiETHPair), address(manager), address(ethJoin), address(taxCollector), address(coinJoin), address(weth), gebProxyLeverageActions, "ETH", safe, 0.5 ether);
        assertEq(lockedCollateral("ETH", manager.safes(safe)), 992767469912244255 - 0.5 ether); // almost 1 eth (flashswap fees) - 0.5 eth freed
        assertEq(generatedDebt("ETH", manager.safes(safe)), 0);
    }
}
