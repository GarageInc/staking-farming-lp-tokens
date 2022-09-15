import { DeployFunction } from 'hardhat-deploy/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { ethers, upgrades } from 'hardhat';

const func: DeployFunction = async (
  hre: HardhatRuntimeEnvironment,
): Promise<void> => {
  const c = await ethers.getContractFactory('StrategyAdapterApeswapBanana');
  const proxy = await upgrades.upgradeProxy(
    '0x852bB92461df9595404E2B7A60bA7e7477a5527e',
    c,
    {
      kind: 'transparent',
    },
  );

  await proxy.deployed();

  console.log('Strategy upgraded to:', proxy.address);
};

func.tags = ['ApeswapStrategyUpgrade'];

export default func;
