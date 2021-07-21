pragma solidity 0.6.7;

import "ds-test/test.sol";
import "ds-token/token.sol";
import "ds-weth/weth9.sol";

import {SAFEEngine} from 'geb/SAFEEngine.sol';
import {Coin} from 'geb/Coin.sol';
import {LiquidationEngine} from 'geb/LiquidationEngine.sol';
import {AccountingEngine} from 'geb/AccountingEngine.sol';
import {TaxCollector} from 'geb/TaxCollector.sol';
import {BasicCollateralJoin, CoinJoin} from 'geb/BasicTokenAdapters.sol';
import {OracleRelayer} from 'geb/OracleRelayer.sol';
import {EnglishCollateralAuctionHouse} from 'geb/CollateralAuctionHouse.sol';
import {GebSafeManager} from "geb-safe-manager/GebSafeManager.sol";

import {CErc20, CToken} from "geb-safe-saviours/integrations/compound/CErc20.sol";
import {ComptrollerG2} from "geb-safe-saviours/integrations/compound/ComptrollerG2.sol";
import {Unitroller} from "geb-safe-saviours/integrations/compound/Unitroller.sol";
import {WhitePaperInterestRateModel} from "geb-safe-saviours/integrations/compound/WhitePaperInterestRateModel.sol";
import {PriceOracle} from "geb-safe-saviours/integrations/compound/PriceOracle.sol";

import "geb-safe-saviours/integrations/uniswap/uni-v2/UniswapV2Factory.sol";
import "geb-safe-saviours/integrations/uniswap/uni-v2/UniswapV2Pair.sol";
import "geb-safe-saviours/integrations/uniswap/uni-v2/UniswapV2Router02.sol";

import "geb-safe-saviours/integrations/uniswap/liquidity-managers/UniswapV2LiquidityManager.sol";
import "geb-safe-saviours/integrations/uniswap/liquidity-managers/UniswapV3LiquidityManager.sol";

import {SaviourCRatioSetter} from "geb-safe-saviours/SaviourCRatioSetter.sol";
import {SAFESaviourRegistry} from "geb-safe-saviours/SAFESaviourRegistry.sol";

import {NativeUnderlyingUniswapV2SafeSaviour} from "geb-safe-saviours/saviours/NativeUnderlyingUniswapV2SafeSaviour.sol";

import {CompoundSystemCoinSafeSaviour} from "geb-safe-saviours/saviours/CompoundSystemCoinSafeSaviour.sol";

import {GebProxyRegistry, DSProxyFactory, DSProxy} from "geb-proxy-registry/GebProxyRegistry.sol";
import {GebProxyActions} from "../GebProxyActions.sol";
import {GebProxySaviourActions} from "../GebProxySaviourActions.sol";

abstract contract Hevm {
    function warp(uint256) virtual public;
}
contract CompoundPriceOracle is PriceOracle {
    uint256 price;

    function setPrice(uint256 newPrice) public {
        price = newPrice;
    }

    function getUnderlyingPrice(CToken cToken) override external view returns (uint) {
        return price;
    }
}
contract MockMedianizer {
    uint256 public price;
    bool public validPrice;
    uint public lastUpdateTime;
    address public priceSource;

    constructor(uint256 price_, bool validPrice_) public {
        price = price_;
        validPrice = validPrice_;
        lastUpdateTime = now;
    }
    function updatePriceSource(address priceSource_) external {
        priceSource = priceSource_;
    }
    function changeValidity() external {
        validPrice = !validPrice;
    }
    function updateCollateralPrice(uint256 price_) external {
        price = price_;
        lastUpdateTime = now;
    }
    function read() external view returns (uint256) {
        return price;
    }
    function getResultWithValidity() external view returns (uint256, bool) {
        return (price, validPrice);
    }
}
contract TestSAFEEngine is SAFEEngine {
    uint256 constant RAY = 10 ** 27;

    constructor() public {}

    function mint(address usr, uint wad) public {
        coinBalance[usr] += wad * RAY;
        globalDebt += wad * RAY;
    }
    function balanceOf(address usr) public view returns (uint) {
        return uint(coinBalance[usr] / RAY);
    }
}
contract TestAccountingEngine is AccountingEngine {
    constructor(address safeEngine, address surplusAuctionHouse, address debtAuctionHouse)
        public AccountingEngine(safeEngine, surplusAuctionHouse, debtAuctionHouse) {}

    function totalDeficit() public view returns (uint) {
        return safeEngine.debtBalance(address(this));
    }
    function totalSurplus() public view returns (uint) {
        return safeEngine.coinBalance(address(this));
    }
    function preAuctionDebt() public view returns (uint) {
        return subtract(subtract(totalDeficit(), totalQueuedDebt), totalOnAuctionDebt);
    }
}

