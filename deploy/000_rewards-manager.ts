import { DeployFunction } from 'hardhat-deploy/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

const BSC_MULTISIG_WALLET = '0x3EDde7123c29Bd05273F743083782DE3C818bF36';

// BSC Reward manager: 0x7F1c2432Dc4e83b49fA0Ec85ae45470D6B17b67F
const func: DeployFunction = async (
  hre: HardhatRuntimeEnvironment,
): Promise<void> => {
  const { deployments, getNamedAccounts } = hre;

  const { deployer } = await getNamedAccounts();

  const result = await deployments.deploy('RewardManager', {
    from: deployer,
    args: [BSC_MULTISIG_WALLET],
    log: true,
  });

  console.log(result);
};

func.tags = ['RewardManager'];

export default func;
