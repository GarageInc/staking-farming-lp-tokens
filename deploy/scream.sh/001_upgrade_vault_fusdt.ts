import { DeployFunction } from 'hardhat-deploy/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { ethers, upgrades } from 'hardhat';

const func: DeployFunction = async (
  hre: HardhatRuntimeEnvironment,
): Promise<void> => {
  const locker = await ethers.getContractFactory('BaseSinglePoolVault');
  const proxy = await upgrades.upgradeProxy(
    '0xb56689F8F22ab1948b395fF701A2aBB05d4d9987',
    locker,
    {
      kind: 'transparent',
    },
  );

  await proxy.deployed();

  console.log('Vault upgraded to:', proxy.address);
};

func.tags = ['ScreamVaultUpgradeFUSDT'];

export default func;
