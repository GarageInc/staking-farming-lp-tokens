// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../../common/strategy/AlphaStrategyBase.sol";
import "./interfaces/XToken.sol";
import "./interfaces/IMasterChef.sol";
import "./interfaces/IController.sol";

contract AlphaStrategyScream is AlphaStrategyBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;

    address public masterChef;
    address public controller;

    event Redeem(address indexed beneficiary, uint256 amount);

    function initializeAlphaStrategy(
        address _multisigWallet,
        address _rewardManager,
        address _treasury,
        address _underlying,
        address _vault,
        address _baseToken,
        address _xBaseToken,
        address _masterChef,
        address _controller
    ) public initializer {
        initDefault(
            _multisigWallet,
            _rewardManager,
            _treasury,
            _underlying,
            _vault,
            _baseToken,
            _xBaseToken
        );
        masterChef = _masterChef;
        controller = _controller;

        address _lpt = IMasterChef(_masterChef).underlying();
        require(_lpt == underlying, "Pool Info does not match underlying");
    }

    function updateAccPerShare(address user) public virtual override onlyVault {
        updateAccRewardPerShare(xBaseToken, pendingReward(xBaseToken), user);
    }

    function pendingReward(address _token)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (_token == xBaseToken) {
            return pendingXToken();
        }

        return 0;
    }

    function updateUserRewardDebts(address user)
        public
        virtual
        override
        onlyVault
    {
        updateUserRewardDebtsFor(xBaseToken, user);
    }

    function pendingRewardOfUser(address user) external view returns (uint256) {
        return (pendingXTokenOfUser(user));
    }

    function pendingXTokenOfUser(address user) public view returns (uint256) {
        uint256 xBalance = pendingXToken();
        return pendingTokenOfUser(user, xBaseToken, xBalance);
    }

    function pendingXToken() public view virtual override returns (uint256) {
        uint256 balance = IERC20Upgradeable(xBaseToken).balanceOf(
            address(this)
        );
        return balance;
    }

    function withdrawReward(address user) public virtual override onlyVault {
        withdrawXTokenReward(user);
    }

    function withdrawLpTokens(uint256 amount) internal override {
        IMasterChef(masterChef).redeemUnderlying(amount);
        emit Redeem(msg.sender, amount);
    }

    function exitFirstPool() internal virtual override returns (uint256) {
        uint256 bal = lpBalance();
        if (bal > 0) {
            withdrawLpTokens(bal);
        }
        return bal;
    }

    function claimFirstPool() public virtual override {
        uint256 bal = lpBalance();
        if (bal > 0) {
            IController(controller).claimComp(address(this));
        }
    }

    function stakeLpTokens() external virtual override {
        uint256 entireBalance = IERC20Upgradeable(underlying).balanceOf(
            address(this)
        );

        if (entireBalance > 0) {
            IERC20Upgradeable(underlying).safeApprove(masterChef, 0);
            IERC20Upgradeable(underlying).safeApprove(
                masterChef,
                entireBalance
            );

            IMasterChef(masterChef).mint(entireBalance);
        }
    }

    function enterBaseToken(uint256 baseTokenBalance)
        internal
        virtual
        override
    {
        XToken(xBaseToken).deposit(baseTokenBalance);
    }

    function lpBalance() public view override returns (uint256) {
        uint256 multiplier;
        uint256 mantissa;
        (multiplier, mantissa) = lpMultiplier();

        uint256 decimals = numDigits(mantissa) - 1;

        uint256 amount = multiplier / (10**(decimals));

        uint256 result = amount > 100000 ? amount - 100000 : 0;

        return (result > 0 ? result / (10**4) : 0);
    }

    function lpMultiplier() public view returns (uint256, uint256) {
        uint256 bal;
        uint256 mantissa;

        (, bal, , mantissa) = IMasterChef(masterChef).getAccountSnapshot(
            address(this)
        );

        return ((bal * mantissa), mantissa);
    }

    function numDigits(uint256 number) public pure returns (uint8) {
        uint8 digits = 0;
        while (number > 0) {
            number /= 10;
            digits++;
        }
        return digits;
    }
}
