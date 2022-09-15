import { DeployFunction } from 'hardhat-deploy/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { ethers } from 'hardhat';
import { BaseSinglePoolVault } from '../..';

const _vault = '0xc737C1b79fd5d3Cd1830AcbD70d5bDC55FAf54fF';
const _strategy = '0x5823feaFee71686bEDC6a84CE022259664b6e56B';

const func: DeployFunction = async (
  hre: HardhatRuntimeEnvironment,
): Promise<void> => {
  const c = await ethers.getContractAt<BaseSinglePoolVault>(
    'BaseSinglePoolVault',
    _vault,
  );

  await c.setStrategy(_strategy);
};

func.tags = ['ScreamConfigsFUSDT'];

export default func;
