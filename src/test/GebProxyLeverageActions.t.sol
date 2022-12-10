
pragma solidity 0.6.7;

import "ds-test/test.sol";
import "./weth9.sol";
import "ds-token/token.sol";

import {GebProxyActions, GebProxyLeverageActions} from "../GebProxyLeverageActions.sol";

import {Feed, GebDeployTestBase, EnglishCollateralAuctionHouse} from "geb-deploy/test/GebDeploy.t.base.sol";
import {DGD, GNT} from "./tokens.sol";
import {CollateralJoin3, CollateralJoin4} from "geb-deploy/AdvancedTokenAdapters.sol";
import {DSValue} from "ds-value/value.sol";
import {GebSafeManager} from "geb-safe-manager/GebSafeManager.sol";
import {GetSafes} from "geb-safe-manager/GetSafes.sol";
import {GebProxyRegistry, DSProxyFactory, DSProxy} from "geb-proxy-registry/GebProxyRegistry.sol";

import "../external/uni-v2/UniswapV2Factory.sol";
import "../external/uni-v2/UniswapV2Pair.sol";
import "../external/uni-v2/UniswapV2Router02.sol";

contract ProxyCalls {
    DSProxy proxy;
    address gebProxyLeverageActions;

    function transfer(address, address, uint256) public {
        proxy.execute(gebProxyLeverageActions, msg.data);
    }

    function openSAFE(address, bytes32, address) public returns (uint safe) {
        bytes memory response = proxy.execute(gebProxyLeverageActions, msg.data);
        assembly {
            safe := mload(add(response, 0x20))
        }
    }

    function lockETH(address, address, uint) public payable {
        (bool success,) = address(proxy).call{value: msg.value}(abi.encodeWithSignature("execute(address,bytes)", gebProxyLeverageActions, msg.data));
        require(success, "");
    }

    function generateDebt(address, address, address, uint, uint) public {
        proxy.execute(gebProxyLeverageActions, msg.data);
    }

    function openLockETHLeverage(address, address, address, address, address, address, address, bytes32, uint) public payable returns (uint safe) {
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

    function lockETHLeverage(address, address, address, address, address, address, address, bytes32, uint, uint) public payable {
        (bool success,) = address(proxy).call{value: msg.value}(abi.encodeWithSignature("execute(address,bytes)", gebProxyLeverageActions, msg.data));
        require(success, "");
    }

    function flashLeverage(address, address, address, address, address, address, address, bytes32, uint, uint) public {
        (bool success,) = address(proxy).call(abi.encodeWithSignature("execute(address,bytes)", gebProxyLeverageActions, msg.data));
        require(success, "");
    }

    function flashDeleverage(address, address, address, address, address, address, address, bytes32, uint) public {
        (bool success,) = address(proxy).call(abi.encodeWithSignature("execute(address,bytes)", gebProxyLeverageActions, msg.data));
        require(success, "");
    }

    function flashDeleverageFreeETH(address, address, address, address, address, address, address, bytes32, uint, uint) public {
        (bool success,) = address(proxy).call(abi.encodeWithSignature("execute(address,bytes)", gebProxyLeverageActions, msg.data));
        require(success, "");
    }
}

contract GebProxyLeverageActionsTest is GebDeployTestBase, ProxyCalls {
    GebSafeManager manager;

    GebProxyRegistry registry;
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
        coin.transfer(address(1), coin.balanceOf(address(this)));
        raiETHPair.transfer(address(0), raiETHPair.balanceOf(address(this)));
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