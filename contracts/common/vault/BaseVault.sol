// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./../IStrategy.sol";

abstract contract BaseVault is ERC20Upgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;

    event Withdraw(address indexed beneficiary, uint256 amount);
    event Deposit(address indexed beneficiary, uint256 amount);
    event Invest(uint256 amount);

    uint256 keepFee;
    uint256 keepFeeMax;

    address public strategy;
    address public underlying;

    uint8 private _decimals;

    function initialize(address _underlying) public initializer {
        __ERC20_init(
            string(
                abi.encodePacked(
                    "alpha_",
                    ERC20Upgradeable(_underlying).symbol()
                )
            ),
            string(
                abi.encodePacked(
                    "alpha",
                    ERC20Upgradeable(_underlying).symbol()
                )
            )
        );

        _decimals = (ERC20Upgradeable(_underlying).decimals());

        __Ownable_init();

        underlying = _underlying;

        keepFee = 10;
        keepFeeMax = 10000;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    // keep fee functions
    function setKeepFee(uint256 _fee, uint256 _feeMax) external onlyOwner {
        require(_feeMax > 0, "feeMax should be bigger than zero");
        require(_fee < _feeMax, "fee can't be bigger than feeMax");
        keepFee = _fee;
        keepFeeMax = _feeMax;
    }

    // override erc20 transfer function
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        super._transfer(sender, recipient, amount);

        IStrategy(strategy).updateUserRewardDebts(sender);
        IStrategy(strategy).updateUserRewardDebts(recipient);
    }

    modifier whenStrategyDefined() {
        require(address(strategy) != address(0), "undefined strategy");
        _;
    }

    function setStrategy(address _strategy) public onlyOwner {
        require(_strategy != address(0), "empty strategy");
        require(
            IStrategy(_strategy).underlying() == address(underlying),
            "underlying not match"
        );
        require(
            IStrategy(_strategy).vault() == address(this),
            "strategy vault not match"
        );

        strategy = _strategy;

        IERC20Upgradeable(underlying).safeApprove(address(strategy), 0);
        IERC20Upgradeable(underlying).safeApprove(
            address(strategy),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
    }

    // Only smart contracts will be affected by this modifier
    modifier defense() {
        require(
            (msg.sender == tx.origin), // If it is a smart contract, then
            "grey listed" // make sure that it is not on our greyList.
        );
        _;
    }

    function stakeLpTokens() external whenStrategyDefined onlyOwner {
        invest();
        IStrategy(strategy).stakeLpTokens();
    }

    function stakeFirstRewards() external whenStrategyDefined onlyOwner {
        IStrategy(strategy).stakeFirstRewards();
    }

    function stakeSecondRewards() external whenStrategyDefined onlyOwner {
        IStrategy(strategy).stakeSecondRewards();
    }

    function doHardWork() public virtual;

    function underlyingBalanceInVault() public view returns (uint256) {
        return IERC20Upgradeable(underlying).balanceOf(address(this));
    }

    function underlyingBalanceWithInvestment() public view returns (uint256) {
        if (address(strategy) == address(0)) {
            // initial state, when not set
            return underlyingBalanceInVault();
        }
        return
            underlyingBalanceInVault() +
            IStrategy(strategy).investedUnderlyingBalance();
    }

    function underlyingBalanceWithInvestmentForHolder(address holder)
        external
        view
        returns (uint256)
    {
        if (totalSupply() == 0) {
            return 0;
        }
        return
            (underlyingBalanceWithInvestment() * balanceOf(holder)) /
            totalSupply();
    }

    function rebalance() external onlyOwner {
        withdrawAll();
        invest();
    }

    function invest() internal whenStrategyDefined {
        uint256 availableAmount = underlyingBalanceInVault();
        if (availableAmount > 0) {
            IERC20Upgradeable(underlying).safeTransfer(
                address(strategy),
                availableAmount
            );
            emit Invest(availableAmount);
        }
    }

    function deposit(uint256 amount) external defense whenStrategyDefined {
        _deposit(amount, msg.sender, msg.sender);
    }

    function depositFor(uint256 amount, address holder)
        public
        defense
        whenStrategyDefined
    {
        _deposit(amount, msg.sender, holder);
    }

    function withdrawAll() public onlyOwner whenStrategyDefined {
        IStrategy(strategy).withdrawAllToVault();
    }

    function withdraw(uint256 numberOfShares) external whenStrategyDefined {
        require(totalSupply() > 0, "no shares");

        // doHardWork at every withdraw
        doHardWork();

        IStrategy(strategy).updateAccPerShare(msg.sender);
        IStrategy(strategy).withdrawReward(msg.sender);

        if (numberOfShares > 0) {
            uint256 totalSupply = totalSupply();

            _burn(msg.sender, numberOfShares);

            uint256 underlyingAmountToWithdraw = (underlyingBalanceWithInvestment() *
                    numberOfShares) / totalSupply;

            if (underlyingAmountToWithdraw > underlyingBalanceInVault()) {
                // withdraw everything from the strategy to accurately check the share value
                if (numberOfShares == totalSupply) {
                    IStrategy(strategy).withdrawAllToVault();
                } else {
                    uint256 missing = underlyingAmountToWithdraw -
                        underlyingBalanceInVault();
                    IStrategy(strategy).withdrawToVault(missing);
                }
                // recalculate to improve accuracy
                underlyingAmountToWithdraw = MathUpgradeable.min(
                    (underlyingBalanceWithInvestment() * numberOfShares) /
                        totalSupply,
                    underlyingBalanceInVault()
                );
            }

            // Send withdrawal fee
            uint256 feeAmount = (underlyingAmountToWithdraw * keepFee) /
                keepFeeMax;

            IERC20Upgradeable(underlying).safeTransfer(
                IStrategy(strategy).treasury(),
                feeAmount
            );

            underlyingAmountToWithdraw = underlyingAmountToWithdraw - feeAmount;

            IERC20Upgradeable(underlying).safeTransfer(
                msg.sender,
                underlyingAmountToWithdraw
            );

            // update the withdrawal amount for the holder
            emit Withdraw(msg.sender, underlyingAmountToWithdraw);
        }

        IStrategy(strategy).updateUserRewardDebts(msg.sender);
    }

    function _deposit(
        uint256 amount,
        address sender,
        address beneficiary
    ) internal {
        require(beneficiary != address(0), "holder undefined");

        doHardWork();

        IStrategy(strategy).updateAccPerShare(beneficiary);
        IStrategy(strategy).withdrawReward(beneficiary);

        if (amount > 0) {
            uint256 toMint = totalSupply() == 0
                ? amount
                : ((amount * totalSupply()) /
                    underlyingBalanceWithInvestment());

            _mint(beneficiary, toMint);

            IERC20Upgradeable(underlying).safeTransferFrom(
                sender,
                address(this),
                amount
            );

            // update the contribution amount for the beneficiary
            emit Deposit(beneficiary, amount);
        }

        IStrategy(strategy).updateUserRewardDebts(beneficiary);
    }
}
