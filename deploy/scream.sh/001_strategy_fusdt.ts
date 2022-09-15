import { DeployFunction } from 'hardhat-deploy/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { ethers, upgrades } from 'hardhat';
import {
  FANTOM_multisigWallet,
  FANTOM_rewardManager,
  FANTOM_treasury,
} from '../chain_configs';

const _underlying = '0x049d68029688eabf473097a2fc38ef61633a3c7a';
const _vault = '0xc737C1b79fd5d3Cd1830AcbD70d5bDC55FAf54fF';
const _masterChef = '0x02224765bc8d54c21bb51b0951c80315e1c263f9';
const _controller = '0x260e596dabe3afc463e75b6cc05d8c46acacfb09';

const func: DeployFunction = async (
  hre: HardhatRuntimeEnvironment,
): Promise<void> => {
  const c = await ethers.getContractFactory('StrategyAdapterScream');
  const proxy = await upgrades.deployProxy(
    c,
    [
      FANTOM_multisigWallet,
      FANTOM_rewardManager,
      FANTOM_treasury,
      _underlying,
      _vault,
      _masterChef,
      _controller,
    ],
    {
      kind: 'transparent',
    },
  );

  await proxy.deployed();

  console.log('Strategy deployed to:', proxy.address);
};

func.tags = ['ScreamStrategyFUSDT'];

export default func;
