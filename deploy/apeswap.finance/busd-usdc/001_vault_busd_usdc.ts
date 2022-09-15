import { DeployFunction } from 'hardhat-deploy/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { ethers, upgrades } from 'hardhat';

const UNDERLYING = '0xC087C78AbaC4A0E900a327444193dBF9BA69058E';

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

func.tags = ['ApeswapVault_BUSD_USDC'];

export default func;
