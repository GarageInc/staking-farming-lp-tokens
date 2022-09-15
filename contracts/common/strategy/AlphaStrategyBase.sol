// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

abstract contract AlphaStrategyBase is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;

    address public treasury;
    address public rewardManager;
    address public multisigWallet;

    uint256 keepFee;
    uint256 keepFeeMax;

    uint256 keepReward;
    uint256 keepRewardMax;

    address public vault;
    address public underlying;

    bool public sell;
    uint256 public sellFloor;

    mapping(address => mapping(address => uint256)) public userRewardDebt;

    mapping(address => uint256) public accRewardPerShare;
    mapping(address => uint256) public lastPendingReward;
    mapping(address => uint256) public curPendingReward;

    address public baseToken;
    address public xBaseToken;

    function initDefault(
        address _multisigWallet,
        address _rewardManager,
        address _treasury,
        address _underlying,
        address _vault,
        address _baseToken,
        address _xBaseToken
    ) internal {
        __Ownable_init();

        underlying = _underlying;
        vault = _vault;

        rewardManager = _rewardManager;
        multisigWallet = _multisigWallet;

        baseToken = _baseToken;
        xBaseToken = _xBaseToken;

        treasury = _treasury;

        keepFee = 5;
        keepFeeMax = 100;

        keepReward = 5;
        keepRewardMax = 100;

        sell = true;
    }

    // keep fee functions
    function setKeepFee(uint256 _fee, uint256 _feeMax)
        external
        onlyMultisigOrOwner
    {
        require(_feeMax > 0, "Treasury feeMax should be bigger than zero");
        require(_fee < _feeMax, "Treasury fee can't be bigger than feeMax");
        keepFee = _fee;
        keepFeeMax = _feeMax;
    }

    // keep reward functions
    function setKeepReward(uint256 _fee, uint256 _feeMax)
        external
        onlyMultisigOrOwner
    {
        require(_feeMax > 0, "Reward feeMax should be bigger than zero");
        require(_fee < _feeMax, "Reward fee can't be bigger than feeMax");
        keepReward = _fee;
        keepRewardMax = _feeMax;
    }

    // Salvage functions
    function unsalvagableTokens(address token) public view returns (bool) {
        return (token == baseToken || token == underlying);
    }

    /**
     * Salvages a token.
     */
    function salvage(
        address recipient,
        address token,
        uint256 amount
    ) public onlyMultisigOrOwner {
        // To make sure that governance cannot come in and take away the coins
        require(
            !unsalvagableTokens(token),
            "token is defined as not salvagable"
        );
        IERC20Upgradeable(token).safeTransfer(recipient, amount);
    }

    modifier onlyVault() {
        require(msg.sender == vault, "Not a vault");
        _;
    }

    modifier onlyMultisig() {
        require(
            msg.sender == multisigWallet,
            "The sender has to be the multisig wallet"
        );
        _;
    }

    modifier onlyMultisigOrOwner() {
        require(
            msg.sender == multisigWallet || msg.sender == owner(),
            "The sender has to be the multisig wallet or owner"
        );
        _;
    }

    function setMultisig(address _wallet) public onlyMultisig {
        multisigWallet = _wallet;
    }

    function setOnxTreasuryFundAddress(address _address)
        public
        onlyMultisigOrOwner
    {
        treasury = _address;
    }

    function setRewardManagerAddress(address _address)
        public
        onlyMultisigOrOwner
    {
        rewardManager = _address;
    }

    function updateAccRewardPerShare(
        address token,
        uint256 rewardPending,
        address user
    ) internal {
        curPendingReward[token] = rewardPending;

        if (
            lastPendingReward[token] > 0 &&
            curPendingReward[token] < lastPendingReward[token]
        ) {
            curPendingReward[token] = 0;
            lastPendingReward[token] = 0;
            accRewardPerShare[token] = 0;
            userRewardDebt[token][user] = 0;
            return;
        }

        uint256 totalSupply = IERC20Upgradeable(vault).totalSupply();

        if (totalSupply == 0) {
            accRewardPerShare[token] = 0;
            return;
        }

        uint256 addedReward = curPendingReward[token] -
            lastPendingReward[token];

        accRewardPerShare[token] =
            (accRewardPerShare[token] + addedReward * 1e36) /
            totalSupply;
    }

    /*
     *   Note that we currently do not have a mechanism here to include the
     *   amount of reward that is accrued.
     */
    function investedUnderlyingBalance() external view returns (uint256) {
        // Adding the amount locked in the reward pool and the amount that is somehow in this contract
        // both are in the units of "underlying"
        // The second part is needed because there is the emergency exit mechanism
        // which would break the assumption that all the funds are always inside of the reward pool
        return
            lpBalance() +
            IERC20Upgradeable(underlying).balanceOf(address(this));
    }

    function getPendingShare(
        address user,
        uint256 perShare,
        uint256 debt
    ) public view virtual returns (uint256) {
        uint256 current = (IERC20Upgradeable(vault).balanceOf(user) *
            perShare) / (1e36);

        if (current < debt) {
            return 0;
        }

        return current - debt;
    }

    function withdrawAllToVault() public onlyVault {
        exitFirstPool();

        uint256 bal = IERC20Upgradeable(underlying).balanceOf(address(this));

        if (bal != 0) {
            IERC20Upgradeable(underlying).safeTransfer(
                vault,
                IERC20Upgradeable(underlying).balanceOf(address(this))
            );
        }
    }

    /*
     *   Withdraws all the asset to the vault
     */
    function withdrawToVault(uint256 amount) public onlyVault {
        // Typically there wouldn"t be any amount here
        // however, it is possible because of the emergencyExit
        uint256 entireBalance = IERC20Upgradeable(underlying).balanceOf(
            address(this)
        );

        if (amount > entireBalance) {
            // While we have the check above, we still using SafeMath below
            // for the peace of mind (in case something gets changed in between)
            uint256 needToWithdraw = amount - entireBalance;
            uint256 toWithdraw = Math.min(lpBalance(), needToWithdraw);

            withdrawLpTokens(toWithdraw);
        }

        IERC20Upgradeable(underlying).safeTransfer(vault, amount);
    }

    function pendingTokenOfUser(
        address user,
        address token,
        uint256 pending
    ) internal view returns (uint256) {
        uint256 totalSupply = IERC20Upgradeable(vault).totalSupply();
        uint256 userBalance = IERC20Upgradeable(vault).balanceOf(user);
        if (totalSupply == 0) return 0;

        if (pending < lastPendingReward[token]) return 0; // < 8158866730045283

        uint256 addedReward = pending - lastPendingReward[token];

        uint256 newAccPerShare = (accRewardPerShare[token] +
            addedReward *
            1e36) / totalSupply;

        uint256 toWithdraw = (userBalance * newAccPerShare) / 1e36;

        if (toWithdraw <= userRewardDebt[token][user]) return 0;

        return toWithdraw - userRewardDebt[token][user];
    }

    function stakeFirstRewards() external virtual {
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

        IERC20Upgradeable(baseToken).safeApprove(xBaseToken, 0);
        IERC20Upgradeable(baseToken).safeApprove(xBaseToken, baseTokenBalance);

        uint256 balanceBefore = balanceXToken();

        enterBaseToken(baseTokenBalance);

        uint256 balanceAfter = balanceXToken();
        uint256 added = balanceAfter - balanceBefore;

        if (added > 0) {
            uint256 fee = (added * keepFee) / keepFeeMax;
            IERC20Upgradeable(xBaseToken).safeTransfer(treasury, fee);

            uint256 feeReward = (added * keepReward) / keepRewardMax;
            IERC20Upgradeable(xBaseToken).safeTransfer(
                rewardManager,
                feeReward
            );
        }
    }

    function xTokenStaked() internal view virtual returns (uint256 bal) {
        return 0;
    }

    function balanceXToken() public view virtual returns (uint256) {
        return IERC20Upgradeable(xBaseToken).balanceOf(address(this));
    }

    function prepareForWithdraw(uint256 available, uint256 pending)
        internal
        virtual
        returns (uint256)
    {
        uint256 result = available;

        if (available < pending) {
            uint256 stakedXToken = xTokenStaked();

            if (stakedXToken > 0) {
                uint256 needToWithdraw = pending > available
                    ? pending - available
                    : available;
                uint256 toWithdraw = Math.min(stakedXToken, needToWithdraw);

                if (toWithdraw > 0) {
                    withdrawXTokenStaked(toWithdraw);
                }

                result = balanceXToken();
            }
        }

        return Math.min(result, pending);
    }

    function withdrawXTokenReward(address user) internal virtual onlyVault {
        uint256 _pendingXBaseToken = getPendingShare(
            user,
            accRewardPerShare[xBaseToken],
            userRewardDebt[xBaseToken][user]
        );

        uint256 _xBaseTokenBalance = balanceXToken();

        _pendingXBaseToken = prepareForWithdraw(
            _xBaseTokenBalance,
            _pendingXBaseToken
        );

        if (
            _pendingXBaseToken > 0 &&
            curPendingReward[xBaseToken] > _pendingXBaseToken
        ) {
            IERC20Upgradeable(xBaseToken).safeTransfer(
                user,
                _pendingXBaseToken
            );

            lastPendingReward[xBaseToken] =
                curPendingReward[xBaseToken] -
                _pendingXBaseToken;
        }
    }

    function updateUserRewardDebtsFor(address token, address user)
        public
        virtual
        onlyVault
    {
        userRewardDebt[token][user] =
            (IERC20Upgradeable(vault).balanceOf(user) *
                accRewardPerShare[token]) /
            1e36;
    }

    /* VIRTUAL FUNCTIONS */
    function withdrawXTokenStaked(uint256 toWithdraw) internal virtual {}

    function stakeSecondRewards() external virtual {}

    function pendingReward(address _token)
        public
        view
        virtual
        returns (uint256);

    function updateAccPerShare(address user) public virtual;

    function updateUserRewardDebts(address user) public virtual;

    function withdrawReward(address user) public virtual;

    function withdrawLpTokens(uint256 amount) internal virtual;

    function lpBalance() public view virtual returns (uint256 bal);

    function stakeLpTokens() external virtual;

    function exitFirstPool() internal virtual returns (uint256);

    function claimFirstPool() public virtual;

    function enterBaseToken(uint256 baseTokenBalance) internal virtual;

    function pendingXToken() public view virtual returns (uint256);
}
