import { DeployFunction } from 'hardhat-deploy/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { ethers, upgrades } from 'hardhat';

const func: DeployFunction = async (
  hre: HardhatRuntimeEnvironment,
): Promise<void> => {
  const c = await ethers.getContractFactory('StrategyAdapterPancakeswapCake');
  const proxy = await upgrades.upgradeProxy(
    '0x41032EAB8B6927d3CB533cB9078F769eB6423c26',
    c,
    {
      kind: 'transparent',
    },
  );

  await proxy.deployed();

  console.log('Strategy upgraded to:', proxy.address);
};

func.tags = ['PancakeswapStrategyUpgrade'];

export default func;
