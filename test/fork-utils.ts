import { network } from 'hardhat';

export async function impersonates(targetAccounts: string[]): Promise<void> {
  console.log('Impersonating...');
  for (let i = 0; i < targetAccounts.length; i++) {
    await network.provider.request({
      method: 'hardhat_impersonateAccount',
      params: [targetAccounts[i]],
    });
  }
}
