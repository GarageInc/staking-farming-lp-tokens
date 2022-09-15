// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../../common/strategy/AlphaStrategyBase.sol";
import "./interfaces/IMasterChef.sol";
import "./interfaces/IMasterChefCake.sol";

contract AlphaStrategyPancakeswap is AlphaStrategyBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;

    address public masterChefV1;
    address public masterChefV2;

    uint256 public pidLp;

    function initializeAlphaStrategy(
        address _multisigWallet,
        address _rewardManager,
        address _treasury,
        address _underlying,
        address _vault,
        address _masterChefV1,
        address _masterChefV2,
        address _rewardToken,
        uint256 _pidLp
    ) public initializer {
        initDefault(
            _multisigWallet,
            _rewardManager,
            _treasury,
            _underlying,
            _vault,
            _rewardToken,
            _rewardToken
        );

        masterChefV1 = _masterChefV1;
        masterChefV2 = _masterChefV2;

        address _lpt = IMasterChef(masterChefV1).lpToken(_pidLp);

        require(_lpt == underlying, "Pool Info does not match first reward");
        pidLp = _pidLp;
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
        uint256 balance = balanceXToken();

        uint256 stakedToken = getStakedCake();

        return balance + stakedToken;
    }

    function getStakedCake() public view returns (uint256) {
        uint256 balanceOf = IMasterChefCake(masterChefV2).balanceOf();

        uint256 totalShares = IMasterChefCake(masterChefV2).totalShares();

        (uint256 shares, , , , , , , , ) = IMasterChefCake(masterChefV2)
            .userInfo(address(this));

        uint256 currentAmount = ((shares * balanceOf) / totalShares);

        return currentAmount;
    }

    function withdrawReward(address user) public virtual override onlyVault {
        withdrawXTokenReward(user);
    }

    function xTokenStaked()
        internal
        view
        virtual
        override
        returns (uint256 bal)
    {
        return getStakedCake();
    }

    function withdrawXTokenReward(address user)
        internal
        virtual
        override
        onlyVault
    {
        uint256 _pendingXBaseToken = getPendingShare(
            user,
            accRewardPerShare[xBaseToken],
            userRewardDebt[xBaseToken][user]
        );

        uint256 _xBaseTokenBalance = pendingXToken();

        _pendingXBaseToken = prepareForWithdraw(
            _xBaseTokenBalance,
            _pendingXBaseToken
        );

        if (
            _pendingXBaseToken > 0 &&
            curPendingReward[xBaseToken] > _pendingXBaseToken
        ) {
            uint256 reward = Math.min(balanceXToken(), _pendingXBaseToken);

            IERC20Upgradeable(xBaseToken).safeTransfer(user, reward);

            lastPendingReward[xBaseToken] =
                curPendingReward[xBaseToken] -
                reward;
        }
    }

    function withdrawLpTokens(uint256 amount) internal override {
        IMasterChef(masterChefV1).withdraw(pidLp, amount);
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
            IMasterChef(masterChefV1).deposit(pidLp, 0);
        }
    }

    function stakeLpTokens() external virtual override {
        uint256 entireBalance = IERC20Upgradeable(underlying).balanceOf(
            address(this)
        );

        if (entireBalance > 0) {
            IERC20Upgradeable(underlying).safeApprove(masterChefV1, 0);
            IERC20Upgradeable(underlying).safeApprove(
                masterChefV1,
                entireBalance
            );

            IMasterChef(masterChefV1).deposit(pidLp, entireBalance);
        }
    }

    function enterBaseToken(uint256 baseTokenBalance)
        internal
        virtual
        override
    {
        if (baseTokenBalance > 0.00001 ether) {
            IERC20Upgradeable(baseToken).safeApprove(masterChefV2, 0);
            IERC20Upgradeable(baseToken).safeApprove(
                masterChefV2,
                baseTokenBalance
            );
            IMasterChefCake(masterChefV2).deposit(baseTokenBalance, 0);
        }
    }

    function lpBalance() public view override returns (uint256) {
        (uint256 amount, , ) = IMasterChef(masterChefV1).userInfo(
            pidLp,
            address(this)
        );

        return amount;
    }

    function withdrawXTokenStaked(uint256 toWithdraw) internal override {
        uint256 xBalance = balanceXToken();

        if (xBalance < toWithdraw) {
            uint256 needToUnstake = toWithdraw - xBalance;
            uint256 balance = getStakedCake();

            uint256 unstakeValue = Math.min(balance, needToUnstake);

            if (unstakeValue > 0.00001 ether) {
                IMasterChefCake(masterChefV2).withdrawByAmount(unstakeValue);
            }
        }
    }

    function stakeFirstRewards() external override {
        require(baseToken == xBaseToken, "Tokens should be equal");

        claimFirstPool();

        uint256 baseTokenBalance = IERC20Upgradeable(baseToken).balanceOf(
            address(this)
        );

        if (!sell || baseTokenBalance < sellFloor) {
            // Profits can be disabled for possible simplified and rapid exit
            return;
        }

        if (baseTokenBalance == 0) {
            return;
        }

        if (baseTokenBalance > 0) {
            uint256 fee = (baseTokenBalance * keepFee) / keepFeeMax;
            IERC20Upgradeable(xBaseToken).safeTransfer(treasury, fee);

            uint256 feeReward = (baseTokenBalance * keepReward) / keepRewardMax;
            IERC20Upgradeable(xBaseToken).safeTransfer(
                rewardManager,
                feeReward
            );

            enterBaseToken(baseTokenBalance - fee - feeReward);
        }
    }
}
