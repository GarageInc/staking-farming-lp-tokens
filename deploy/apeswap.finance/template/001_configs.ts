import { DeployFunction } from 'hardhat-deploy/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { ethers, upgrades } from 'hardhat';
import { BaseSinglePoolVault } from '../../../typechain-types';

const UNDERLYING = '0x60593Abea55e9Ea9d31c1b6473191cD2475a720D';
const POOL_ID = 25;

const func: DeployFunction = async (
  hre: HardhatRuntimeEnvironment,
): Promise<void> => {
  const vault = await ethers.getContractFactory('BaseSinglePoolVault');
  const proxyVault = await upgrades.deployProxy(vault, [UNDERLYING], {
    kind: 'transparent',
  });

  await proxyVault.deployed();

  console.log('Vault deployed to:', proxyVault.address);

  const strategy = await ethers.getContractFactory(
    'StrategyAdapterApeswapBanana',
  );
  const proxyStrategy = await upgrades.deployProxy(
    strategy,
    [UNDERLYING, proxyVault.address, POOL_ID],
    {
      kind: 'transparent',
    },
  );

  await proxyStrategy.deployed();

  console.log('Strategy deployed to:', proxyStrategy.address);

  const vaultContract = await ethers.getContractAt<BaseSinglePoolVault>(
    'BaseSinglePoolVault',
    proxyVault.address,
  );

  await vaultContract.setStrategy(proxyStrategy.address);

  console.log('Set address');
};

func.tags = ['ApeswapDeployAndConfigure'];

export default func;
