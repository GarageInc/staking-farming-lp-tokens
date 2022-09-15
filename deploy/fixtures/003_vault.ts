import { DeployFunction } from 'hardhat-deploy/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

const func: DeployFunction = async (
  hre: HardhatRuntimeEnvironment,
): Promise<void> => {
  const { deployments, getNamedAccounts } = hre;

  const { deployer } = await getNamedAccounts();

  await deployments.deploy('VaultMock', {
    from: deployer,
    args: [],
    log: true,
  });
};

func.tags = ['VaultMock'];
func.skip = (env) => Promise.resolve(env.network.name === 'mainnet');

export default func;
