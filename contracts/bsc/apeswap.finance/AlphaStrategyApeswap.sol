// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../../common/strategy/AlphaStrategyBase.sol";
import "./interfaces/IMasterChef.sol";

contract AlphaStrategyApeswap is AlphaStrategyBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;

    address public masterChef;

    uint256 public pidLp;
    uint256 public pidSecond;

    function initializeAlphaStrategy(
        address _multisigWallet,
        address _rewardManager,
        address _treasury,
        address _underlying,
        address _vault,
        address _masterChef,
        address _rewardToken,
        uint256 _pidLp,
        uint256 _pidSecond
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

        masterChef = _masterChef;

        address _lpt;
        (_lpt, , , ) = IMasterChef(_masterChef).getPoolInfo(_pidLp);

        require(_lpt == underlying, "Pool Info does not match first reward");
        pidLp = _pidLp;

        (_lpt, , , ) = IMasterChef(_masterChef).getPoolInfo(_pidSecond);
        require(_lpt == _rewardToken, "Pool Info does not match second reward");

        pidSecond = _pidSecond;
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

        uint256 stakedToken = getStakedToPool(pidSecond);

        return balance + stakedToken;
    }

    function getStakedToPool(uint256 pid) public view returns (uint256) {
        (uint256 stakedToken, ) = IMasterChef(masterChef).userInfo(
            pid,
            address(this)
        );

        return stakedToken;
    }

    function getPendingCake(uint256 pid) public view returns (uint256) {
        return IMasterChef(masterChef).pendingCake(pid, address(this));
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
        return getStakedToPool(pidSecond);
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
            uint256 reward = prepareForWithdraw(
                balanceXToken(),
                _pendingXBaseToken
            );

            IERC20Upgradeable(xBaseToken).safeTransfer(user, reward);

            lastPendingReward[xBaseToken] =
                curPendingReward[xBaseToken] -
                reward;
        }
    }

    function withdrawLpTokens(uint256 amount) internal override {
        IMasterChef(masterChef).withdraw(pidLp, amount);
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
            IMasterChef(masterChef).deposit(pidLp, 0);
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

            IMasterChef(masterChef).deposit(pidLp, entireBalance);
        }
    }

    function enterBaseToken(uint256 baseTokenBalance)
        internal
        virtual
        override
    {
        if (baseTokenBalance > 0) {
            IERC20Upgradeable(baseToken).safeApprove(masterChef, 0);
            IERC20Upgradeable(baseToken).safeApprove(
                masterChef,
                baseTokenBalance
            );
            IMasterChef(masterChef).enterStaking(baseTokenBalance);
        }
    }

    function lpBalance() public view override returns (uint256) {
        return getStakedToPool(pidLp);
    }

    function withdrawXTokenStaked(uint256 toWithdraw) internal override {
        uint256 balance = getPendingCake(pidSecond);

        if (balance > 0) {
            IMasterChef(masterChef).leaveStaking(0);
        }

        uint256 xBalance = balanceXToken();

        if (xBalance < toWithdraw) {
            uint256 needToUnstake = toWithdraw - xBalance;
            balance = getStakedToPool(pidSecond);

            uint256 unstakeValue = Math.min(balance, needToUnstake);

            if (unstakeValue > 0) {
                IMasterChef(masterChef).leaveStaking(unstakeValue);
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
