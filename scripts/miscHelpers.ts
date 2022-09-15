import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { ContractTransaction } from 'ethers';
import { ethers, network } from 'hardhat';
import { expect } from 'chai';

let HRE: HardhatRuntimeEnvironment = {} as HardhatRuntimeEnvironment;

export const setHRE = (_HRE: HardhatRuntimeEnvironment): void => {
  HRE = _HRE;
};

export async function delay(ms: number): Promise<number> {
  // eslint-disable-next-line no-promise-executor-return
  return new Promise((resolve) => setTimeout(resolve, ms));
}

const CONFIRMATIONS = 1;

export async function waitForTx(
  promise: Promise<ContractTransaction>,
): Promise<ContractTransaction> {
  return promise.then((tx) => {
    tx.wait(CONFIRMATIONS);
    return tx;
  });
}

export async function waitForAllTxs(
  ...rest: Promise<ContractTransaction>[]
): Promise<void> {
  await Promise.all(rest.map(waitForTx));
}

export async function verifyContract(
  _address: string,
  contractPath: string,
  args: unknown,
): Promise<void> {
  let count = 0;
  const maxTries = 5;

  while (count < maxTries) {
    try {
      console.log('Verifying contract at', _address);

      await HRE.run('verify:verify', {
        address: _address,
        constructorArguments: args,
        contract: contractPath, // "contracts/lp-oracle-contracts/mock/Token.sol:Token",
      });
      return;
    } catch (error) {
      count += 1;

      await delay(5000);
    }
  }

  if (count === maxTries) {
    console.log('Failed to verify contract at path %s at address %s', _address);
    throw new Error('Verification failed');
  }
}
export const increaseTime = async (days: number): Promise<void> => {
  console.log('Increased for days: ', days);
  await ethers.provider.send('evm_increaseTime', [days * 24 * 60 * 60]);
  await network.provider.send('evm_mine');
  await network.provider.send('evm_mine');
};

export async function assertErrorMessage(
  p: Promise<ContractTransaction>,
  message: string,
): Promise<void> {
  return p.then(
    (value) => {
      /* eslint-disable */
      expect.fail(`Found value instead of error: ${value}`);
    },
    /* eslint-disable */
    (reason) => {
      expect(reason.message, 'Some internal msg').to.contain(message);
    },
  );
}
