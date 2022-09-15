import { DeployFunction } from 'hardhat-deploy/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { ethers } from 'hardhat';
import { BaseSinglePoolVault } from '../../..';

const _vault = '0xE7d244b3264a1453AA60D9E42c461102D05eCa37';
const _strategy = '0x852bB92461df9595404E2B7A60bA7e7477a5527e';

const func: DeployFunction = async (
  hre: HardhatRuntimeEnvironment,
): Promise<void> => {
  const c = await ethers.getContractAt<BaseSinglePoolVault>(
    'BaseSinglePoolVault',
    _vault,
  );

  await c.setStrategy(_strategy);
};

func.tags = ['ApeswapConfigs_BUSD_USDC'];

export default func;
