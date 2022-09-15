import { DeployFunction } from 'hardhat-deploy/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { ethers, upgrades } from 'hardhat';

const func: DeployFunction = async (
  hre: HardhatRuntimeEnvironment,
): Promise<void> => {
  const locker = await ethers.getContractFactory('StrategyAdapterScream');
  const proxy = await upgrades.upgradeProxy(
    '0x5823feaFee71686bEDC6a84CE022259664b6e56B',
    locker,
    {
      kind: 'transparent',
    },
  );

  await proxy.deployed();

  console.log('Strategy upgraded to:', proxy.address);
};

func.tags = ['ScreamStrategyUpgradeFUSDT'];

export default func;
