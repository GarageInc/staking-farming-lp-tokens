import { deployments as dep } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address';
import {
  OnxLocker,
  TAlphaToken,
  UniswapV2PairMock,
  VaultMock,
} from '../typechain-types';

export const setupTestEnvironment = dep.createFixture(
  async ({ deployments, ethers }) => {
    await deployments.fixture();

    const [deployer, firstTestWallet, secondTestWallet, thirdTestWallet] =
      await ethers.getSigners();

    const locker: OnxLocker = await ethers.getContract('OnxLocker');
    const onxToken: TAlphaToken = await ethers.getContract('TAlphaToken');
    const uniV2: UniswapV2PairMock = await ethers.getContract(
      'UniswapV2PairMock',
    );
    const vault: VaultMock = await ethers.getContract('VaultMock');

    const setUpWallet = async (wallet: SignerWithAddress) => {
      const tx = await onxToken
        .connect(wallet)
        .approve(locker.address, ethers.utils.parseEther('1000'));

      await tx.wait();

      const tx2 = await uniV2
        .connect(wallet)
        .approve(locker.address, ethers.utils.parseEther('1000'));

      await tx2.wait();

      const tx3 = await vault
        .connect(wallet)
        .approve(locker.address, ethers.utils.parseEther('1000'));

      await tx3.wait();
    };

    await setUpWallet(deployer);
    await setUpWallet(firstTestWallet);
    await setUpWallet(secondTestWallet);
    await setUpWallet(thirdTestWallet);
  },
);

export default {};
