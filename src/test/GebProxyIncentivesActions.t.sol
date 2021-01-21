pragma solidity 0.6.7;

import "ds-test/test.sol";
import "ds-weth/weth9.sol";
import "ds-token/token.sol";

import {GebProxyActions, GebProxyIncentivesActions} from "../GebProxyIncentivesActions.sol";

import {Feed, GebDeployTestBase, EnglishCollateralAuctionHouse} from "geb-deploy/test/GebDeploy.t.base.sol";
import {DGD, GNT} from "./tokens.sol";
import {CollateralJoin3, CollateralJoin4} from "geb-deploy/AdvancedTokenAdapters.sol";
import {DSValue} from "ds-value/value.sol";
import {GebSafeManager} from "geb-safe-manager/GebSafeManager.sol";
import {GetSafes} from "geb-safe-manager/GetSafes.sol";
import {GebProxyRegistry, DSProxyFactory, DSProxy} from "geb-proxy-registry/GebProxyRegistry.sol";
import {StakingRewards} from "geb-incentives/uniswap/StakingRewards.sol";

import "../uni/UniswapV2Factory.sol";
import "../uni/UniswapV2Pair.sol";
import "../uni/UniswapV2Router02.sol";

contract ProxyCalls {
    DSProxy proxy;
    address gebProxyIncentivesActions;

    function transfer(address, address, uint256) public {
        proxy.execute(gebProxyIncentivesActions, msg.data);
    }

    function openSAFE(address, bytes32, address) public returns (uint safe) {
        bytes memory response = proxy.execute(gebProxyIncentivesActions, msg.data);
        assembly {
            safe := mload(add(response, 0x20))
        }
    }

    function lockETH(address, address, uint) public payable {
        (bool success,) = address(proxy).call{value: msg.value}(abi.encodeWithSignature("execute(address,bytes)", gebProxyIncentivesActions, msg.data));
        require(success, "");
    }

    function generateDebt(address, address, address, uint, uint) public {
        proxy.execute(gebProxyIncentivesActions, msg.data);
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

    function getRewards(address pool) public {
        proxy.execute(gebProxyIncentivesActions, abi.encodeWithSignature("getRewards(address)", pool));
    }

    function exitMine(address) public {
        proxy.execute(gebProxyIncentivesActions, msg.data);
    }

    function migrateCampaign(address, address) public {
        proxy.execute(gebProxyIncentivesActions, msg.data);
    }

    function withdrawFromMine(address, uint) public {
        proxy.execute(gebProxyIncentivesActions, msg.data);
    }

    function withdrawAndHarvest(address, uint) public {
        proxy.execute(gebProxyIncentivesActions, msg.data);
    }


    function removeLiquidityUniswap(address, address, uint, uint[2] memory) public returns (uint amountA, uint amountB) {
        bytes memory response = proxy.execute(gebProxyIncentivesActions, msg.data);
        assembly {
            amountA := mload(add(response, 0x20))
            amountB := mload(add(response, 0x40))
        }
    }

    function withdrawHarvestRemoveLiquidity(address, address, address, uint, uint[2] memory) public returns (uint amountA, uint amountB) {
        bytes memory response = proxy.execute(gebProxyIncentivesActions, msg.data);
        assembly {
            amountA := mload(add(response, 0x20))
            amountB := mload(add(response, 0x40))
        }
    }

    function stakeInMine(address, uint) public {
        proxy.execute(gebProxyIncentivesActions, msg.data);
    }

    function withdrawAndRemoveLiquidity(address, address, uint, address, uint[2] memory) public returns (uint amountA, uint amountB) {
        bytes memory response = proxy.execute(gebProxyIncentivesActions, msg.data);
        assembly {
            amountA := mload(add(response, 0x20))
            amountB := mload(add(response, 0x40))
        }
    }

    function exitAndRemoveLiquidity(address, address, address, uint[2] memory) public returns (uint amountA, uint amountB) {
        bytes memory response = proxy.execute(gebProxyIncentivesActions, msg.data);
        assembly {
            amountA := mload(add(response, 0x20))
            amountB := mload(add(response, 0x40))
        }
    }

    function exitRemoveLiquidityRepayDebt(address, address, uint, address, address, uint[2] memory) public {
        proxy.execute(gebProxyIncentivesActions, msg.data);
    }

    function exitRemoveLiquidityRepayDebtFreeETH(address, address, address, uint, address, uint, address, uint[2] memory) public {
        proxy.execute(gebProxyIncentivesActions, msg.data);
    }

    function withdrawRemoveLiquidityRepayDebt(address, address, uint, address, uint, address, uint[2] memory) public {
        proxy.execute(gebProxyIncentivesActions, msg.data);
    }

    function withdrawRemoveLiquidityRepayDebtFreeETH(address, address, address, uint, address, uint, uint, address, uint[2] memory) public {
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

    function provideLiquidityUniswap(address, address, uint, uint[2] memory) public payable {
        (bool success,) = address(proxy).call{value: msg.value}(abi.encodeWithSignature("execute(address,bytes)", gebProxyIncentivesActions, msg.data));
        require(success, "");
    }

    function provideLiquidityStake(address, address, address, uint, uint[2] memory) public payable {
        (bool success,) = address(proxy).call{value: msg.value}(abi.encodeWithSignature("execute(address,bytes)", gebProxyIncentivesActions, msg.data));
        require(success, "");
    }
}

contract GebIncentivesProxyActionsTest is GebDeployTestBase, ProxyCalls {
    GebSafeManager manager;

    GebProxyRegistry registry;
    StakingRewards incentives;
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
        coin.transfer(address(1), coin.balanceOf(address(this)));
        raiETHPair.transfer(address(0), raiETHPair.balanceOf(address(this)));

        // Setup Incentives
        incentives = new StakingRewards(address(this), address(col), address(raiETHPair), 12 days);
        col.mint(address(incentives), 20 ether);
        incentives.notifyRewardAmount(10 ether);
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
        assertEq(incentives.rewardsToken().balanceOf(address(proxy)), 0);
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

    function testGetRewards() public assertProxyEndsWithNoBalance {

        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebtAndProvideLiquidityStake{value: 2 ether}(address(manager), address(taxCollector), address(coinJoin), address(uniswapRouter), address(incentives), safe, 300 ether, [uint(1),1]);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 300 ether);
        hevm.warp(now + 6 days); // halfway through campaign
        this.getRewards(address(incentives));
        assertTrue(incentives.rewardsToken().balanceOf(address(this)) > 4.9999 ether); 

        assertTrue(incentives.balanceOf(address(proxy)) > 0);
        hevm.warp(now + 6 days); // campaign over
        this.getRewards(address(incentives));
        assertEq(incentives.rewardsToken().balanceOf(address(proxy)), 0);
        assertTrue(incentives.rewardsToken().balanceOf(address(this)) > 9.9999 ether); 
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
        assertEq(incentives.rewardsToken().balanceOf(address(proxy)), 0);
        assertTrue(incentives.rewardsToken().balanceOf(address(this)) > 9.9999 ether); 
        assertEq(raiETHPair.balanceOf(address(this)), balanceLocked);
    }

    function testMigrateCampaign() public assertProxyEndsWithNoBalance {
        uint safe = this.openSAFE(address(manager), "ETH", address(proxy));
        this.lockETH{value: 2 ether}(address(manager), address(ethJoin), safe);
        assertEq(coin.balanceOf(address(this)), 0);
        this.generateDebtAndProvideLiquidityStake{value: 2 ether}(address(manager), address(taxCollector), address(coinJoin), address(uniswapRouter), address(incentives), safe, 300 ether, [uint(1),1]);

        uint balanceLocked = raiETHPair.balanceOf(address(incentives));

        assertTrue(incentives.balanceOf(address(proxy)) > 0);
        hevm.warp(now + 12 days); // campaign over

        StakingRewards newCampaign = new StakingRewards(address(this), address(col), address(raiETHPair), 12 days);
        col.mint(address(newCampaign), 10 ether);
        incentives.notifyRewardAmount(10 ether);

        this.migrateCampaign(address(incentives), address(newCampaign));
        assertEq(incentives.rewardsToken().balanceOf(address(proxy)), 0);
        assertTrue(incentives.rewardsToken().balanceOf(address(this)) > 9.9999 ether);
        assertEq(raiETHPair.balanceOf(address(this)), 0);
        assertEq(raiETHPair.balanceOf(address(newCampaign)), balanceLocked);
        assertEq(newCampaign.balanceOf(address(proxy)), balanceLocked);
        assertEq(incentives.rewardsToken().balanceOf(address(proxy)), 0);
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
        this.withdrawAndHarvest(address(incentives), 1 ether);
        assertEq(raiETHPair.balanceOf(address(this)), lpTokenBalanceBeforeWithdraw + 1 ether);
        assertEq(incentives.rewardsToken().balanceOf(address(proxy)), 0);
        assertTrue(incentives.rewardsToken().balanceOf(address(this)) > 9.9999 ether); 
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
        (uint raiAmount, uint ethAmount) = this.withdrawHarvestRemoveLiquidity(address(incentives), address(uniswapRouter), address(coin), 1 ether, [uint(1),1]);
        assertEq(raiETHPair.balanceOf(address(this)), lpTokenBalanceBeforeWithdraw);
        assertEq(incentives.rewardsToken().balanceOf(address(proxy)), 0);
        assertTrue(incentives.rewardsToken().balanceOf(address(this)) > 9.9999 ether); 
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
        assertTrue(incentives.rewardsToken().balanceOf(address(this)) > 9.9999 ether); 
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
        assertTrue(incentives.rewardsToken().balanceOf(address(this)) > 9.9999 ether);
        assertTrue(ethBalanceBeforeWithdraw < address(this).balance);
        assertEq(generatedDebt("ETH", manager.safes(safe)), 260000000000000000002);
    }
}