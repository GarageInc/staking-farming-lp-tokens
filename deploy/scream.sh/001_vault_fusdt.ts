import { DeployFunction } from 'hardhat-deploy/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { ethers, upgrades } from 'hardhat';

const UNDERLYING = '0x049d68029688eabf473097a2fc38ef61633a3c7a';

const func: DeployFunction = async (
  hre: HardhatRuntimeEnvironment,
): Promise<void> => {
  const c = await ethers.getContractFactory('BaseSinglePoolVault');
  const proxy = await upgrades.deployProxy(c, [UNDERLYING], {
    kind: 'transparent',
  });

  await proxy.deployed();

  console.log('Vault deployed to:', proxy.address);
};

func.tags = ['ScreamVaultFUSDT'];

export default func;
