import { DeployFunction } from 'hardhat-deploy/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { ethers, upgrades } from 'hardhat';

const _underlying = '0xc087c78abac4a0e900a327444193dbf9ba69058e';
const _vault = '0xE7d244b3264a1453AA60D9E42c461102D05eCa37';
const pid = 8;

const func: DeployFunction = async (
  hre: HardhatRuntimeEnvironment,
): Promise<void> => {
  const c = await ethers.getContractFactory('StrategyAdapterApeswapBanana');
  const proxy = await upgrades.deployProxy(c, [_underlying, _vault, pid], {
    kind: 'transparent',
  });

  await proxy.deployed();

  console.log('Strategy deployed to:', proxy.address);
};

func.tags = ['ApeswapStrategy_BUSD_USDC'];

export default func;

// impl 0xb137afa138e9aa3842cb7cd0ff1a97b5f056b437
