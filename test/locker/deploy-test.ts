import { expect } from 'chai';
import { BigNumber, Contract } from 'ethers';
import { ethers, getNamedAccounts } from 'hardhat';
import { impersonates } from '../fork-utils';
import {
  OnxLocker,
  TAlphaToken,
  UniswapV2PairMock,
  VaultMock,
} from '../../typechain-types';
import { setupTestEnvironment } from '../createFixture';
import { increaseTime } from '../../scripts/miscHelpers';

const RANDOM_ADDRESS = '0x0000000000000000000000000000000000001234';

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

const AMOUNT: BigNumber = BigNumber.from((2e18).toString());
const ON_ONX_TO_LP_AMOUNT: BigNumber = BigNumber.from((75e18).toString());

const ONX_BALANCE = AMOUNT.mul(1000);

describe('Locker', () => {
  let locker: OnxLocker;
  let onxToken: TAlphaToken;
  let owner: string;
  let uniV2: UniswapV2PairMock;
  let vaultMock: VaultMock;

  async function setupExternalContracts() {
    locker = await ethers.getContract('OnxLocker');
    onxToken = await ethers.getContract('TAlphaToken');
    uniV2 = await ethers.getContract('UniswapV2PairMock');
    vaultMock = await ethers.getContract('VaultMock');

    await locker.deployed();
    await onxToken.deployed();
    await uniV2.deployed();
    await vaultMock.deployed();
  }

  async function setupBalances() {
    const [firstTestWallet, secondTestWallet, thirdTestWallet] =
      await ethers.getSigners();

    const mint = async (token: Contract): Promise<void> => {
      // eslint-disable-next-line
      await token.mint(owner, ONX_BALANCE);
      // eslint-disable-next-line
      await token.mint(firstTestWallet.address, ONX_BALANCE);
      // eslint-disable-next-line
      await token.mint(secondTestWallet.address, ONX_BALANCE);
      // eslint-disable-next-line
      await token.mint(thirdTestWallet.address, ONX_BALANCE);
    };

    await mint(onxToken);
    await mint(uniV2);
    await mint(vaultMock);
  }

  before(async () => {
    await setupTestEnvironment();

    const { deployer, ...rest } = await getNamedAccounts();

    console.log({ deployer, ...rest });
    owner = deployer;

    await setupExternalContracts();
    await impersonates([deployer]);
    await setupBalances();
  });

  it('should set/change right operator', async () => {
    expect(await locker.governor(), 'Not right governor').to.be.eq(owner);

    // const { firstTestWallet } = await ethers.getNamedSigners();

    /* await assertErrorMessage(
      bond.setOperator(lockerDeployed.address),
      "VM Exception while processing transaction: reverted with custom error 'Unauthorized()'",
    ); */
  });

  it('right name', async () => {
    expect(await locker.symbol()).to.be.eq('onONX');
    expect(await locker.name()).to.be.eq('Onx.Finance Governance');
    expect(await locker.decimals()).to.be.eq(18);
  });

  it('correct balance set', async () => {
    expect(await onxToken.balanceOf(owner)).to.be.eq(ONX_BALANCE);
    expect(await onxToken.balanceOf(owner)).to.be.eq(
      (await onxToken.totalSupply()).div(4),
    );

    expect(await uniV2.balanceOf(owner)).to.be.eq(ONX_BALANCE);
    expect(await uniV2.balanceOf(owner)).to.be.eq(
      (await uniV2.totalSupply()).div(4),
    );
  });

  it('should add ONX token', async () => {
    await locker.setStakingToken(onxToken.address, ZERO_ADDRESS);

    expect((await locker.stakingTokens(onxToken.address)).token).to.be.eq(
      onxToken.address,
    );

    expect((await locker.stakingTokens(RANDOM_ADDRESS)).token).to.be.not.eq(
      onxToken.address,
    );

    expect((await locker.stakingTokens(RANDOM_ADDRESS)).token).to.be.eq(
      ZERO_ADDRESS,
    );
  });

  it('should add UNI-V2 token', async () => {
    await locker.setStakingToken(vaultMock.address, uniV2.address);

    expect(
      (await locker.stakingTokens(vaultMock.address)).token,
      'Staking token is vault',
    ).to.be.eq(vaultMock.address);

    expect(
      (await locker.stakingTokens(RANDOM_ADDRESS)).token,
      'Random address is not zero address',
    ).to.be.not.eq(vaultMock.address);

    expect(
      (await locker.stakingTokens(RANDOM_ADDRESS)).token,
      'Random address is random',
    ).to.be.eq(ZERO_ADDRESS);
  });

  it('should lock ONX token', async () => {
    await locker.setStakingToken(onxToken.address, ZERO_ADDRESS);

    const [, firstTestWallet, secondTestWallet] = await ethers.getSigners();

    expect(await locker.getBoostedAmount(onxToken.address, AMOUNT)).to.be.eq(
      AMOUNT,
    );

    await locker.connect(firstTestWallet).lock(onxToken.address, AMOUNT);
    await locker.connect(secondTestWallet).lock(onxToken.address, AMOUNT);

    const [totalFirst, unlockable, locked] = await locker.lockedBalances(
      firstTestWallet.address,
      onxToken.address,
    );

    expect(totalFirst).to.be.eq(AMOUNT);
    expect(unlockable).to.be.eq(0);
    expect(locked).to.be.eq(AMOUNT);

    const [totalSecond] = await locker.lockedBalances(
      secondTestWallet.address,
      onxToken.address,
    );

    expect(
      await locker.balanceOf(firstTestWallet.address),
      'Locked balance first user in 1 epoch',
    ).to.be.eq(0);
    expect(
      await locker.balanceOf(secondTestWallet.address),
      'Locked balance second user in 1 epoch',
    ).to.be.eq(0);

    expect(totalSecond).to.be.eq(AMOUNT);

    expect(await locker.totalSupply()).to.be.eq(AMOUNT.mul(2));
    expect(await locker.lockedSupply(onxToken.address)).to.be.eq(AMOUNT.mul(2));

    const epoch1 = await locker.getCurrentEpoch();

    await increaseTime(29);
    await locker.connect(firstTestWallet).lock(onxToken.address, AMOUNT);

    const [totalAfter28Days, unlockableAfter28Days, lockedAfter28Days] =
      await locker.lockedBalances(firstTestWallet.address, onxToken.address);

    expect(totalAfter28Days).to.be.eq(AMOUNT.mul(2));
    expect(unlockableAfter28Days).to.be.eq(AMOUNT);
    expect(lockedAfter28Days).to.be.eq(AMOUNT);

    const epoch2 = await locker.getCurrentEpoch();

    printDiffEpochs(epoch2, epoch1);

    await increaseTime(28);
    await increaseTime(28);

    await locker.connect(firstTestWallet).lock(onxToken.address, AMOUNT);

    const [totalAfter3Locks, unlockableAfter3Locks, lockedAfter3Locks] =
      await locker.lockedBalances(firstTestWallet.address, onxToken.address);

    const epoch3 = await locker.getCurrentEpoch();

    printDiffEpochs(epoch3, epoch2);

    expect(totalAfter3Locks, 'Total locked in 3 epoch').to.be.eq(AMOUNT.mul(3));
    expect(lockedAfter3Locks, 'Total locked in 3 epoch').to.be.eq(AMOUNT);
    expect(
      unlockableAfter3Locks,
      'Total unlocked in 3 epoch  (can withdraw)',
    ).to.be.eq(AMOUNT.mul(2));

    expect(
      await locker.balanceOf(firstTestWallet.address),
      'Locked balance in 3 epoch',
    ).to.be.eq(0);

    expect(await locker.totalSupply()).to.be.eq(0);

    await increaseTime(28);
    await increaseTime(28);

    const [totalAfterAfterAll, unlockableAfterAfterAll, lockedAfterAfterAll] =
      await locker.lockedBalances(firstTestWallet.address, onxToken.address);

    console.log(
      totalAfterAfterAll.toString(),
      unlockableAfterAfterAll.toString(),
      lockedAfterAfterAll.toString(),
    );
    expect(totalAfterAfterAll).to.be.eq(AMOUNT.mul(3));
    expect(unlockableAfterAfterAll).to.be.eq(AMOUNT.mul(3));
    expect(lockedAfterAfterAll).to.be.eq(0);
  });

  it('should lock UNI-v2 token', async () => {
    await locker.setStakingToken(vaultMock.address, uniV2.address);
    console.log(await locker.stakingTokens(vaultMock.address));

    const [, firstTestWallet, secondTestWallet] = await ethers.getSigners();

    expect(await locker.getBoostedAmount(vaultMock.address, AMOUNT)).to.be.eq(
      ON_ONX_TO_LP_AMOUNT,
    );

    await locker.connect(firstTestWallet).lock(vaultMock.address, AMOUNT);
    await locker.connect(secondTestWallet).lock(vaultMock.address, AMOUNT);

    const [totalFirst, unlockable, locked] = await locker.lockedBalances(
      firstTestWallet.address,
      vaultMock.address,
    );

    expect(totalFirst).to.be.eq(AMOUNT);
    expect(unlockable).to.be.eq(0);
    expect(locked).to.be.eq(AMOUNT);

    expect(
      await locker.balanceOf(firstTestWallet.address),
      'Locked balance in 1 epoch',
    ).to.be.eq(0);
  });
});

function printDiffEpochs(epoch2: BigNumber, epoch1: BigNumber) {
  console.log('Diff: ', (epoch2.toNumber() - epoch1.toNumber()) / 24 / 60 / 60);
}
