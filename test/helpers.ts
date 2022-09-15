import { BigNumberish, BigNumber } from 'ethers';
import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address';
import { ZERO_ADDRESS } from './constants';

export const convertBigNumber = (
  bnAmount: BigNumberish,
  divider: BigNumberish,
): string => BigNumber.from(bnAmount.toString()).div(divider).toString();

export const mintBlocks = async (
  blocksNumber: number,
  wallet: SignerWithAddress,
): Promise<void> => {
  const startBlockNumber = await ethers.provider.getBlockNumber();
  let currentBlockNumber = startBlockNumber;

  // TODO: refactoring to evm_mine
  while (startBlockNumber + blocksNumber > currentBlockNumber) {
    await wallet.sendTransaction({
      to: ZERO_ADDRESS,
      value: ethers.utils.parseUnits('1', '0'),
    });

    currentBlockNumber = await ethers.provider.getBlockNumber();
  }
};