contract ProxyCalls {
    DSProxy proxy;
    address gebProxyActions;
    address gebProxySaviourActions;

    function openSAFE(address, bytes32, address) public returns (uint safe) {
        bytes memory response = proxy.execute(gebProxyActions, msg.data);
        assembly {
            safe := mload(add(response, 0x20))
        }
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

    function transferTokensToCaller(address[] memory) public {
        proxy.execute(gebProxySaviourActions, msg.data);
    }

    function protectSAFE(
        address,
        address,
        uint,
        address
    ) public {
        proxy.execute(gebProxySaviourActions, msg.data);
    }

    function setDesiredCollateralizationRatio(
        address cRatioSetter,
        bytes32 collateralType,
        uint256 safe,
        uint256 cRatio
    ) public {
        proxy.execute(gebProxySaviourActions, msg.data);
    }

    function deposit(
        bool,
        address,
        address,
        address,
        uint256,
        uint256
    ) public {
        proxy.execute(gebProxySaviourActions, msg.data);
    }

    function setDesiredCRatioDeposit(
        bool,
        address,
        address,
        address,
        address,
        uint256,
        uint256,
        uint256
    ) public {
        proxy.execute(gebProxySaviourActions, msg.data);
    }

    function withdraw(
        bool,
        address,
        address,
        uint256,
        uint256,
        address
    ) public {
        proxy.execute(gebProxySaviourActions, msg.data);
    }

    function setDesiredCRatioWithdraw(
        bool,
        address,
        address,
        address,
        uint256,
        uint256,
        uint256,
        address
    ) public {
        proxy.execute(gebProxySaviourActions, msg.data);
    }

    function protectSAFEDeposit(
        bool,
        address,
        address,
        address,
        address,
        uint256,
        uint256
    ) public {
        proxy.execute(gebProxySaviourActions, msg.data);
    }

    function protectSAFESetDesiredCRatioDeposit(
        bool,
        address,
        address,
        address,
        address,
        address,
        uint256,
        uint256,
        uint256
    ) public {
        proxy.execute(gebProxySaviourActions, msg.data);
    }

    function withdrawUncoverSAFE(
        bool,
        address,
        address,
        address,
        address,
        uint256,
        uint256,
        address
    ) public {
        proxy.execute(gebProxySaviourActions, msg.data);
    }

    function withdrawProtectSAFEDeposit(
        bool,
        bool,
        address,
        address,
        address,
        address,
        address,
        uint256,
        uint256,
        uint256,
        address
    ) public {
        proxy.execute(gebProxySaviourActions, msg.data);
    }

    function getReservesAndUncover(address, address, address, uint256, address) public {
        proxy.execute(gebProxySaviourActions, msg.data);
    }
}

contract GebProxySaviourActionsTest is DSTest, ProxyCalls {
    Hevm hevm;

    UniswapV2Factory uniswapFactory;
    UniswapV2Router02 uniswapRouter;
    UniswapV2LiquidityManager liquidityManager;
    UniswapV2Pair raiWETHPair;

    TestSAFEEngine safeEngine;
    TestAccountingEngine accountingEngine;
    LiquidationEngine liquidationEngine;
    OracleRelayer oracleRelayer;
    TaxCollector taxCollector;

    BasicCollateralJoin collateralJoin;

    CoinJoin coinJoin;
    WETH9_ weth;

    CoinJoin systemCoinJoin;
    EnglishCollateralAuctionHouse collateralAuctionHouse;

    GebSafeManager safeManager;

    MockMedianizer systemCoinOracle;
    CompoundPriceOracle compoundSysCoinOracle;
    MockMedianizer ethFSM;
    MockMedianizer ethMedian;

    Coin systemCoin;

    CompoundSystemCoinSafeSaviour compoundSaviour;
    NativeUnderlyingUniswapV2SafeSaviour uniswapSaviour;

    SaviourCRatioSetter cRatioSetter;
    SAFESaviourRegistry saviourRegistry;

    CErc20 cRAI;
    ComptrollerG2 comptroller;
    Unitroller unitroller;
    WhitePaperInterestRateModel interestRateModel;

    GebProxyRegistry registry;

    address me;

    // Compound Params
    uint256 systemCoinsToMint = 1000000 * 10**18;
    uint256 systemCoinPrice = 1 ether;

    uint256 baseRatePerYear = 10**17;
    uint256 multiplierPerYear = 45 * 10**17;
    uint256 liquidationIncentive = 1 ether;
    uint256 closeFactor = 0.051 ether;
    uint256 maxAssets = 10;
    uint256 exchangeRate = 1 ether;

    uint8 cTokenDecimals = 8;

    string cTokenSymbol = "cRAI";
    string cTokenName = "cRAI";

    // General saviour params
    uint256 saveCooldown = 1 days;
    uint256 keeperPayout = 0.5 ether;
    uint256 minKeeperPayoutValue = 1000 ether;
    uint256 payoutToSAFESize = 40;

    // Uniswap Params
    uint256 initTokenAmount  = 100000 ether;
    uint256 initETHUSDPrice  = 250 * 10 ** 18;
    uint256 initRAIUSDPrice  = 4.242 * 10 ** 18;

    uint256 initETHRAIPairLiquidity = 5 ether;               // 1250 USD
    uint256 initRAIETHPairLiquidity = 294.672324375E18;      // 1 RAI = 4.242 USD

    // CRatio setter params
    uint256 defaultDesiredCollateralizationRatio = 200;
    uint256 minDesiredCollateralizationRatio = 155;

    // Core system params
    uint256 minCRatio = 1.5 ether;
    uint256 ethToMint = 5000 ether;
    uint256 ethCeiling = uint(-1);
    uint256 ethLiquidationPenalty = 1 ether;

    uint256 defaultLiquidityMultiplier = 50;
    uint256 defaultCollateralAmount = 40 ether;
    uint256 defaultTokenAmount = 100 ether;

    bool isSystemCoinToken0;

    address[] tokenList;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        // System coin
        systemCoin = new Coin("RAI", "RAI", 1);
        systemCoin.mint(address(this), systemCoinsToMint);
        systemCoinOracle = new MockMedianizer(systemCoinPrice, true);

        // Compound setup
        compoundSysCoinOracle = new CompoundPriceOracle();
        compoundSysCoinOracle.setPrice(systemCoinPrice);

        interestRateModel = new WhitePaperInterestRateModel(baseRatePerYear, multiplierPerYear);
        unitroller  = new Unitroller();
        comptroller = new ComptrollerG2();

        unitroller._setPendingImplementation(address(comptroller));
        comptroller._become(unitroller);

        comptroller._setLiquidationIncentive(liquidationIncentive);
        comptroller._setCloseFactor(closeFactor);
        comptroller._setMaxAssets(maxAssets);
        comptroller._setPriceOracle(compoundSysCoinOracle);

        cRAI = new CErc20();
        cRAI.initialize(
            address(systemCoin),
            comptroller,
            interestRateModel,
            exchangeRate,
            cTokenName,
            cTokenSymbol,
            cTokenDecimals
        );
        comptroller._supportMarket(cRAI);

        // Core system
        safeEngine = new TestSAFEEngine();

        ethFSM    = new MockMedianizer(initETHUSDPrice, true);
        ethMedian = new MockMedianizer(initETHUSDPrice, true);
        ethFSM.updatePriceSource(address(ethMedian));

        oracleRelayer = new OracleRelayer(address(safeEngine));
        oracleRelayer.modifyParameters("redemptionPrice", ray(systemCoinPrice));

        oracleRelayer.modifyParameters("eth", "orcl", address(ethFSM));
        oracleRelayer.modifyParameters("eth", "safetyCRatio", ray(minCRatio));
        oracleRelayer.modifyParameters("eth", "liquidationCRatio", ray(minCRatio));

        safeEngine.addAuthorization(address(oracleRelayer));

        accountingEngine = new TestAccountingEngine(
          address(safeEngine), address(0x1), address(0x2)
        );
        safeEngine.addAuthorization(address(accountingEngine));

        taxCollector = new TaxCollector(address(safeEngine));
        taxCollector.initializeCollateralType("eth");
        taxCollector.modifyParameters("primaryTaxReceiver", address(accountingEngine));
        safeEngine.addAuthorization(address(taxCollector));

        liquidationEngine = new LiquidationEngine(address(safeEngine));
        liquidationEngine.modifyParameters("accountingEngine", address(accountingEngine));

        safeEngine.addAuthorization(address(liquidationEngine));
        accountingEngine.addAuthorization(address(liquidationEngine));

        weth = new WETH9_();
        weth.deposit{value: initTokenAmount}();

        safeEngine.initializeCollateralType("eth");

        collateralJoin = new BasicCollateralJoin(address(safeEngine), "eth", address(weth));

        coinJoin = new CoinJoin(address(safeEngine), address(systemCoin));
        systemCoin.addAuthorization(address(coinJoin));

        safeEngine.addAuthorization(address(collateralJoin));

        safeEngine.modifyParameters("eth", "debtCeiling", rad(ethCeiling));
        safeEngine.modifyParameters("globalDebtCeiling", rad(ethCeiling));

        collateralAuctionHouse = new EnglishCollateralAuctionHouse(address(safeEngine), address(liquidationEngine), "eth");
        collateralAuctionHouse.addAuthorization(address(liquidationEngine));

        liquidationEngine.addAuthorization(address(collateralAuctionHouse));
        liquidationEngine.modifyParameters("eth", "collateralAuctionHouse", address(collateralAuctionHouse));
        liquidationEngine.modifyParameters("eth", "liquidationPenalty", ethLiquidationPenalty);

        safeEngine.addAuthorization(address(collateralAuctionHouse));
        safeEngine.approveSAFEModification(address(collateralAuctionHouse));

        safeManager = new GebSafeManager(address(safeEngine));
        oracleRelayer.updateCollateralPrice("eth");

        // Uniswap setup
        uniswapFactory = new UniswapV2Factory(address(this));
        createUniswapPair();
        uniswapRouter = new UniswapV2Router02(address(uniswapFactory), address(weth));
        addPairLiquidityRouter(address(systemCoin), address(weth), initRAIETHPairLiquidity, initETHRAIPairLiquidity);

        // Liquidity manager
        liquidityManager = new UniswapV2LiquidityManager(address(raiWETHPair), address(uniswapRouter));

        // Saviour infra
        saviourRegistry = new SAFESaviourRegistry(saveCooldown);
        cRatioSetter = new SaviourCRatioSetter(address(oracleRelayer), address(safeManager));
        cRatioSetter.setDefaultCRatio("eth", defaultDesiredCollateralizationRatio);

        compoundSaviour = new CompoundSystemCoinSafeSaviour(
            address(coinJoin),
            address(cRatioSetter),
            address(systemCoinOracle),
            address(liquidationEngine),
            address(oracleRelayer),
            address(safeManager),
            address(saviourRegistry),
            address(cRAI),
            keeperPayout,
            minKeeperPayoutValue
        );
        saviourRegistry.toggleSaviour(address(compoundSaviour));
        liquidationEngine.connectSAFESaviour(address(compoundSaviour));

        uniswapSaviour = new NativeUnderlyingUniswapV2SafeSaviour(
            isSystemCoinToken0,
            address(coinJoin),
            address(collateralJoin),
            address(cRatioSetter),
            address(systemCoinOracle),
            address(liquidationEngine),
            address(oracleRelayer),
            address(safeManager),
            address(saviourRegistry),
            address(liquidityManager),
            address(raiWETHPair),
            minKeeperPayoutValue
        );
        saviourRegistry.toggleSaviour(address(uniswapSaviour));
        liquidationEngine.connectSAFESaviour(address(uniswapSaviour));

        // Proxy actions
        gebProxyActions        = address(new GebProxyActions());
        gebProxySaviourActions = address(new GebProxySaviourActions());

        // Proxies
        DSProxyFactory factory = new DSProxyFactory();
        registry = new GebProxyRegistry(address(factory));
        proxy = DSProxy(registry.build());

        me = address(this);
    }

    // --- Math ---
    function ray(uint wad) internal pure returns (uint) {
        return wad * 10 ** 9;
    }
    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }

    // --- Uniswap utils ---
    function createUniswapPair() internal {
        // Setup WETH/RAI pair
        uniswapFactory.createPair(address(weth), address(systemCoin));
        raiWETHPair = UniswapV2Pair(uniswapFactory.getPair(address(weth), address(systemCoin)));

        if (address(raiWETHPair.token0()) == address(systemCoin)) isSystemCoinToken0 = true;
    }
    function addPairLiquidityRouter(address token1, address token2, uint256 amount1, uint256 amount2) internal {
        DSToken(token1).approve(address(uniswapRouter), uint(-1));
        DSToken(token2).approve(address(uniswapRouter), uint(-1));
        uniswapRouter.addLiquidity(token1, token2, amount1, amount2, amount1, amount2, address(this), now);
        UniswapV2Pair updatedPair = UniswapV2Pair(uniswapFactory.getPair(token1, token2));
        updatedPair.sync();
    }
    function addPairLiquidityTransfer(UniswapV2Pair pair, address token1, address token2, uint256 amount1, uint256 amount2) internal {
        DSToken(token1).transfer(address(pair), amount1);
        DSToken(token2).transfer(address(pair), amount2);
        pair.sync();
    }

    // --- Uniswap Saviour Utils ---


    // --- Tests ---
    function test_setup() public {
        assertEq(compoundSaviour.authorizedAccounts(address(this)), 1);
        assertEq(compoundSaviour.keeperPayout(), keeperPayout);
        assertEq(compoundSaviour.minKeeperPayoutValue(), minKeeperPayoutValue);

        assertEq(address(compoundSaviour.coinJoin()), address(coinJoin));
        assertEq(address(compoundSaviour.cRatioSetter()), address(cRatioSetter));
        assertEq(address(compoundSaviour.liquidationEngine()), address(liquidationEngine));
        assertEq(address(compoundSaviour.oracleRelayer()), address(oracleRelayer));
        assertEq(address(compoundSaviour.systemCoinOrcl()), address(systemCoinOracle));
        assertEq(address(compoundSaviour.systemCoin()), address(systemCoin));
        assertEq(address(compoundSaviour.safeEngine()), address(safeEngine));
        assertEq(address(compoundSaviour.safeManager()), address(safeManager));
        assertEq(address(compoundSaviour.saviourRegistry()), address(saviourRegistry));
        assertEq(address(compoundSaviour.cToken()), address(cRAI));

        assertEq(uniswapSaviour.authorizedAccounts(address(this)), 1);
        assertTrue(uniswapSaviour.isSystemCoinToken0() == isSystemCoinToken0);
        assertEq(uniswapSaviour.minKeeperPayoutValue(), minKeeperPayoutValue);
        assertEq(uniswapSaviour.restrictUsage(), 0);

        assertEq(address(uniswapSaviour.coinJoin()), address(coinJoin));
        assertEq(address(uniswapSaviour.collateralJoin()), address(collateralJoin));
        assertEq(address(uniswapSaviour.cRatioSetter()), address(cRatioSetter));
        assertEq(address(uniswapSaviour.liquidationEngine()), address(liquidationEngine));
        assertEq(address(uniswapSaviour.oracleRelayer()), address(oracleRelayer));
        assertEq(address(uniswapSaviour.systemCoinOrcl()), address(systemCoinOracle));
        assertEq(address(uniswapSaviour.systemCoin()), address(systemCoin));
        assertEq(address(uniswapSaviour.safeEngine()), address(safeEngine));
        assertEq(address(uniswapSaviour.safeManager()), address(safeManager));
        assertEq(address(uniswapSaviour.saviourRegistry()), address(saviourRegistry));
        assertEq(address(uniswapSaviour.liquidityManager()), address(liquidityManager));
        assertEq(address(uniswapSaviour.lpToken()), address(raiWETHPair));
        assertEq(address(uniswapSaviour.collateralToken()), address(weth));
    }

    function test_transfer_tokens() public {
        systemCoin.mint(address(proxy), 1 ether);

        weth.deposit{value: 1 ether}();
        weth.transfer(address(proxy), 1 ether);

        tokenList.push(address(systemCoin));
        tokenList.push(address(weth));

        uint256 wethBalance       = weth.balanceOf(address(this));
        uint256 systemCoinBalance = systemCoin.balanceOf(address(this));

        this.transferTokensToCaller(tokenList);
        assertEq(weth.balanceOf(address(this)), wethBalance + 1 ether);
        assertEq(systemCoin.balanceOf(address(this)), systemCoinBalance + 1 ether);

        delete(tokenList);
    }

    function test_protect_safe() public {
        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        this.protectSAFE(address(compoundSaviour), address(safeManager), safe, address(liquidationEngine));
        assertEq(liquidationEngine.chosenSAFESaviour("eth", safeManager.safes(safe)), address(compoundSaviour));

        this.protectSAFE(address(uniswapSaviour), address(safeManager), safe, address(liquidationEngine));
        assertEq(liquidationEngine.chosenSAFESaviour("eth", safeManager.safes(safe)), address(uniswapSaviour));
    }

    function test_set_desired_cratio() public {
        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        this.setDesiredCollateralizationRatio(address(cRatioSetter), "eth", safe, 999);
        assertEq(cRatioSetter.desiredCollateralizationRatios("eth", safeManager.safes(safe)), 999);

        this.setDesiredCollateralizationRatio(address(cRatioSetter), "eth", safe, 0);
        assertEq(cRatioSetter.desiredCollateralizationRatios("eth", safeManager.safes(safe)), 0);
    }

    function test_deposit_in_compound_saviour() public {
        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        systemCoin.approve(address(proxy), uint(-1));
        uint256 systemCoinBalanceSelf = systemCoin.balanceOf(address(this));

        this.protectSAFE(address(compoundSaviour), address(safeManager), safe, address(liquidationEngine));
        this.deposit(true, address(compoundSaviour), address(safeManager), address(systemCoin), safe, systemCoinsToMint);

        assertEq(systemCoin.balanceOf(address(this)) + systemCoinsToMint, systemCoinBalanceSelf);
        assertEq(systemCoin.balanceOf(address(proxy)), 0);
        assertEq(systemCoin.balanceOf(address(compoundSaviour)), 0);
        assertTrue(cRAI.balanceOf(address(compoundSaviour)) > 0);
        assertTrue(compoundSaviour.cTokenCover("eth", safeManager.safes(safe)) > 0);
    }

    function test_deposit_in_uniswap_saviour() public {
        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        // Add liquidity to Uniswap
        addPairLiquidityRouter(
          address(systemCoin), address(weth), initRAIETHPairLiquidity, initETHRAIPairLiquidity
        );
        uint256 lpTokenAmount = raiWETHPair.balanceOf(address(this));
        raiWETHPair.approve(address(proxy), uint(-1));

        // Protect and deposit
        this.protectSAFE(address(uniswapSaviour), address(safeManager), safe, address(liquidationEngine));
        this.deposit(false, address(uniswapSaviour), address(safeManager), address(raiWETHPair), safe, lpTokenAmount);

        assertEq(raiWETHPair.balanceOf(address(this)), 0);
        assertEq(raiWETHPair.balanceOf(address(proxy)), 0);
        assertEq(raiWETHPair.balanceOf(address(uniswapSaviour)), lpTokenAmount);
        assertEq(uniswapSaviour.lpTokenCover(safeManager.safes(safe)), lpTokenAmount);
    }

    function testFail_deposit_in_uniswap_saviour_collateral_specific() public {
        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        // Add liquidity to Uniswap
        addPairLiquidityRouter(
          address(systemCoin), address(weth), initRAIETHPairLiquidity, initETHRAIPairLiquidity
        );
        uint256 lpTokenAmount = raiWETHPair.balanceOf(address(this));
        raiWETHPair.approve(address(proxy), uint(-1));

        // Protect and deposit
        this.protectSAFE(address(uniswapSaviour), address(safeManager), safe, address(liquidationEngine));
        this.deposit(true, address(uniswapSaviour), address(safeManager), address(raiWETHPair), safe, lpTokenAmount);
    }

    function test_set_desired_cratio_deposit_in_compound_saviour() public {
        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        systemCoin.approve(address(proxy), uint(-1));
        uint256 systemCoinBalanceSelf = systemCoin.balanceOf(address(this));

        // Protect, set the desired cRatio and deposit
        this.protectSAFE(address(compoundSaviour), address(safeManager), safe, address(liquidationEngine));
        this.setDesiredCRatioDeposit(
          true, address(compoundSaviour), address(cRatioSetter), address(safeManager), address(systemCoin), safe, systemCoinsToMint, 999
        );

        assertEq(cRatioSetter.desiredCollateralizationRatios("eth", safeManager.safes(safe)), 999);
        assertEq(systemCoin.balanceOf(address(this)) + systemCoinsToMint, systemCoinBalanceSelf);
        assertEq(systemCoin.balanceOf(address(proxy)), 0);
        assertEq(systemCoin.balanceOf(address(compoundSaviour)), 0);
        assertTrue(cRAI.balanceOf(address(compoundSaviour)) > 0);
        assertTrue(compoundSaviour.cTokenCover("eth", safeManager.safes(safe)) > 0);
    }

    function test_set_desired_cratio_deposit_in_uniswap_saviour() public {
        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        // Add liquidity to Uniswap
        addPairLiquidityRouter(
          address(systemCoin), address(weth), initRAIETHPairLiquidity, initETHRAIPairLiquidity
        );
        uint256 lpTokenAmount = raiWETHPair.balanceOf(address(this));
        raiWETHPair.approve(address(proxy), uint(-1));

        // Protect and deposit
        this.protectSAFE(address(uniswapSaviour), address(safeManager), safe, address(liquidationEngine));
        this.setDesiredCRatioDeposit(
          false, address(uniswapSaviour), address(cRatioSetter), address(safeManager), address(raiWETHPair), safe, lpTokenAmount, 999
        );

        assertEq(cRatioSetter.desiredCollateralizationRatios("eth", safeManager.safes(safe)), 999);
        assertEq(raiWETHPair.balanceOf(address(this)), 0);
        assertEq(raiWETHPair.balanceOf(address(proxy)), 0);
        assertEq(raiWETHPair.balanceOf(address(uniswapSaviour)), lpTokenAmount);
        assertEq(uniswapSaviour.lpTokenCover(safeManager.safes(safe)), lpTokenAmount);
    }

    function test_withdraw_self_from_compound_saviour() public {
        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        systemCoin.approve(address(proxy), uint(-1));
        uint256 systemCoinBalanceSelf = systemCoin.balanceOf(address(this));

        this.protectSAFE(address(compoundSaviour), address(safeManager), safe, address(liquidationEngine));
        this.deposit(true, address(compoundSaviour), address(safeManager), address(systemCoin), safe, systemCoinsToMint);
        this.withdraw(
          true, address(compoundSaviour), address(safeManager), safe, compoundSaviour.cTokenCover("eth", safeManager.safes(safe)), address(this)
        );

        assertEq(systemCoin.balanceOf(address(this)), systemCoinBalanceSelf);
        assertEq(systemCoin.balanceOf(address(proxy)), 0);
        assertEq(systemCoin.balanceOf(address(compoundSaviour)), 0);
        assertEq(cRAI.balanceOf(address(compoundSaviour)), 0);
        assertEq(cRAI.totalSupply(), 0);
        assertEq(compoundSaviour.cTokenCover("eth", safeManager.safes(safe)), 0);
    }

    function test_withdraw_other_from_compound_saviour() public {
        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        systemCoin.approve(address(proxy), uint(-1));

        this.protectSAFE(address(compoundSaviour), address(safeManager), safe, address(liquidationEngine));
        this.deposit(true, address(compoundSaviour), address(safeManager), address(systemCoin), safe, systemCoinsToMint);
        this.withdraw(
          true, address(compoundSaviour), address(safeManager), safe, compoundSaviour.cTokenCover("eth", safeManager.safes(safe)), address(0x1234)
        );

        assertEq(systemCoin.balanceOf(address(0x1234)), systemCoinsToMint);
        assertEq(systemCoin.balanceOf(address(proxy)), 0);
        assertEq(systemCoin.balanceOf(address(compoundSaviour)), 0);
        assertEq(cRAI.balanceOf(address(compoundSaviour)), 0);
        assertEq(cRAI.totalSupply(), 0);
        assertEq(compoundSaviour.cTokenCover("eth", safeManager.safes(safe)), 0);
    }

    function test_withdraw_self_from_uniswap_saviour() public {
        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        // Add liquidity to Uniswap
        addPairLiquidityRouter(
          address(systemCoin), address(weth), initRAIETHPairLiquidity, initETHRAIPairLiquidity
        );
        uint256 lpTokenAmount = raiWETHPair.balanceOf(address(this));
        raiWETHPair.approve(address(proxy), uint(-1));

        // Protect and deposit
        this.protectSAFE(address(uniswapSaviour), address(safeManager), safe, address(liquidationEngine));
        this.deposit(false, address(uniswapSaviour), address(safeManager), address(raiWETHPair), safe, lpTokenAmount);
        this.withdraw(false, address(uniswapSaviour), address(safeManager), safe, lpTokenAmount, address(this));

        // Checks
        assertEq(raiWETHPair.balanceOf(address(this)), lpTokenAmount);
        assertEq(raiWETHPair.balanceOf(address(proxy)), 0);
        assertEq(raiWETHPair.balanceOf(address(uniswapSaviour)), 0);
        assertEq(uniswapSaviour.lpTokenCover(safeManager.safes(safe)), 0);
    }

    function test_withdraw_other_from_uniswap_saviour() public {
        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        // Add liquidity to Uniswap
        addPairLiquidityRouter(
          address(systemCoin), address(weth), initRAIETHPairLiquidity, initETHRAIPairLiquidity
        );
        uint256 lpTokenAmount = raiWETHPair.balanceOf(address(this));
        raiWETHPair.approve(address(proxy), uint(-1));

        // Protect and deposit
        this.protectSAFE(address(uniswapSaviour), address(safeManager), safe, address(liquidationEngine));
        this.deposit(false, address(uniswapSaviour), address(safeManager), address(raiWETHPair), safe, lpTokenAmount);
        this.withdraw(false, address(uniswapSaviour), address(safeManager), safe, lpTokenAmount, address(0x1234));

        // Checks
        assertEq(raiWETHPair.balanceOf(address(this)), 0);
        assertEq(raiWETHPair.balanceOf(address(0x1234)), lpTokenAmount);
        assertEq(raiWETHPair.balanceOf(address(proxy)), 0);
        assertEq(raiWETHPair.balanceOf(address(uniswapSaviour)), 0);
        assertEq(uniswapSaviour.lpTokenCover(safeManager.safes(safe)), 0);
    }

    function test_set_desired_cratio_withdraw_from_compound_saviour() public {
        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        systemCoin.approve(address(proxy), uint(-1));
        uint256 systemCoinBalanceSelf = systemCoin.balanceOf(address(this));

        this.protectSAFE(address(compoundSaviour), address(safeManager), safe, address(liquidationEngine));
        this.deposit(true, address(compoundSaviour), address(safeManager), address(systemCoin), safe, systemCoinsToMint);
        this.setDesiredCRatioWithdraw(
          true, address(compoundSaviour), address(cRatioSetter), address(safeManager),
          safe, compoundSaviour.cTokenCover("eth", safeManager.safes(safe)), 950, address(this)
        );

        // Checks
        assertEq(cRatioSetter.desiredCollateralizationRatios("eth", safeManager.safes(safe)), 950);
        assertEq(systemCoin.balanceOf(address(this)), systemCoinBalanceSelf);
        assertEq(systemCoin.balanceOf(address(proxy)), 0);
        assertEq(systemCoin.balanceOf(address(compoundSaviour)), 0);
        assertEq(cRAI.balanceOf(address(compoundSaviour)), 0);
        assertEq(cRAI.totalSupply(), 0);
        assertEq(compoundSaviour.cTokenCover("eth", safeManager.safes(safe)), 0);
    }

    function test_set_desired_cratio_withdraw_from_uniswap_saviour() public {
        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        // Add liquidity to Uniswap
        addPairLiquidityRouter(
          address(systemCoin), address(weth), initRAIETHPairLiquidity, initETHRAIPairLiquidity
        );
        uint256 lpTokenAmount = raiWETHPair.balanceOf(address(this));
        raiWETHPair.approve(address(proxy), uint(-1));

        // Protect and deposit
        this.protectSAFE(address(uniswapSaviour), address(safeManager), safe, address(liquidationEngine));
        this.deposit(false, address(uniswapSaviour), address(safeManager), address(raiWETHPair), safe, lpTokenAmount);
        this.setDesiredCRatioWithdraw(
          false, address(uniswapSaviour), address(cRatioSetter), address(safeManager), safe, lpTokenAmount, 950, address(this)
        );

        // Checks
        assertEq(cRatioSetter.desiredCollateralizationRatios("eth", safeManager.safes(safe)), 950);
        assertEq(raiWETHPair.balanceOf(address(this)), lpTokenAmount);
        assertEq(raiWETHPair.balanceOf(address(proxy)), 0);
        assertEq(raiWETHPair.balanceOf(address(uniswapSaviour)), 0);
        assertEq(uniswapSaviour.lpTokenCover(safeManager.safes(safe)), 0);
    }

    function test_protect_safe_deposit_compound_saviour() public {
        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        systemCoin.approve(address(proxy), uint(-1));
        uint256 systemCoinBalanceSelf = systemCoin.balanceOf(address(this));

        // Protect and deposit
        this.protectSAFEDeposit(
          true, address(compoundSaviour), address(safeManager), address(systemCoin), address(liquidationEngine), safe, systemCoinsToMint
        );

        // Checks
        assertEq(liquidationEngine.chosenSAFESaviour("eth", safeManager.safes(safe)), address(compoundSaviour));
        assertEq(systemCoin.balanceOf(address(this)) + systemCoinsToMint, systemCoinBalanceSelf);
        assertEq(systemCoin.balanceOf(address(proxy)), 0);
        assertEq(systemCoin.balanceOf(address(compoundSaviour)), 0);
        assertTrue(cRAI.balanceOf(address(compoundSaviour)) > 0);
        assertTrue(compoundSaviour.cTokenCover("eth", safeManager.safes(safe)) > 0);
    }

    function test_protect_safe_deposit_uniswap_saviour() public {
        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        // Add liquidity to Uniswap
        addPairLiquidityRouter(
          address(systemCoin), address(weth), initRAIETHPairLiquidity, initETHRAIPairLiquidity
        );
        uint256 lpTokenAmount = raiWETHPair.balanceOf(address(this));
        raiWETHPair.approve(address(proxy), uint(-1));

        // Protect and deposit
        this.protectSAFEDeposit(
          false, address(uniswapSaviour), address(safeManager), address(raiWETHPair), address(liquidationEngine), safe, lpTokenAmount
        );

        // Checks
        assertEq(liquidationEngine.chosenSAFESaviour("eth", safeManager.safes(safe)), address(uniswapSaviour));
        assertEq(raiWETHPair.balanceOf(address(this)), 0);
        assertEq(raiWETHPair.balanceOf(address(proxy)), 0);
        assertEq(raiWETHPair.balanceOf(address(uniswapSaviour)), lpTokenAmount);
        assertEq(uniswapSaviour.lpTokenCover(safeManager.safes(safe)), lpTokenAmount);
    }

    function test_protect_safe_set_desired_cratio_deposit_compound_saviour() public {
        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        systemCoin.approve(address(proxy), uint(-1));
        uint256 systemCoinBalanceSelf = systemCoin.balanceOf(address(this));

        // Protect and deposit
        this.protectSAFESetDesiredCRatioDeposit(
          true, address(compoundSaviour), address(cRatioSetter), address(safeManager),
          address(systemCoin), address(liquidationEngine), safe, systemCoinsToMint, 900
        );

        // Checks
        assertEq(cRatioSetter.desiredCollateralizationRatios("eth", safeManager.safes(safe)), 900);
        assertEq(liquidationEngine.chosenSAFESaviour("eth", safeManager.safes(safe)), address(compoundSaviour));
        assertEq(systemCoin.balanceOf(address(this)) + systemCoinsToMint, systemCoinBalanceSelf);
        assertEq(systemCoin.balanceOf(address(proxy)), 0);
        assertEq(systemCoin.balanceOf(address(compoundSaviour)), 0);
        assertTrue(cRAI.balanceOf(address(compoundSaviour)) > 0);
        assertTrue(compoundSaviour.cTokenCover("eth", safeManager.safes(safe)) > 0);
    }

    function test_protect_safe_set_desired_cratio_deposit_uniswap_saviour() public {
        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        // Add liquidity to Uniswap
        addPairLiquidityRouter(
          address(systemCoin), address(weth), initRAIETHPairLiquidity, initETHRAIPairLiquidity
        );
        uint256 lpTokenAmount = raiWETHPair.balanceOf(address(this));
        raiWETHPair.approve(address(proxy), uint(-1));

        // Protect and deposit
        this.protectSAFESetDesiredCRatioDeposit(
          false, address(uniswapSaviour), address(cRatioSetter), address(safeManager),
          address(raiWETHPair), address(liquidationEngine), safe, lpTokenAmount, 900
        );

        // Checks
        assertEq(cRatioSetter.desiredCollateralizationRatios("eth", safeManager.safes(safe)), 900);
        assertEq(liquidationEngine.chosenSAFESaviour("eth", safeManager.safes(safe)), address(uniswapSaviour));
        assertEq(raiWETHPair.balanceOf(address(this)), 0);
        assertEq(raiWETHPair.balanceOf(address(proxy)), 0);
        assertEq(raiWETHPair.balanceOf(address(uniswapSaviour)), lpTokenAmount);
        assertEq(uniswapSaviour.lpTokenCover(safeManager.safes(safe)), lpTokenAmount);
    }

    function test_withdraw_uncover_compound_saviour() public {
        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        systemCoin.approve(address(proxy), uint(-1));
        uint256 systemCoinBalanceSelf = systemCoin.balanceOf(address(this));

        // Protect and deposit and then withdraw and uncover
        this.protectSAFESetDesiredCRatioDeposit(
          true, address(compoundSaviour), address(cRatioSetter), address(safeManager),
          address(systemCoin), address(liquidationEngine), safe, systemCoinsToMint, 900
        );
        this.withdrawUncoverSAFE(
          true, address(compoundSaviour), address(safeManager), address(systemCoin), address(liquidationEngine),
          safe, systemCoinsToMint, address(this)
        );

        // Checks
        assertEq(cRatioSetter.desiredCollateralizationRatios("eth", safeManager.safes(safe)), 900);
        assertEq(liquidationEngine.chosenSAFESaviour("eth", safeManager.safes(safe)), address(0));
        assertEq(systemCoin.balanceOf(address(this)), systemCoinBalanceSelf);
        assertEq(systemCoin.balanceOf(address(proxy)), 0);
        assertEq(systemCoin.balanceOf(address(compoundSaviour)), 0);
        assertEq(cRAI.balanceOf(address(compoundSaviour)), 0);
        assertEq(compoundSaviour.cTokenCover("eth", safeManager.safes(safe)), 0);
    }

    function test_withdraw_uncover_uniswap_saviour() public {
        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        // Add liquidity to Uniswap
        addPairLiquidityRouter(
          address(systemCoin), address(weth), initRAIETHPairLiquidity, initETHRAIPairLiquidity
        );
        uint256 lpTokenAmount = raiWETHPair.balanceOf(address(this));
        raiWETHPair.approve(address(proxy), uint(-1));

        // Protect and deposit
        this.protectSAFESetDesiredCRatioDeposit(
          false, address(uniswapSaviour), address(cRatioSetter), address(safeManager),
          address(raiWETHPair), address(liquidationEngine), safe, lpTokenAmount, 900
        );
        this.withdrawUncoverSAFE(
          false, address(uniswapSaviour), address(safeManager), address(raiWETHPair), address(liquidationEngine),
          safe, lpTokenAmount, address(this)
        );

        // Checks
        assertEq(cRatioSetter.desiredCollateralizationRatios("eth", safeManager.safes(safe)), 900);
        assertEq(liquidationEngine.chosenSAFESaviour("eth", safeManager.safes(safe)), address(0));
        assertEq(raiWETHPair.balanceOf(address(this)), lpTokenAmount);
        assertEq(raiWETHPair.balanceOf(address(proxy)), 0);
        assertEq(raiWETHPair.balanceOf(address(uniswapSaviour)), 0);
        assertEq(uniswapSaviour.lpTokenCover(safeManager.safes(safe)), 0);
    }

    function test_withdraw_from_compound_saviour_protect_deposit_in_uniswap_saviour() public {
        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        systemCoin.approve(address(proxy), uint(-1));
        uint256 systemCoinBalanceSelf = systemCoin.balanceOf(address(this));

        // Protect and deposit
        this.protectSAFESetDesiredCRatioDeposit(
          true, address(compoundSaviour), address(cRatioSetter), address(safeManager),
          address(systemCoin), address(liquidationEngine), safe, systemCoinsToMint, 900
        );

        // Add liquidity to Uniswap
        systemCoin.mint(address(this), initRAIETHPairLiquidity);

        addPairLiquidityRouter(
          address(systemCoin), address(weth), initRAIETHPairLiquidity, initETHRAIPairLiquidity
        );
        uint256 lpTokenAmount = raiWETHPair.balanceOf(address(this));
        raiWETHPair.approve(address(proxy), uint(-1));

        // Change cover to the Uniswap saviour
        this.withdrawProtectSAFEDeposit(
          true, false, address(compoundSaviour), address(uniswapSaviour), address(safeManager),
          address(raiWETHPair), address(liquidationEngine), safe, systemCoinsToMint, lpTokenAmount,
          address(this)
        );

        // Checks
        assertEq(cRatioSetter.desiredCollateralizationRatios("eth", safeManager.safes(safe)), 900);
        assertEq(liquidationEngine.chosenSAFESaviour("eth", safeManager.safes(safe)), address(uniswapSaviour));

        assertEq(systemCoin.balanceOf(address(this)), systemCoinBalanceSelf);
        assertEq(systemCoin.balanceOf(address(proxy)), 0);
        assertEq(systemCoin.balanceOf(address(compoundSaviour)), 0);
        assertEq(cRAI.balanceOf(address(compoundSaviour)), 0);
        assertEq(compoundSaviour.cTokenCover("eth", safeManager.safes(safe)), 0);

        assertEq(raiWETHPair.balanceOf(address(this)), 0);
        assertEq(raiWETHPair.balanceOf(address(proxy)), 0);
        assertEq(raiWETHPair.balanceOf(address(uniswapSaviour)), lpTokenAmount);
        assertEq(uniswapSaviour.lpTokenCover(safeManager.safes(safe)), lpTokenAmount);
    }

    function test_withdraw_from_uniswap_saviour_protect_deposit_in_compound_saviour() public {
        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        systemCoin.approve(address(proxy), uint(-1));

        // Add liquidity to Uniswap
        addPairLiquidityRouter(
          address(systemCoin), address(weth), initRAIETHPairLiquidity, initETHRAIPairLiquidity
        );
        uint256 lpTokenAmount = raiWETHPair.balanceOf(address(this));
        raiWETHPair.approve(address(proxy), uint(-1));

        // Protect and deposit
        this.protectSAFESetDesiredCRatioDeposit(
          false, address(uniswapSaviour), address(cRatioSetter), address(safeManager),
          address(raiWETHPair), address(liquidationEngine), safe, lpTokenAmount, 900
        );

        // Change cover to the Compound saviour
        systemCoin.mint(address(this), systemCoinsToMint);
        uint256 systemCoinBalanceSelf = systemCoin.balanceOf(address(this));

        this.withdrawProtectSAFEDeposit(
          false, true, address(uniswapSaviour), address(compoundSaviour), address(safeManager),
          address(systemCoin), address(liquidationEngine), safe, lpTokenAmount, systemCoinsToMint,
          address(this)
        );

        // Checks
        assertEq(cRatioSetter.desiredCollateralizationRatios("eth", safeManager.safes(safe)), 900);
        assertEq(liquidationEngine.chosenSAFESaviour("eth", safeManager.safes(safe)), address(compoundSaviour));

        assertEq(systemCoin.balanceOf(address(this)) + systemCoinsToMint, systemCoinBalanceSelf);
        assertEq(systemCoin.balanceOf(address(proxy)), 0);
        assertEq(systemCoin.balanceOf(address(compoundSaviour)), 0);
        assertTrue(cRAI.balanceOf(address(compoundSaviour)) > 0);
        assertTrue(compoundSaviour.cTokenCover("eth", safeManager.safes(safe)) > 0);

        assertEq(raiWETHPair.balanceOf(address(this)), lpTokenAmount);
        assertEq(raiWETHPair.balanceOf(address(proxy)), 0);
        assertEq(raiWETHPair.balanceOf(address(uniswapSaviour)), 0);
        assertEq(uniswapSaviour.lpTokenCover(safeManager.safes(safe)), 0);
    }

    function test_get_reserves_self_uniswap_saviour() public {
        uniswapSaviour.modifyParameters("minKeeperPayoutValue", 1 ether);

        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        // Add liquidity to Uniswap
        addPairLiquidityRouter(
          address(systemCoin), address(weth), initRAIETHPairLiquidity, initETHRAIPairLiquidity
        );
        uint256 lpTokenAmount = raiWETHPair.balanceOf(address(this));
        raiWETHPair.approve(address(proxy), uint(-1));

        // Protect and deposit
        this.protectSAFESetDesiredCRatioDeposit(
          false, address(uniswapSaviour), address(cRatioSetter), address(safeManager),
          address(raiWETHPair), address(liquidationEngine), safe, lpTokenAmount, minDesiredCollateralizationRatio
        );

        // Save
        ethMedian.updateCollateralPrice(initETHUSDPrice / 30);
        ethFSM.updateCollateralPrice(initETHUSDPrice / 30);
        oracleRelayer.updateCollateralPrice("eth");

        liquidationEngine.modifyParameters("eth", "liquidationQuantity", rad(100000 ether));
        liquidationEngine.modifyParameters("eth", "liquidationPenalty", 1.1 ether);

        uint256 preSaveSysCoinKeeperBalance = systemCoin.balanceOf(address(this));
        uint256 preSaveWETHKeeperBalance = weth.balanceOf(address(this));

        uint auction = liquidationEngine.liquidateSAFE("eth", safeManager.safes(safe));
        (uint256 sysCoinReserve, uint256 collateralReserve) = uniswapSaviour.underlyingReserves(safeManager.safes(safe));

        assertEq(auction, 0);
        assertTrue(
          sysCoinReserve > 0 ||
          collateralReserve > 0
        );
        assertTrue(
          systemCoin.balanceOf(address(this)) - preSaveSysCoinKeeperBalance > 0 ||
          weth.balanceOf(address(this)) - preSaveWETHKeeperBalance > 0
        );
        assertTrue(raiWETHPair.balanceOf(address(uniswapSaviour)) < lpTokenAmount);

        // Get reserves
        uint256 sysCoinSelfBalance    = systemCoin.balanceOf(address(this));
        uint256 collateralSelfBalance = weth.balanceOf(address(this));

        this.getReservesAndUncover(address(uniswapSaviour), address(safeManager), address(liquidationEngine), safe, address(this));

        assertEq(liquidationEngine.chosenSAFESaviour("eth", safeManager.safes(safe)), address(0));
        assertEq(systemCoin.balanceOf(address(this)), sysCoinSelfBalance + sysCoinReserve);
        assertEq(weth.balanceOf(address(this)), collateralSelfBalance + collateralReserve);
    }

    function test_get_reserves_other_uniswap_saviour() public {
        uniswapSaviour.modifyParameters("minKeeperPayoutValue", 1 ether);

        uint safe = this.openLockETHAndGenerateDebt{value: 2 ether}
          (address(safeManager), address(taxCollector), address(collateralJoin), address(coinJoin), "eth", 300 ether);

        // Add liquidity to Uniswap
        addPairLiquidityRouter(
          address(systemCoin), address(weth), initRAIETHPairLiquidity, initETHRAIPairLiquidity
        );
        uint256 lpTokenAmount = raiWETHPair.balanceOf(address(this));
        raiWETHPair.approve(address(proxy), uint(-1));

        // Protect and deposit
        this.protectSAFESetDesiredCRatioDeposit(
          false, address(uniswapSaviour), address(cRatioSetter), address(safeManager),
          address(raiWETHPair), address(liquidationEngine), safe, lpTokenAmount, minDesiredCollateralizationRatio
        );

        // Save
        ethMedian.updateCollateralPrice(initETHUSDPrice / 30);
        ethFSM.updateCollateralPrice(initETHUSDPrice / 30);
        oracleRelayer.updateCollateralPrice("eth");

        liquidationEngine.modifyParameters("eth", "liquidationQuantity", rad(100000 ether));
        liquidationEngine.modifyParameters("eth", "liquidationPenalty", 1.1 ether);

        uint256 preSaveSysCoinKeeperBalance = systemCoin.balanceOf(address(this));
        uint256 preSaveWETHKeeperBalance = weth.balanceOf(address(this));

        uint auction = liquidationEngine.liquidateSAFE("eth", safeManager.safes(safe));
        (uint256 sysCoinReserve, uint256 collateralReserve) = uniswapSaviour.underlyingReserves(safeManager.safes(safe));

        assertEq(auction, 0);
        assertTrue(
          sysCoinReserve > 0 ||
          collateralReserve > 0
        );
        assertTrue(
          systemCoin.balanceOf(address(this)) - preSaveSysCoinKeeperBalance > 0 ||
          weth.balanceOf(address(this)) - preSaveWETHKeeperBalance > 0
        );
        assertTrue(raiWETHPair.balanceOf(address(uniswapSaviour)) < lpTokenAmount);

        // Get reserves
        this.getReservesAndUncover(address(uniswapSaviour), address(safeManager), address(liquidationEngine), safe, address(0x123));

        assertEq(liquidationEngine.chosenSAFESaviour("eth", safeManager.safes(safe)), address(0));
        assertEq(systemCoin.balanceOf(address(0x123)), sysCoinReserve);
        assertEq(weth.balanceOf(address(0x123)), collateralReserve);
    }
}
